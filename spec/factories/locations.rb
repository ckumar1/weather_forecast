FactoryBot.define do
  factory :location do
    sequence(:address) { |n| "#{n} Main Street, Cupertino, CA 95014" }

    city { "Cupertino" }
    state { "CA" }
    zipcode { "95014" }
    country { "US" }
    latitude { 37.331686 }
    longitude { -122.030656 }

    trait :not_geocoded do
      latitude { nil }
      longitude { nil }
      city { nil }
      state { nil }
      zipcode { nil }
      country { nil }
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
