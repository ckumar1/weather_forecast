# System Architecture & Object Decomposition

## Core Components

### Location Model
**Responsibilities:**
- Address geocoding with single API call optimization
- Weather data association management
- Cache key generation for weather lookups

**Key Design Decisions:**
- `has_one :forecast` - One current forecast per location
- `scope :recent` - Limits index queries to 10 records to prevent unbounded result sets
- Custom `geocode` method extracts all address components (city, state, zipcode) in one API call instead of multiple

### Forecast Model  
**Responsibilities:**
- Weather data storage with 30-minute TTL
- Cache expiration logic via `current?` method
- Temperature formatting for display

**Key Design Decisions:**
- `CACHE_DURATION = 30.minutes`
- `forecast_timestamp` tracks when data was fetched, not when record was created

### WeatherApiService
**Responsibilities:**
- External API integration with error handling
- Two-tier caching strategy implementation
- Result pattern for consistent success/failure handling

**Caching Strategy (Database-First):**
1. Check `location.forecast&.current?` first (leverages Rails association caching)
2. Check Rails cache only if no current database forecast
3. API call as last resort

**Why Database-First:**
- `location.forecast` is already loaded/cached by ActiveRecord associations
- Avoids cache/database synchronization complexity
- Database is single source of truth
- Most requests hit the fast path (existing current forecast)

## Design Patterns Used

**Service Layer Pattern** - Business logic encapsulated in WeatherApiService
**Result Pattern** - Consistent error handling with success/failure states
**Active Record Pattern** - Domain models with built-in persistence

## Performance Considerations

**Location Limiting:** `scope :recent` prevents loading thousands of locations on index page, which would trigger thousands of weather API calls

**Geocoding Optimization:** Custom geocode method extracts city, state, zipcode in single API call rather than making a second separate request for those components by searching based on the coordinates

**Association Loading:** Database-first caching leverages Rails' built-in association optimization rather than fighting against it

## Security Implementation

- **CSRF Protection:** `protect_from_forgery with: :exception`
- **SQL Injection Prevention:** ActiveRecord parameterized queries throughout
- **Environment Variables:** API keys and sensitive config externalized
- **Strong Parameters:** Mass assignment protection on all write operations
