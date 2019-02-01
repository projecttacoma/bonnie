class MeasuresController < ApplicationController
  include MeasureHelper

  skip_before_action :verify_authenticity_token, only: [:show, :value_sets]

  respond_to :json, :js, :html

  def show
    skippable_fields = [:map_fns, :record_ids, :measure_attributes]
    @measure = CQM::Measure.by_user(current_user).without(*skippable_fields).where(id: params[:id]).first
    raise Mongoid::Errors::DocumentNotFound unless @measure
    if stale? last_modified: @measure.updated_at.try(:utc), etag: @measure.cache_key
      raw_json = @measure.as_json(except: skippable_fields)
      @measure_json = MultiJson.encode(raw_json)
      respond_with @measure do |format|
        format.json { render json: @measure_json }
      end
    end
  end

  def value_sets
    # Caching of value sets is (temporarily?) disabled to correctly handle cases where users use multiple accounts
    # if stale? last_modified: Measure.by_user(current_user).max(:updated_at).try(:utc)
    if true
      ### FOR CQM Measures ###

      cqm_measures = CQM::Measure.where(user_id: current_user.id)
      # Measure {measure_id: [value_sets]}
      @value_sets_by_measure_id_json = {}
      cqm_measures.each do |cqm_measure|
        @value_sets_by_measure_id_json[cqm_measure.hqmf_set_id] = cqm_measure.value_sets.as_json(:except => :_id)
      end

      @value_sets_final = MultiJson.encode @value_sets_by_measure_id_json
      respond_with @value_sets_final do |format|
        format.json { render json: @value_sets_final }
      end
    end
  end

  def create
    if !params[:measure_file]
      flash[:error] = {title: "Error Loading Measure", body: "You must specify a Measure Authoring tool measure export to use."}
      redirect_to "#{root_path}##{params[:redirect_route]}"
      return
    end

    measure_details = {
      'type'=>params[:measure_type],
      'episode_of_care'=>params[:calculation_type] == 'episode',
      'calculate_sdes'=>params[:calc_sde]
    }

    extension = File.extname(params[:measure_file].original_filename).downcase if params[:measure_file]
    if !extension || extension != '.zip'
      flash[:error] = {title: "Error Loading Measure",
        summary: "Incorrect Upload Format.",
        body: 'The file you have uploaded does not appear to be a Measure Authoring Tool (MAT) zip export of a measure. Please re-package and re-export your measure from the MAT.<br/>If this is a QDM-Logic Based measure, please use <a href="https://bonnie-qdm.healthit.gov">Bonnie-QDM</a>.'.html_safe}
      redirect_to "#{root_path}##{params[:redirect_route]}"
      return
    elsif !Measures::CqlLoader.mat_cql_export?(params[:measure_file])
      flash[:error] = {title: "Error Uploading Measure",
        summary: "The uploaded zip file is not a valid Measure Authoring Tool (MAT) export of a CQL Based Measure.",
        body: 'Please re-package and re-export your measure from the MAT.<br/>If this is a QDM-Logic Based measure, please use <a href="https://bonnie-qdm.healthit.gov">Bonnie-QDM</a>.'.html_safe}
      redirect_to "#{root_path}##{params[:redirect_route]}"
      return
    end
    #If we get to this point, then the measure that is being uploaded is a MAT export of CQL
    begin
      # parse VSAC options using helper and get ticket_granting_ticket which is always needed
      vsac_options = MeasureHelper.parse_vsac_parameters(params)
      vsac_ticket_granting_ticket = get_ticket_granting_ticket

      is_update = false
      if (params[:hqmf_set_id] && !params[:hqmf_set_id].empty?)
        existing = CqlMeasure.by_user(current_user).where(hqmf_set_id: params[:hqmf_set_id]).first
        if !existing.nil?
          is_update = true
          measure_details['type'] = existing.type
          measure_details['episode_of_care'] = existing.episode_of_care
          if measure_details['episode_of_care']
            episodes = params["eoc_#{existing.hqmf_set_id}"]
          end
          measure_details['calculate_sdes'] = existing.calculate_sdes
          measure_details['population_titles'] = existing.populations.map {|p| p['title']} if existing.populations.length > 1
        else
          raise Exception.new('Update requested, but measure does not exist.')
        end
      end
      # Extract measure(s) from zipfile
      measures = Measures::CqlLoader.extract_measures(params[:measure_file], current_user, measure_details, vsac_options, vsac_ticket_granting_ticket)
      update_error_message = MeasureHelper.update_measures(measures, current_user, is_update, existing)
      if (!update_error_message.nil?)
        flash[:error] = update_error_message
        redirect_to "#{root_path}##{params[:redirect_route]}"
        return
      end
    rescue Exception => e
      measures.each(&:delete) if measures
      errors_dir = Rails.root.join('log', 'load_errors')
      FileUtils.mkdir_p(errors_dir)
      clean_email = File.basename(current_user.email) # Prevent path traversal

      # Create the filename for the copied measure upload. We do not use the original extension to avoid malicious user
      # input being used in file system operations.
      filename = "#{clean_email}_#{Time.now.strftime('%Y-%m-%dT%H%M%S')}.xmlorzip"

      operator_error = false # certain types of errors are operator errors and do not need to be emailed out.
      File.open(File.join(errors_dir, filename), 'w') do |errored_measure_file|
        uploaded_file = params[:measure_file].tempfile.open()
        errored_measure_file.write(uploaded_file.read());
        uploaded_file.close()
      end

      File.chmod(0644, File.join(errors_dir, filename))
      File.open(File.join(errors_dir, "#{clean_email}_#{Time.now.strftime('%Y-%m-%dT%H%M%S')}.error"), 'w') do |f|
        f.write("Original Filename was #{params[:measure_file].original_filename}\n")
        f.write(e.to_s + "\n" + e.backtrace.join("\n"))
      end
      if e.is_a?(Util::VSAC::VSACError)
        operator_error = true
        flash[:error] = MeasureHelper.build_vsac_error_message(e)

        # also clear the ticket granting ticket in the session if it was a VSACTicketExpiredError
        session[:vsac_tgt] = nil if e.is_a?(Util::VSAC::VSACTicketExpiredError)
      elsif e.is_a? Measures::MeasureLoadingException
        operator_error = true
        flash[:error] = {title: "Error Loading Measure", summary: "The measure could not be loaded", body:"There may be an error in the CQL logic."}
      else
        flash[:error] = {title: "Error Loading Measure", summary: "The measure could not be loaded.", body: "Bonnie has encountered an error while trying to load the measure."}
      end

      # email the error
      if !operator_error && defined? ExceptionNotifier::Notifier
        params[:error_file] = filename
        ExceptionNotifier::Notifier.exception_notification(env, e).deliver_now
      end

      redirect_to "#{root_path}##{params[:redirect_route]}"
      return
    end

    MeasureHelper.measures_population_update(measures, is_update, current_user, measure_details)

    redirect_to "#{root_path}##{params[:redirect_route]}"
  end

  def destroy
    measure = CQM::Measure.by_user(current_user).where(id: params[:id]).first

    if measure.component
      render status: :bad_request, json: {error: "Component measures can't be deleted individually."}
      return
    elsif measure.composite
      # If the measure if a composite, delete all the associated components
      measure.component_hqmf_set_ids.each do |component_hqmf_set_id|
        CQM::Measure.by_user(current_user).where(hqmf_set_id: component_hqmf_set_id).first.destroy_self_and_child_docs
      end
    end
    measure.destroy_self_and_child_docs

    render :json => measure
  end

  def finalize
    measure_finalize_data = params.values.select {|p| p['hqmf_id']}.uniq
    measure_finalize_data.each do |data|
      measure = CQM::Measure.by_user(current_user).where(hqmf_id: data['hqmf_id']).first
      begin
        # TODO: should this do the same for component measures?
        Measures::CqlLoader.update_population_set_and_strat_titles(measure, data['titles'])
        measure.save!
      rescue Exception => e
        operator_error = true
        flash[:error] = {title: "Error Loading Measure", summary: "Error Finalizing Measure", body: "An unexpected error occurred while finalizing this measure.  Please delete the measure, re-package and re-export the measure from the MAT, and re-upload the measure."}
      ensure
        # These 2 steps need to be run even if there was an error, otherwise there will be an infinite loop with the finalize dialog
        measure['needs_finalize'] = false
        measure.save!
      end
    end
    redirect_to root_path
  end

  private

  def persist_measure(uploaded_file, params, user)
    measures, main_hqmf_set_id =
      if params[:hqmf_set_id].present?
        update_measure(uploaded_file: uploaded_file,
                      target_id: params[:hqmf_set_id],
                      value_set_loader: build_vs_loader(params, false),
                      user: user)
      else
        create_measure(uploaded_file: uploaded_file,
                      measure_details: retrieve_measure_details(params),
                      value_set_loader: build_vs_loader(params, false),
                      user: user)
      end
    return measures, main_hqmf_set_id
  end

  def retrieve_measure_details(params)
    return {
      'episode_of_care'=>params[:calculation_type] == 'episode',
      'calculate_sdes'=>params[:calc_sde]
    }
  end
end
