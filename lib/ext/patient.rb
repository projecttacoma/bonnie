module QDM
  class Patient
    field :measure_ids, type: Array
   
    belongs_to :user
    scope :by_measure_id, ->(id) { where({'measure_id'=>id }) }
    scope :by_user, ->(user) { where({'user_id'=>user.id}) }
    index "user_id" => 1
  end
end