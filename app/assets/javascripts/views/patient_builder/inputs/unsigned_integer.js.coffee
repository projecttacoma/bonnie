
# Input view for Integer types.
class Thorax.Views.InputUnsignedIntegerView extends Thorax.Views.BonnieView
  template: JST['patient_builder/inputs/unsigned_integer']

  # Expected options to be passed in using the constructor options hash:
  #   initialValue - positive integer - Optional. Initial value of unsigned integer.
  #   placeholder - string - Optional. placeholder text to show. will use 'unsigned integer' if not specified
  initialize: ->
    if @initialValue?
      @value = @initialValue
    else
      @value = null

  events:
    'change input': 'handleInputChange'
    'keyup input': 'handleInputChange'

  # checks if the value in this view is valid. returns true or false. this is used by the attribute entry view to determine
  # if the add button should be active or not
  hasValidValue: ->
    @value?

  handleInputChange: (e) ->
    inputValue = @$(e.target).val()
    if /^([0]|([1-9][0-9]*))$/.test(inputValue)
      parsed = parseInt(inputValue)
      if isNaN(parsed)
        @value = null
      else
        @value = cqm.models.PrimitiveUnsignedInt.parsePrimitive(parsed)
    else
      @value = null
    @trigger 'valueChanged', @
