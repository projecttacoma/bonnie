###*
# The adapter for starting the CQM execution engine.
###
@CQMCalculator = class CQMCalculator extends Calculator

  calculate: (population, patient, options = {}) ->
    measure = population.collection.parent
    # We store both the calculation result and the calcuation code based on keys derived from the arguments
    cacheKey = @cacheKey(population, patient)
    calcKey = @calculationKey(population)
    # We only ever generate a single result for a population / patient pair; if we've ever generated a
    # result for this pair, we use that result and return it, starting its calculation if needed
    result = @resultsCache[cacheKey] ?= new Thorax.Models.Result({}, population: population, patient: patient)

    # If the result is marked as 'cancelled', that means a cancellation has been requested but not yet handled in
    # the deferred calculation code; however, since we're here, that means a new calculation has been requested
    # subsequent to the cancellation; just change the state back to 'pending' to reflected our updated desire, and
    # the still pending deferred calculation will do the correct thing
    result.state = 'pending' if result.state == 'cancelled'

    # If the result already finished calculating, or is in-process with a pending calculation, we can just return it
    return result if result.state == 'complete' || result.state == 'pending'

    # Since we're going to start a calculation for this one, set the state to 'pending'
    result.state = 'pending'
    
    if !patient.has('cqmPatient')
      result.state = 'cancelled'
      console.log "No CQM patient for #{patient.get('_id')} - #{patient.get('first')} #{patient.get('last')}"
      return result

    if !measure.has('cqmMeasure')
      result.state = 'cancelled'
      console.log "No CQM measure for #{measure.get('cms_id')}"
      return result

    cqmMeasure = measure.get('cqmMeasure')
    cqmValueSets = measure.get('cqmValueSets')
    cqmPatient = patient.get('cqmPatient')
    cqmResults = cqm.execution.Calculator.calculate(cqmMeasure, [cqmPatient], cqmValueSets, { doPretty: true, includeClauseResults: true })
    
    patientResults = cqmResults[patient.id]
    populationSetResults = patientResults[cqmMeasure.population_sets[population.get('index')].population_set_id]
    result.set(populationSetResults.toObject())
    result.state = 'complete'
    console.log "finished calculation of #{cqmMeasure.cms_id} - #{patient.get('first')} #{patient.get('last')}"
    return result
