class Debate < Sequel::Model
    many_to_one :user
    one_to_many :arguments
end
