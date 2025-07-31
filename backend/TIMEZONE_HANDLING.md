# Timezone Handling in Futsal System

## Overview

The system handles timezone differences between server deployment locations and the business location (Somali timezone). This is particularly important for ESP32 verification which needs to work with local time regardless of server location.

## Key Components

### 1. Timezone Configuration

**Environment Variable:**
```bash
BUSINESS_TIMEZONE=Africa/Mogadishu  # Default: Somali timezone
```

**Location:** `backend/config/env.js`

### 2. Timezone Utilities

**File:** `backend/utils/timezone.js`

**Key Functions:**
- `getSomaliTime()` - Get current time in business timezone
- `getSomaliTimeString()` - Get time as HH:MM string
- `getSomaliDateString()` - Get date as YYYY-MM-DD string
- `getTimezoneInfo()` - Debug timezone information

### 3. ESP32 Verification

**File:** `backend/controllers/booking.controller.js`

**Function:** `verifyBookingOTP()`

**Key Changes:**
- Uses Somali timezone instead of server time
- Validates booking date against Somali date
- Validates current time against slot time in Somali timezone
- Includes timezone info in response

## How It Works

### Before (Server Time)
```javascript
const now = new Date();
const currentTime = now.toTimeString().split(" ")[0].slice(0, 5);
const today = now.toISOString().split("T")[0];
```

### After (Somali Timezone)
```javascript
const somaliTime = getSomaliTime();
const currentTime = getSomaliTimeString(); // HH:MM in Somali timezone
const today = getSomaliDateString(); // YYYY-MM-DD in Somali timezone
```

## Deployment Scenarios

### Scenario 1: Server in Different Timezone
- **Server:** UTC+0 (London)
- **Business:** UTC+3 (Mogadishu)
- **Result:** ESP32 verification uses Somali time (UTC+3)

### Scenario 2: Server in Same Timezone
- **Server:** UTC+3 (Mogadishu)
- **Business:** UTC+3 (Mogadishu)
- **Result:** No difference, but still uses configured timezone

### Scenario 3: Server Timezone Changes
- **Before:** Server in UTC+0
- **After:** Server moved to UTC+5
- **Result:** ESP32 verification still uses Somali time (UTC+3)

## Testing

### Test Endpoint
```
GET /public/test-timezone
```

**Response:**
```json
{
  "success": true,
  "data": {
    "serverTimezone": "Europe/London",
    "businessTimezone": "Africa/Mogadishu",
    "serverTime": "2024-01-15 10:00:00",
    "businessTime": "2024-01-15 13:00:00",
    "isSameTimezone": false,
    "timeDifference": 3,
    "testCases": {
      "currentSomaliTime": "13:00",
      "currentSomaliDate": "2024-01-15"
    }
  }
}
```

## Configuration

### Environment Variables
```bash
# .env file
BUSINESS_TIMEZONE=Africa/Mogadishu
```

### Supported Timezones
- `Africa/Mogadishu` (Default - Somali timezone)
- `Asia/Dubai` (UAE timezone)
- `UTC` (Universal time)
- Any valid IANA timezone identifier

## Flutter App Handling

The Flutter app already handles timezone conversion correctly:
- Receives UTC dates from server
- Converts to local timezone for display
- Uses `toLocal()` method for conversion

## Database Storage

All dates are stored in UTC format:
- Booking dates: UTC midnight
- Subscription dates: UTC format
- Timestamps: UTC format

## Benefits

1. **Consistent Business Time:** ESP32 always uses Somali time regardless of server location
2. **Flexible Deployment:** Server can be deployed anywhere without affecting business logic
3. **Easy Configuration:** Timezone can be changed via environment variable
4. **Debugging Support:** Comprehensive timezone information for troubleshooting
5. **Backward Compatibility:** Existing functionality remains unchanged

## Migration Notes

- No database changes required
- Existing bookings continue to work
- Flutter app continues to work as before
- ESP32 verification now uses correct timezone 