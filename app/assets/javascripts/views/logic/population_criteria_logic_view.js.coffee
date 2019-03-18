class Thorax.Views.PopulationCriteriaLogic extends Thorax.Views.BonnieView
  template: JST['logic/population_criteria']
  events:
    'click .panel-population' : -> @$('.toggle-icon').toggleClass('fa-angle-right fa-angle-down')
  population_map:
    'IPP': 'Initial Population'
    'STRAT': 'Stratification'
    'DENOM': 'Denominator'
    'NUMER': 'Numerator'
    'NUMEX': 'Numerator Exclusions'
    'DENEXCEP': 'Denominator Exceptions'
    'DENEX': 'Denominator Exclusions'
    'MSRPOPL': 'Measure Population'
    'OBSERV': 'Measure Observations'
    'MSRPOPLEX': 'Measure Population Exclusions'
  aggregator_map:
    'MEAN':'Mean of'
    'MEDIAN':'Median of'

  initialize: ->
    @rootPreconditon = @population.preconditions[0] if @population.preconditions?.length > 0
    @aggregator = @population.aggregator
    @comments = _(@rootPreconditon?.comments || []).union(@population?.comments || [])

  translate_population: (code) ->
    @population_map[code]

  translate_aggregator: (code) ->
    @aggregator_map[code]
