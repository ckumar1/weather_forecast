class CreateForecasts < ActiveRecord::Migration[7.1]
  def change
    create_table :forecasts do |t|
      t.references :location, null: false, foreign_key: true
      t.decimal :current_temp, precision: 5, scale: 2
      t.decimal :high_temp, precision: 5, scale: 2
      t.decimal :low_temp, precision: 5, scale: 2
      t.string :conditions
      t.datetime :forecast_timestamp
      t.boolean :from_cache

      t.timestamps
    end
  end
end
