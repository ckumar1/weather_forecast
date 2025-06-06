# Weather Forecast Application

## Overview
A Ruby on Rails application that allows users to manage locations and view weather forecasts using the WeatherAPI service.

## System Architecture

### Core Components
- **Location Model**: Manages geographic locations with geocoding
- **Forecast Model**: Stores weather data with caching logic
- **WeatherApiService**: Handles external API communication
- **LocationsController**: Web interface for location management

### Data Flow
1. User adds location → Address geocoding via Geocoder gem → Weather API call → Cache storage
2. Subsequent requests use cached data (30-minute TTL) for optimal performance
3. Two-tier caching: Database-level (Forecast model) + Rails cache for API responses

### Design Patterns Implemented
- **Service Layer Pattern**: Business logic and external integrations encapsulated in WeatherApiService
- **Result Pattern**: Consistent success/failure handling across API calls
- **Factory Pattern**: Used in test suite for clean test data generation

## Setup Instructions

### Prerequisites
- Ruby 3.4.4
- Rails 7.1.5
- PostgreSQL

### Environment Variables
Create a `.env` file in the root directory:
```bash
WEATHER_API_KEY=your_api_key_here
WEATHER_API_BASE_URL=https://api.weatherapi.com/v1
```

### Installation
```bash
# Clone and setup
git clone <repository-url>
cd weather_forecast

# Install dependencies
bundle install
rails db:create db:migrate
rails server
```

## API Integration
Uses WeatherAPI.com for weather data with intelligent caching strategy.

### Caching Strategy
1. **Database Cache**: Forecasts stored with 30-minute TTL
2. **Rails Cache**: API responses cached to prevent duplicate calls

## Testing
Comprehensive test suite using RSpec

```bash
# Run all tests
bundle exec rspec
```

### Test Features
- Unit tests for all models and services
- Controller integration tests
- VCR cassettes for API mocking
- Factory-based test data generation
- Edge case and error condition testing

## Scalability Considerations

### Database Optimization
- Indexed columns for location lookups (lat/lng, zipcode)
- Limit location index queries to 10 most recently added locations to prevent unbounded result sets

## Development Workflow

### Code Quality
```bash
# Run linting
bundle exec rubocop
```
### Security
- Environment variables for sensitive data
- HTTPS enforced in production
- CSRF protection enabled
- SQL injection prevention via parameterized queries
