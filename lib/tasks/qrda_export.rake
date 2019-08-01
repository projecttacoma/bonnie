namespace :bonnie do
  namespace :qrda do

    desc %{Export patient records as QRDA.

    You must identify the user by EMAIL:

    $ rake bonnie:qrda:export_for_user EMAIL=xxx}
    task :export_for_user => :environment do
      user = User.find_by email: ENV['EMAIL']

      @measures = CQM::Measure.by_user(user)

      @measures.each do |measure|
        cqm_patients = CQM::Patient.by_user_and_hqmf_set_id(user, measure.hqmf_set_id).all
        Zip::ZipOutputStream.open("tmp/#{measure.cms_id}_#{user.first_name}_#{user.last_name}.zip") do |z|
          options = { start_time: DateTime.parse(measure.measure_period['low']['value']),
                      end_time: DateTime.parse(measure.measure_period['high']['value']) }
          cqm_patients.each_with_index do |cqm_patient, i|
            if cqm_patient.qdmPatient.get_data_elements('patient_characteristic', 'payer').empty?
              payer_codes = [{ 'code' => '1', 'system' => '2.16.840.1.113883.3.221.5', 'codeSystem' => 'SOP' }]
              cqm_patient.qdmPatient.dataElements.push QDM::PatientCharacteristicPayer.new(dataElementCodes: payer_codes, relevantPeriod: QDM::Interval.new(cqm_patient.qdmPatient.birthDatetime, nil))
            end
            safe_first_name = cqm_patient.givenNames.join(' ').delete("'")
            safe_last_name = cqm_patient.familyName.delete("'")
            entry_path = "#{i}_#{safe_first_name}_#{safe_last_name}"
            z.put_next_entry("#{entry_path}.xml")
            # TODO: R2P: make sure using correct exporter
            z << Qrda1R5.new(cqm_patient, @measures, options).render
          end
        end
        puts "#{ENV['EMAIL']} is now has #{cqm_patients.size} QRDA."
      end
    end
  end
end