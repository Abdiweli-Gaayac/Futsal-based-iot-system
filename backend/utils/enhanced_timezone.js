import moment from "moment-timezone";
import { BUSINESS_TIMEZONE } from "../config/env.js";

// Configuration
const BUSINESS_TIMEZONE_NAME = BUSINESS_TIMEZONE || "Africa/Mogadishu";

/**
 * Enhanced timezone utilities with DST handling
 */
export class EnhancedTimezone {
  /**
   * Get current time in business timezone with DST awareness
   */
  static getBusinessTime() {
    return moment().tz(BUSINESS_TIMEZONE_NAME);
  }

  /**
   * Get current time as HH:MM string in business timezone
   */
  static getBusinessTimeString() {
    return this.getBusinessTime().format("HH:mm");
  }

  /**
   * Get current date as YYYY-MM-DD string in business timezone
   */
  static getBusinessDateString() {
    return this.getBusinessTime().format("YYYY-MM-DD");
  }

  /**
   * Convert UTC date to business timezone with DST handling
   */
  static convertUTCToBusiness(utcDate) {
    return moment.utc(utcDate).tz(BUSINESS_TIMEZONE_NAME);
  }

  /**
   * Convert business timezone date to UTC
   */
  static convertBusinessToUTC(businessDate) {
    return moment.tz(businessDate, BUSINESS_TIMEZONE_NAME).utc();
  }

  /**
   * Create UTC date from business timezone components
   */
  static createUTCDateFromBusiness(year, month, day, hour = 0, minute = 0) {
    return moment.tz([year, month - 1, day, hour, minute], BUSINESS_TIMEZONE_NAME).utc();
  }

  /**
   * Check if a date is today in business timezone
   */
  static isTodayInBusiness(date) {
    const businessToday = this.getBusinessDateString();
    const businessDate = this.convertUTCToBusiness(date).format("YYYY-MM-DD");
    return businessToday === businessDate;
  }

  /**
   * Check if a date is in the future in business timezone
   */
  static isFutureInBusiness(date) {
    const businessNow = this.getBusinessTime();
    const businessDate = this.convertUTCToBusiness(date);
    return businessDate.isAfter(businessNow, 'day');
  }

  /**
   * Check if a date is in the past in business timezone
   */
  static isPastInBusiness(date) {
    const businessNow = this.getBusinessTime();
    const businessDate = this.convertUTCToBusiness(date);
    return businessDate.isBefore(businessNow, 'day');
  }

  /**
   * Get date range for a month in business timezone
   */
  static getMonthRangeInBusiness(year, month) {
    const start = moment.tz([year, month - 1, 1], BUSINESS_TIMEZONE_NAME);
    const end = moment.tz([year, month, 0], BUSINESS_TIMEZONE_NAME);
    return { start: start.utc(), end: end.utc() };
  }

  /**
   * Get next occurrence of a day of week in business timezone
   */
  static getNextDayOfWeekInBusiness(dayOfWeek, startDate = null) {
    const start = startDate ? this.convertUTCToBusiness(startDate) : this.getBusinessTime();
    const currentDay = start.day();
    const daysUntilNext = (dayOfWeek - currentDay + 7) % 7;
    return start.add(daysUntilNext, 'days').utc();
  }

  /**
   * Validate time string format (HH:MM)
   */
  static isValidTimeString(timeString) {
    return /^([01]?[0-9]|2[0-3]):[0-5][0-9]$/.test(timeString);
  }

  /**
   * Compare time strings (HH:MM format)
   */
  static compareTimeStrings(time1, time2) {
    if (!this.isValidTimeString(time1) || !this.isValidTimeString(time2)) {
      throw new Error('Invalid time format. Use HH:MM');
    }
    
    const [hours1, minutes1] = time1.split(':').map(Number);
    const [hours2, minutes2] = time2.split(':').map(Number);
    
    const totalMinutes1 = hours1 * 60 + minutes1;
    const totalMinutes2 = hours2 * 60 + minutes2;
    
    return totalMinutes1 - totalMinutes2;
  }

  /**
   * Check if time is within business hours
   */
  static isWithinBusinessHours(timeString, startHour = 6, endHour = 23) {
    if (!this.isValidTimeString(timeString)) return false;
    
    const [hours] = timeString.split(':').map(Number);
    return hours >= startHour && hours < endHour;
  }

  /**
   * Get comprehensive timezone information
   */
  static getTimezoneInfo() {
    const businessTime = this.getBusinessTime();
    const serverTime = moment();
    
    return {
      serverTimezone: moment.tz.guess(),
      businessTimezone: BUSINESS_TIMEZONE_NAME,
      serverTime: serverTime.format("YYYY-MM-DD HH:mm:ss"),
      businessTime: businessTime.format("YYYY-MM-DD HH:mm:ss"),
      isSameTimezone: serverTime.tz(BUSINESS_TIMEZONE_NAME).isSame(businessTime),
      timeDifference: businessTime.diff(serverTime, "hours", true),
      isDST: businessTime.isDST(),
      offset: businessTime.format("Z"),
      businessOffset: businessTime.utcOffset() / 60,
    };
  }

  /**
   * Format date for API (UTC)
   */
  static formatDateForAPI(date) {
    return moment.utc(date).format("YYYY-MM-DD");
  }

  /**
   * Format date for display (business timezone)
   */
  static formatDateForDisplay(date) {
    return this.convertUTCToBusiness(date).format("MMM DD, YYYY");
  }

  /**
   * Get day of week name in business timezone
   */
  static getDayOfWeekName(date) {
    const days = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday', 
      'Thursday', 'Friday', 'Saturday'
    ];
    const dayOfWeek = this.convertUTCToBusiness(date).day();
    return days[dayOfWeek];
  }
} 