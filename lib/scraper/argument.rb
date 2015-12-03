class Argument < Sequel::Model
    many_to_one :user
    many_to_one :debate
    many_to_one :parent, :class=>self
    one_to_many :children, :key=>:parent_id, :class=>self
end
