// Timezone utilities for Somalia (EAT - East Africa Time)
// Somalia is UTC+3

const SOMALIA_TIMEZONE = 'Africa/Mogadishu';

/**
 * Get current time in Somalia timezone
 * @returns {Date} Current date/time in Somalia timezone
 */
export const getSomaliaTime = () => {
  const now = new Date();
  const somaliaTime = new Date(now.toLocaleString("en-US", {timeZone: SOMALIA_TIMEZONE}));
  return somaliaTime;
};

/**
 * Convert a date to Somalia timezone
 * @param {Date|string} date - Date to convert
 * @returns {Date} Date in Somalia timezone
 */
export const toSomaliaTime = (date) => {
  const inputDate = new Date(date);
  return new Date(inputDate.toLocaleString("en-US", {timeZone: SOMALIA_TIMEZONE}));
};

/**
 * Convert Somalia time to UTC for storage
 * @param {Date|string} somaliaDate - Date in Somalia timezone
 * @returns {Date} Date in UTC
 */
export const somaliaToUTC = (somaliaDate) => {
  const date = new Date(somaliaDate);
  // Create a date string in Somalia timezone
  const somaliaString = date.toLocaleString("en-US", {timeZone: SOMALIA_TIMEZONE});
  // Parse it back to get the UTC equivalent
  const utcDate = new Date(somaliaString);
  return utcDate;
};

/**
 * Convert UTC date to Somalia timezone for display
 * @param {Date|string} utcDate - Date in UTC
 * @returns {Date} Date in Somalia timezone
 */
export const utcToSomalia = (utcDate) => {
  const date = new Date(utcDate);
  return new Date(date.toLocaleString("en-US", {timeZone: SOMALIA_TIMEZONE}));
};

/**
 * Get current Somalia date in YYYY-MM-DD format
 * @returns {string} Current date in Somalia timezone as YYYY-MM-DD
 */
export const getSomaliaDateString = () => {
  const somaliaTime = getSomaliaTime();
  return somaliaTime.toISOString().split('T')[0];
};

/**
 * Get Somalia date string from a date
 * @param {Date|string} date - Date to convert
 * @returns {string} Date in Somalia timezone as YYYY-MM-DD
 */
export const getSomaliaDateStringFromDate = (date) => {
  const somaliaTime = toSomaliaTime(date);
  return somaliaTime.toISOString().split('T')[0];
};

/**
 * Check if a date is today in Somalia timezone
 * @param {Date|string} date - Date to check
 * @returns {boolean} True if date is today in Somalia timezone
 */
export const isTodayInSomalia = (date) => {
  const somaliaToday = getSomaliaDateString();
  const somaliaDate = getSomaliaDateStringFromDate(date);
  return somaliaToday === somaliaDate;
};

/**
 * Check if a date is in the past in Somalia timezone
 * @param {Date|string} date - Date to check
 * @returns {boolean} True if date is in the past in Somalia timezone
 */
export const isPastDateInSomalia = (date) => {
  const somaliaToday = getSomaliaTime();
  const somaliaDate = toSomaliaTime(date);
  somaliaToday.setHours(0, 0, 0, 0);
  somaliaDate.setHours(0, 0, 0, 0);
  return somaliaDate < somaliaToday;
};

/**
 * Get Somalia time string in HH:MM format
 * @param {Date|string} date - Date to convert
 * @returns {string} Time in HH:MM format in Somalia timezone
 */
export const getSomaliaTimeString = (date) => {
  const somaliaTime = toSomaliaTime(date);
  return somaliaTime.toTimeString().slice(0, 5);
};

/**
 * Create a date object for a specific date in Somalia timezone
 * @param {string} dateString - Date string in YYYY-MM-DD format
 * @returns {Date} Date object representing the date in Somalia timezone
 */
export const createSomaliaDate = (dateString) => {
  const [year, month, day] = dateString.split('-').map(Number);
  // Create date in Somalia timezone
  const somaliaDate = new Date(year, month - 1, day);
  return somaliaDate;
};

/**
 * Validate if a booking date is valid (not in past) in Somalia timezone
 * @param {Date|string} date - Date to validate
 * @returns {boolean} True if date is valid for booking
 */
export const isValidBookingDateInSomalia = (date) => {
  return !isPastDateInSomalia(date);
};

/**
 * Get current Somalia timestamp
 * @returns {number} Current timestamp in Somalia timezone
 */
export const getSomaliaTimestamp = () => {
  return getSomaliaTime().getTime();
}; 