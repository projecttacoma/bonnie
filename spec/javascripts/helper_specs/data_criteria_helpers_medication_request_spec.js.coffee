describe 'DataCriteriaHelpers', ->

  describe 'Medication Request attributes', ->
    it 'should support MedicationRequest.status', ->
      DataCriteriaAsserts.assertCode('MedicationRequest', 'status', 'status', (fhirResource) -> cqm.models.MedicationRequestStatus.isMedicationRequestStatus(fhirResource.status))

    it 'should support MedicationRequest.intent', ->
      DataCriteriaAsserts.assertCode('MedicationRequest', 'intent', 'intent', (fhirResource) -> cqm.models.MedicationRequestIntent.isMedicationRequestIntent(fhirResource.intent))

    it 'should support MedicationRequest.category', ->
      DataCriteriaAsserts.assertCodeableConcept('MedicationRequest', 'category', 'category')

    it 'should support MedicationRequest.reasonCode', ->
      DataCriteriaAsserts.assertCodeableConcept('MedicationRequest', 'reasonCode', 'reasonCode')

    it 'should support MedicationRequest.statusReason', ->
      DataCriteriaAsserts.assertCodeableConcept('MedicationRequest', 'statusReason', 'statusReason')

    it 'should support MedicationRequest.dosageInstruction.timing.code', ->
      DataCriteriaAsserts.assertCodeableConcept('MedicationRequest', 'dosageInstruction.timing.code', 'dosageInstruction.timing.code')

    it 'should support MedicationRequest.dispenseRequest.validityPeriod', ->
      DataCriteriaAsserts.assertPeriod('MedicationRequest', 'dispenseRequest.validityPeriod', 'dispenseRequest.validityPeriod')

    it 'should support MedicationRequest.dosageInstruction.doseAndRate.rate', ->
      attrs = DataCriteriaHelpers.DATA_ELEMENT_ATTRIBUTES['MedicationRequest']
      attr = attrs.find (attr) => attr.path is 'dosageInstruction.doseAndRate.rate'
      expect(attr.path).toEqual 'dosageInstruction.doseAndRate.rate'
      expect(attr.title).toEqual 'dosageInstruction.doseAndRate.rate'
      expect(attr.types).toEqual [ 'Ratio', 'Range', 'SimpleQuantity' ]

      fhirResource = new cqm.models['MedicationRequest']()

      # Ratio
      ratio = cqm.models.Ratio.parse({"numerator": {"value": "1", "unit": "ms"}, "denominator": {"value": "2", "unit": "ms"}})
      attr.setValue(fhirResource, ratio)
      value = attr.getValue(fhirResource.clone())

      expect(value.numerator.value.value).toEqual '1'
      expect(value.numerator.unit.value).toEqual 'ms'

      expect(value.denominator.value.value).toEqual '2'
      expect(value.denominator.unit.value).toEqual 'ms'

      # Range
      range = cqm.models.Range.parse({"low": {"value": "3", "unit": "h"}, "high": {"value": "4", "unit": "h"}})
      attr.setValue(fhirResource, range)
      value = attr.getValue(fhirResource.clone())

      expect(value.low.value.value).toEqual '3'
      expect(value.low.unit.value).toEqual 'h'

      expect(value.high.value.value).toEqual '4'
      expect(value.high.unit.value).toEqual 'h'

      # SimpleQuantity
      simpleQuantity = cqm.models.SimpleQuantity.parse({"value": 13, "unit": "kg"})
      attr.setValue(fhirResource, simpleQuantity)
      value = attr.getValue(fhirResource.clone())

      expect(value.value.value).toEqual 13
      expect(value.unit.value).toEqual 'kg'

    it 'should support MedicationRequest.dosageInstructions.timing.repeat.bounds', ->
      attrs = DataCriteriaHelpers.DATA_ELEMENT_ATTRIBUTES['MedicationRequest']
      attr = attrs.find (attr) => attr.path is 'dosageInstructions.timing.repeat.bounds'
      expect(attr.path).toEqual 'dosageInstructions.timing.repeat.bounds'
      expect(attr.title).toEqual 'dosageInstructions.timing.repeat.bounds'
      expect(attr.types).toEqual [ 'Duration', 'Range', 'Period' ]

      fhirResource = new cqm.models['MedicationRequest']()

      # Duration
      duration = cqm.models.Duration.parse({"unit": "ml", "value": "100"})
      attr.setValue(fhirResource, duration)
      value = attr.getValue(fhirResource.clone())

      expect(value.value.value).toEqual '100'
      expect(value.unit.value).toEqual 'ml'

      # Range
      range = cqm.models.Range.parse({"low": {"value": "3", "unit": "h"}, "high": {"value": "4", "unit": "h"}})
      attr.setValue(fhirResource, range)
      value = attr.getValue(fhirResource.clone())

      expect(value.low.value.value).toEqual '3'
      expect(value.low.unit.value).toEqual 'h'

      expect(value.high.value.value).toEqual '4'
      expect(value.high.unit.value).toEqual 'h'

      # Period
      DataCriteriaAsserts.assertPeriod('MedicationRequest', 'dosageInstructions.timing.repeat.bounds', 'dosageInstructions.timing.repeat.bounds')
      period = new cqm.models.Period()
      period.start = cqm.models.PrimitiveDateTime.parsePrimitive('2020-09-02T13:54:57')
      period.end = cqm.models.PrimitiveDateTime.parsePrimitive('2020-10-02T13:54:57')

      attr.setValue(fhirResource, period)
      value = attr.getValue(fhirResource.clone())

      expect(value.start.value).toEqual '2020-09-02T13:54:57'
      expect(value.end.value).toEqual '2020-10-02T13:54:57'
