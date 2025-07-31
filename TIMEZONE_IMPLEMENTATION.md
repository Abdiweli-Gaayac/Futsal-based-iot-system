# Somalia Timezone Implementation Guide

## Overview

This document explains how to implement consistent Somalia timezone (UTC+3) handling across your backend and frontend applications. The goal is to ensure that all date/time operations use Somalia timezone instead of server time or local time.

## Backend Implementation (Node.js)

### 1. Timezone Utility (`backend/utils/timezone.js`)

The backend uses a comprehensive timezone utility that handles all Somalia timezone conversions:

```javascript
// Key functions:
- getSomaliaTime() - Get current time in Somalia timezone
- toSomaliaTime(date) - Convert any date to Somalia timezone
- somaliaToUTC(date) - Convert Somalia time to UTC for storage
- utcToSomalia(date) - Convert UTC to Somalia timezone for display
- isValidBookingDateInSomalia(date) - Validate booking dates in Somalia timezone
- getSomaliaTimestamp() - Get current Somalia timestamp
```

### 2. Updated Controllers

#### Booking Controller (`backend/controllers/booking.controller.js`)

Key changes:
- All date validations now use `isValidBookingDateInSomalia()`
- Date conversions use `convertToSomaliaThenUTC()` for storage
- Display functions use `formatDateForDisplay()` for Somalia timezone
- Reference IDs use `getSomaliaTimestamp()`

#### Subscription Controller (`backend/controllers/subscription.controller.js`)

Key changes:
- Start date validation uses Somalia timezone
- All date comparisons use Somalia timezone
- Reference IDs use Somalia timestamp

### 3. Cron Jobs (`backend/cronJobs.js`)

Updated to use Somalia timezone for all time-based operations.

### 4. App Logging (`backend/app.js`)

Request logging now shows Somalia timezone timestamps.

## Frontend Implementation (Flutter)

### 1. Timezone Utility (`futsal/lib/utils/timezone.dart`)

The Flutter app uses a comprehensive timezone utility:

```dart
// Key functions:
- getSomaliaTime() - Get current time in Somalia timezone
- toSomaliaTime(date) - Convert any date to Somalia timezone
- somaliaToUTC(date) - Convert Somalia time to UTC for API calls
- utcToSomalia(date) - Convert UTC to Somalia timezone for display
- isValidBookingDateInSomalia(date) - Validate booking dates
- getTodayInSomalia() - Get today's date in Somalia timezone
- formatDateForAPI(date) - Format date for API calls (UTC)
- formatDateForDisplay(date) - Format date for display (Somalia)
```

### 2. Updated Models

#### Booking Model (`futsal/lib/models/booking.dart`)

Key changes:
- Added `somaliaDate` getter for Somalia timezone conversion
- Added `somaliaDateString` getter for formatted Somalia date
- Maintained backward compatibility with existing `localDate` methods

### 3. Screen Updates

#### Slots Screen (`futsal/lib/screens/client/slots_screen.dart`)

Key changes needed:
- Date picker should use `SomaliaTimezone.getTodayInSomalia()` for initial date
- Date validation should use `SomaliaTimezone.isValidBookingDateInSomalia()`
- Date formatting should use `SomaliaTimezone.formatDateForDisplay()`

#### Bookings Screen (`futsal/lib/screens/manager/bookings_screen.dart`)

Key changes needed:
- Date picker should use Somalia timezone
- Date comparisons should use Somalia timezone
- Display dates should be in Somalia timezone

## Deployment Considerations

### Server Deployment (Sweden, etc.)

When deploying to servers in different timezones:

1. **Server Timezone**: Set server timezone to UTC
   ```bash
   sudo timedatectl set-timezone UTC
   ```

2. **Environment Variables**: No changes needed - the timezone utilities handle all conversions

3. **Database**: Continue storing dates in UTC - the utilities handle conversion

4. **Logging**: All logs now show Somalia timezone timestamps

### API Responses

All API responses should include dates in Somalia timezone format:

```json
{
  "success": true,
  "data": {
    "booking": {
      "date": "2024-01-15", // This is in Somalia timezone
      "createdAt": "2024-01-15T10:30:00.000Z" // UTC for storage
    }
  }
}
```

## Testing

### Backend Testing

Test the timezone utilities:

```javascript
const { getSomaliaTime, isValidBookingDateInSomalia } = require('./utils/timezone');

// Test current time
console.log('Somalia time:', getSomaliaTime());

// Test date validation
const pastDate = '2023-01-01';
const futureDate = '2025-01-01';
console.log('Past date valid:', isValidBookingDateInSomalia(pastDate)); // false
console.log('Future date valid:', isValidBookingDateInSomalia(futureDate)); // true
```

### Frontend Testing

Test the timezone utilities:

```dart
import 'package:futsal/utils/timezone.dart';

void testTimezone() {
  final somaliaTime = SomaliaTimezone.getSomaliaTime();
  print('Somalia time: $somaliaTime');
  
  final isValid = SomaliaTimezone.isValidBookingDateInSomalia(DateTime.now());
  print('Today is valid for booking: $isValid');
}
```

## Migration Steps

### 1. Backend Migration

1. Add the timezone utility file
2. Update controllers to use Somalia timezone functions
3. Update cron jobs to use Somalia timezone
4. Update logging to show Somalia timezone
5. Test all date validations

### 2. Frontend Migration

1. Add the timezone utility file
2. Update models to use Somalia timezone
3. Update screens to use Somalia timezone for date pickers
4. Update API calls to convert dates properly
5. Test all date displays and validations

### 3. Database Migration

No database changes needed - continue storing dates in UTC. The utilities handle all conversions.

## Benefits

1. **Consistency**: All date/time operations use Somalia timezone
2. **User Experience**: Users see dates in their local timezone (Somalia)
3. **Deployment Flexibility**: Works regardless of server location
4. **Maintainability**: Centralized timezone logic
5. **Accuracy**: Proper handling of daylight saving time (Somalia doesn't observe DST)

## Troubleshooting

### Common Issues

1. **Date validation errors**: Ensure using `isValidBookingDateInSomalia()` instead of local timezone validation
2. **Display inconsistencies**: Ensure using `formatDateForDisplay()` for user-facing dates
3. **API errors**: Ensure using `formatDateForAPI()` when sending dates to backend

### Debugging

Add timezone debugging:

```javascript
// Backend
console.log('UTC time:', new Date());
console.log('Somalia time:', getSomaliaTime());

// Frontend
print('UTC time: ${DateTime.now()}');
print('Somalia time: ${SomaliaTimezone.getSomaliaTime()}');
```

## Future Enhancements

1. **Timezone Configuration**: Make timezone configurable via environment variables
2. **Caching**: Cache timezone conversions for better performance
3. **Internationalization**: Support multiple timezones for different regions
4. **Testing**: Add comprehensive timezone unit tests 