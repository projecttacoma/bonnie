describe 'PopulationCalculationView', ->

  beforeEach ->
    jasmine.getJSONFixtures().clearCache()
    @measure = new Thorax.Models.Measure getJSONFixture('cqm_measure_data/core_measures/CMS160/CMS160v6.json'), parse: true
    @oldBonnieValueSetsByOid = bonnie.valueSetsByOid
    bonnie.valueSetsByOid = getJSONFixture('cqm_measure_data/core_measures/CMS160/value_sets.json')
    @patients = new Thorax.Collections.Patients getJSONFixture('cqm_patients/CMS160/patients.json'), parse: true
    @measure.set('patients', @patients)
    @population = @measure.get('populations').first()
    @populationCalculationView = new Thorax.Views.PopulationCalculation(model: @population)
    @populationCalculationView.render()

  afterEach ->
    bonnie.valueSetsByOid = @oldBonnieValueSetsByOid

  it 'renders correctly', ->
    expect(@populationCalculationView.$el).toContainText @patients.first().get('last')

  it 'does not have a "Share" button', ->
    expect(@populationCalculationView.$('span[class=btn-label]').length).toEqual(0)
