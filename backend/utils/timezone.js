import moment from "moment-timezone";
import { BUSINESS_TIMEZONE } from "../config/env.js";

// Configuration
const BUSINESS_TIMEZONE_NAME = BUSINESS_TIMEZONE || "Africa/Mogadishu";

/**
 * Get current time in business timezone (default: Somali)
 * @returns {moment.Moment} Current time in business timezone
 */
export const getSomaliTime = () => {
  return moment().tz(BUSINESS_TIMEZONE_NAME);
};

/**
 * Get current time in business timezone as HH:MM string
 * @returns {string} Current time in HH:MM format (business timezone)
 */
export const getSomaliTimeString = () => {
  return getSomaliTime().format("HH:mm");
};

/**
 * Get current date in business timezone as YYYY-MM-DD string
 * @returns {string} Current date in YYYY-MM-DD format (business timezone)
 */
export const getSomaliDateString = () => {
  return getSomaliTime().format("YYYY-MM-DD");
};

/**
 * Convert a UTC date to business timezone
 * @param {Date|string} utcDate - UTC date to convert
 * @returns {moment.Moment} Date in business timezone
 */
export const convertUTCToSomali = (utcDate) => {
  return moment.utc(utcDate).tz(BUSINESS_TIMEZONE_NAME);
};

/**
 * Check if server is already in business timezone
 * @returns {boolean} True if server timezone matches business timezone
 */
export const isServerInSomaliTimezone = () => {
  const serverTimezone = moment.tz.guess();
  return serverTimezone === BUSINESS_TIMEZONE_NAME;
};

/**
 * Get timezone information for debugging
 * @returns {object} Timezone information
 */
export const getTimezoneInfo = () => {
  const somaliTime = getSomaliTime();
  const serverTime = moment();
  
  return {
    serverTimezone: moment.tz.guess(),
    businessTimezone: BUSINESS_TIMEZONE_NAME,
    serverTime: serverTime.format("YYYY-MM-DD HH:mm:ss"),
    businessTime: somaliTime.format("YYYY-MM-DD HH:mm:ss"),
    isSameTimezone: isServerInSomaliTimezone(),
    timeDifference: somaliTime.diff(serverTime, "hours", true)
  };
};

/**
 * Validate if a time string is within Somali business hours (optional)
 * @param {string} timeString - Time in HH:MM format
 * @returns {boolean} True if within business hours
 */
export const isWithinSomaliBusinessHours = (timeString) => {
  const [hours] = timeString.split(":").map(Number);
  // Assuming business hours are 6 AM to 11 PM
  return hours >= 6 && hours < 23;
}; 