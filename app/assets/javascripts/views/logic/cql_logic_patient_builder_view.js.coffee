class Thorax.Views.CqlPatientBuilderLogic extends Thorax.Views.BonnieView

  template: JST['logic/cql_patient_builder_logic']

  initialize: ->
    @population_names = Object.keys(@model.get('population_criteria'))
    @results = {}
    for pop in @population_names
      @results[pop] = 0
    @cqlLogicView = new Thorax.Views.CqlPopulationLogic(model: @model, highlightPatientDataEnabled: true, population: @population)

  showRationale: (result) ->
    for pop in @population_names
      @results[pop] = result.get(pop)
    @cqlLogicView.showRationale result
    @render()
