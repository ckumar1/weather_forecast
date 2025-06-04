class AddIndexesToLocations < ActiveRecord::Migration[7.1]
  def change
    add_index :locations, :zipcode
    add_index :locations, [:state, :city]
    add_index :locations, [:latitude, :longitude]
  end
end
