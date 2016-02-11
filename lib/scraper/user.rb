class User < Sequel::Model
  unrestrict_primary_key
  one_to_many :debates
  one_to_many :arguments
end
