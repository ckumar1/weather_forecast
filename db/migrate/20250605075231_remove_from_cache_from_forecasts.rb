class RemoveFromCacheFromForecasts < ActiveRecord::Migration[7.1]
  def change
    remove_column :forecasts, :from_cache, :boolean, default: false
  end
end
