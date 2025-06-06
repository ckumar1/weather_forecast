# frozen_string_literal: true

class AddDefaultsToForecasts < ActiveRecord::Migration[7.1]
  def change
    change_column_default :forecasts, :from_cache, false
  end
end
