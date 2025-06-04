FactoryBot.define do
  factory :forecast do
    association :location
    current_temp { 72.5 }
    high_temp { 78.0 }
    low_temp { 65.0 }
    conditions { "Partly Cloudy" }
    forecast_timestamp { Time.current }
    from_cache { false }
    
    trait :cached do
      from_cache { true }
    end
    
    trait :expired do
      forecast_timestamp { 31.minutes.ago }
    end
  end
end
