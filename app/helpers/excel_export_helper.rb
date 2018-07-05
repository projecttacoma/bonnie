require 'uri'

module ExcelExportHelper
  def self.convert_results_for_excel_export(results)
    # Convert results from the back-end calculator to the format
    # expected the excel export module

    results_for_excel_export = {}
    # TODO: do conversion here

    ####################################################################################
    # These are snippets from the existing conversion in measure_view.js.coffee
    ####################################################################################
    # for pop in @model.get('populations').models
    #   for patient in @model.get('patients').models
    #     if calc_results[pop.cid] == undefined
    #       calc_results[pop.cid] = {}
    #     # Re-calculate results before excel export (we need to include pretty result generation)
    #     bonnie.calculator_selector.clearResult pop, patient
    #     result = pop.calculate(patient, {doPretty: true})
    #     result_criteria = {}
    #     for pop_crit of result.get('population_relevance')
    #       result_criteria[pop_crit] = result.get(pop_crit)
    #     calc_results[pop.cid][patient.cid] = {statement_results: @removeExtra(result.get("statement_results")), criteria: result_criteria}
    ####################################################################################
    # TODO: do any other conversion needed
    return results_for_excel_export
  end

  def self.get_patient_details_from_measure(measure, patients)
    patient_details = {}
    measure.populations.each do | population |
      patients.each do | patient |
        if !patient_details[patient.id]
          patient_details[patient.id] = {
            first: patient.first,
            last: patient.last,
            expected_values: patient.expected_values,
            birthdate: patient.birthdate,
            expired: patient.expired,
            deathdate: patient.deathdate,
            ethnicity: patient.ethnicity,
            race: patient.race,
            gender: patient.gender,
            notes: patient.notes
          }
        end
      end
    end
    return patient_details
  end

  def get_population_details_from_measure(measure)
    population_details = {}
    ####################################################################################
    # These are snippets from the existing conversion in measure_view.js.coffee
    ####################################################################################
    # for pop in @model.get('populations').models
    #   for patient in @model.get('patients').models
    #   # Populates the population details
    #     if (population_details[pop.cid] == undefined)
    #       population_details[pop.cid] = {title: pop.get("title"), statement_relevance: result.get("statement_relevance")}
    #       criteria = []
    #       for popAttrs of pop.attributes
    #         if (popAttrs != "title" && popAttrs != "sub_id" && popAttrs != "title")
    #           criteria.push(popAttrs)
    #       population_details[pop.cid]["criteria"] = criteria
    ####################################################################################
    return population_details
  end

  def get_statement_details_from_measure(measure)
    # Builds a map of define statement name to the statement's text from a measure.
    statement_details = {}

    measure.elm_annotations.each do |lib|
      lib_statements = {}
      measure.elm_annotations[lib].statements.each do |statement|
        lib_statements[statement.define_name] = parseAnnotationTree(statement.children)
      end
      statement_details[lib] = lib_statements
    end

    return statement_details
  end

  private_class_method def self.parseAnnotationTree(children)
    # Recursive function that parses an annotation tree to extract text statements.
    ret = ""
    if children.text
      return URI.unescape(children.text).sub("&#13", "").sub(";", "")
    end

    if children.children
      children.children.each do |child|
        ret = ret + parseAnnotationTree(child)
      end
    end

    children.each do |child|
      ret = ret + parseAnnotationTree(child)
    end

    return ret
  end

end