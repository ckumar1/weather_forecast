# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 20_250_605_075_231) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'plpgsql'

  create_table 'forecasts', force: :cascade do |t|
    t.bigint 'location_id', null: false
    t.decimal 'current_temp', precision: 5, scale: 2
    t.decimal 'high_temp', precision: 5, scale: 2
    t.decimal 'low_temp', precision: 5, scale: 2
    t.string 'conditions'
    t.datetime 'forecast_timestamp'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['location_id'], name: 'index_forecasts_on_location_id'
  end

  create_table 'locations', force: :cascade do |t|
    t.string 'address'
    t.string 'city'
    t.string 'state'
    t.string 'zipcode'
    t.string 'country'
    t.decimal 'latitude', precision: 10, scale: 6
    t.decimal 'longitude', precision: 10, scale: 6
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index %w[latitude longitude], name: 'index_locations_on_latitude_and_longitude'
    t.index %w[state city], name: 'index_locations_on_state_and_city'
    t.index ['zipcode'], name: 'index_locations_on_zipcode'
  end

  add_foreign_key 'forecasts', 'locations'
end
