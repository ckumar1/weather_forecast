VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = false
  
  config.default_cassette_options = {
    serialize_with: :json,
    preserve_exact_body_bytes: true,
    decode_compressed_response: true,
    record: :new_episodes
  }
  
  # Filter sensitive data
  config.filter_sensitive_data('<WEATHER_API_KEY>') { ENV['WEATHER_API_KEY'] }
  
  # Ignore localhost and test domains
  config.ignore_localhost = true
end
