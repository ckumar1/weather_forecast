# frozen_string_literal: true

class AddIndexesToLocations < ActiveRecord::Migration[7.1]
  def change
    add_index :locations, :zipcode
    add_index :locations, %i[state city]
    add_index :locations, %i[latitude longitude]
  end
end
