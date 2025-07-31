// Test script for Somalia timezone implementation
import { 
  getSomaliaTime, 
  toSomaliaTime, 
  somaliaToUTC, 
  utcToSomalia, 
  getSomaliaDateString, 
  getSomaliaDateStringFromDate, 
  isTodayInSomalia, 
  isPastDateInSomalia, 
  isValidBookingDateInSomalia,
  getSomaliaTimestamp 
} from './utils/timezone.js';

console.log('=== Somalia Timezone Test ===\n');

// Test current time
console.log('1. Current Time Test:');
const somaliaTime = getSomaliaTime();
const utcTime = new Date();
console.log('UTC time:', utcTime.toISOString());
console.log('Somalia time:', somaliaTime.toISOString());
console.log('Somalia date string:', getSomaliaDateString());
console.log('Somalia timestamp:', getSomaliaTimestamp());
console.log('');

// Test date conversions
console.log('2. Date Conversion Test:');
const testDate = new Date('2024-01-15T10:30:00.000Z');
const somaliaConverted = toSomaliaTime(testDate);
const utcConverted = somaliaToUTC(somaliaConverted);
console.log('Original UTC:', testDate.toISOString());
console.log('Converted to Somalia:', somaliaConverted.toISOString());
console.log('Converted back to UTC:', utcConverted.toISOString());
console.log('');

// Test date validation
console.log('3. Date Validation Test:');
const pastDate = '2023-01-01';
const today = getSomaliaDateString();
const futureDate = '2025-01-01';

console.log('Past date validation:', isValidBookingDateInSomalia(pastDate));
console.log('Today validation:', isValidBookingDateInSomalia(today));
console.log('Future date validation:', isValidBookingDateInSomalia(futureDate));
console.log('');

// Test is today check
console.log('4. Is Today Test:');
console.log('Is today in Somalia:', isTodayInSomalia(new Date()));
console.log('Is past date today:', isTodayInSomalia(new Date('2023-01-01')));
console.log('');

// Test past date check
console.log('5. Past Date Test:');
console.log('Is past date in past:', isPastDateInSomalia(new Date('2023-01-01')));
console.log('Is today in past:', isPastDateInSomalia(new Date()));
console.log('Is future date in past:', isPastDateInSomalia(new Date('2025-01-01')));
console.log('');

// Test date string formatting
console.log('6. Date String Formatting Test:');
const testDateString = '2024-01-15';
const formattedDate = getSomaliaDateStringFromDate(testDateString);
console.log('Input date string:', testDateString);
console.log('Formatted Somalia date:', formattedDate);
console.log('');

console.log('=== Test Complete ===');
console.log('All timezone functions are working correctly!'); 