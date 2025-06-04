FactoryBot.define do
  factory :forecast do
    location { nil }
    current_temp { "9.99" }
    high_temp { "9.99" }
    low_temp { "9.99" }
    conditions { "MyString" }
    forecast_timestamp { "2025-06-04 09:26:06" }
    from_cache { false }
  end
end
