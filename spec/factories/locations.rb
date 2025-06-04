FactoryBot.define do
  factory :location do
    sequence(:address) { |n| "#{n} Main Street, Cupertino, CA 95014" }
    skip_geocoding { true }

    city { "Cupertino" }
    state { "CA" }
    zipcode { "95014" }
    country { "US" }

    trait :not_geocoded do
      latitude { nil }
      longitude { nil }
      city { nil }
      state { nil }
      zipcode { nil }
      country { nil }
    end

    trait :geocoded do
      latitude { 37.331686 }
      longitude { -122.030656 }
    end

    trait :with_geocoding do
      skip_geocoding { false }
    end

    trait :san_francisco do
      sequence(:address) { |n| "#{n} Market Street, San Francisco, CA 94105" }
      city { "San Francisco" }
      state { "CA" }
      zipcode { "94105" }
      latitude { 37.794220 }
      longitude { -122.395055 }
    end
  end
end
