class Admin::UsersController < ApplicationController

  protect_from_forgery
  before_action :authenticate_user!
  before_action :require_admin!

  respond_to :json

  def index
    # Getting the count for user measures and patients via the DB is a 1+n problem, and a bit slow, so we grab
    # the counts separately via map reduce and plug them in
    users = User.asc(:email).all.to_a # Need to convert to array so counts stick
    map = "function() { emit(this.user_id, 1); }"
    reduce = "function(user_id, counts) { return Array.sum(counts); }"
    measure_counts = CQM::Measure.map_reduce(map, reduce).out(inline: 1).each_with_object({}) { |r, h| h[r[:_id]] = r[:value].to_i }
    patient_counts = CQM::Patient.map_reduce(map, reduce).out(inline: 1).each_with_object({}) { |r, h| h[r[:_id]] = r[:value].to_i }
    users.each do |u|
      u.measure_count = measure_counts[u.id] || 0
      u.patient_count = patient_counts[u.id] || 0
    end
    users_json = MultiJson.encode(users.as_json(methods: [:measure_count, :patient_count, :last_sign_in_at]))
    respond_with users do |format|
      format.json { render json: users_json }
    end
  end

  def email_all
    User.asc(:email).each do |user|
      email = Admin::UsersMailer.users_email(user, user_email_params[:subject], user_email_params[:body])
      email.deliver_now
      sleep 2 # address issues with mail throttling
    end
    render json: {}
  end

  def email_active
    # only send email to users who have logged in sometime in the last 6 months
    # and have at least one measure loaded
    User.asc(:email).where(:last_sign_in_at.gt => Date.today - 6.months).each do |user|
      if user.measure_count > 0
        email = Admin::UsersMailer.users_email(user, user_email_params[:subject], user_email_params[:body])
        email.deliver_now
        sleep 2 # address issues with mail throttling
      end
    end
    render json: {}
  end

  def email_single
    user = User.where(email: user_email_params[:target_email]).first
    email = Admin::UsersMailer.users_email(user, user_email_params[:subject], user_email_params[:body])
    email.deliver_now
    render json: {}
  end

  def update
    user = User.find(params[:id])
    user.update(user_params)
    respond_with user
  end

  def approve
    user = User.find(params[:id])
    user.approved = true
    user.save
    UserMailer.account_activation_email(user).deliver_now
    render json: user
  end

  def disable
    user = User.find(params[:id])
    user.approved = false
    user.save
    render json: user
  end

  def destroy
    user = User.find(params[:id])
    user.destroy
    render json: {}
  end

  def patients
    user = User.find(params[:id])
    send_data JSON.pretty_generate(user.patients.map(&:as_document)), :type => 'application/json', :disposition => 'attachment', :filename => "patients_#{user.email}.json"
  end

  def measures
    user = User.find(params[:id])
    send_data JSON.pretty_generate(JSON.parse(user.cqm_measures.to_json)), :type => 'application/json', :disposition => 'attachment', :filename => "measures_#{user.email}.json"
  end

  def log_in_as
    user = User.find(params[:id])
    sign_in user
    redirect_to root_path
  end

  private

  def user_params
    params.permit(:email, :admin, :portfolio, :dashboard)
  end

  def user_email_params
    params.permit(:target_email, :subject, :body)
  end

  def require_admin!
    raise "User #{current_user.email} requesting resource requiring admin access" unless current_user.admin?
  end

end
