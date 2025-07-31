import Subscription from "../models/subscription.model.js";
import Slot from "../models/slot.model.js";
import Booking from "../models/booking.model.js";
import { initiateWaafiPayment } from "../services/payment.service.js";
import User from "../models/user.model.js";
import { generateOTP } from "../utils/otp.js";
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
} from "../utils/timezone.js";

// Helper function to convert date string to Somalia timezone and then to UTC for storage
const convertToSomaliaThenUTC = (dateString) => {
  // If dateString is already a Date object, convert it to Somalia time then UTC
  if (dateString instanceof Date) {
    return somaliaToUTC(toSomaliaTime(dateString));
  }

  // If it's a string in YYYY-MM-DD format, create Somalia date then convert to UTC
  if (typeof dateString === "string" && dateString.includes("-")) {
    const somaliaDate = toSomaliaTime(dateString);
    return somaliaToUTC(somaliaDate);
  }

  // For other formats, parse and convert to Somalia time then UTC
  const date = new Date(dateString);
  const somaliaDate = toSomaliaTime(date);
  return somaliaToUTC(somaliaDate);
};

// Helper function to get day of week (0-6, Sunday-Saturday)
const getDayOfWeek = (date) => {
  return new Date(date).getDay();
};

// Helper function to get next occurrence of a day of week
const getNextOccurrence = (dayOfWeek, startDate = new Date()) => {
  const currentDay = startDate.getDay();
  const daysUntilNext = (dayOfWeek - currentDay + 7) % 7;
  const nextDate = new Date(startDate);
  nextDate.setDate(startDate.getDate() + daysUntilNext);
  return nextDate;
};

// Helper function to generate dates for a month
const generateMonthlyDates = (startDate, weeklyDay, months = 1) => {
  const dates = [];
  const currentDate = new Date(startDate);

  for (let month = 0; month < months; month++) {
    const monthStart = new Date(
      currentDate.getUTCFullYear(),
      currentDate.getUTCMonth() + month,
      1
    );
    const monthEnd = new Date(
      currentDate.getUTCFullYear(),
      currentDate.getUTCMonth() + month + 1,
      0
    );

    let currentWeekDate = getNextOccurrence(weeklyDay, monthStart);

    while (currentWeekDate <= monthEnd) {
      dates.push(new Date(currentWeekDate));
      currentWeekDate.setDate(currentWeekDate.getDate() + 7);
    }
  }

  return dates;
};

// Helper function to generate all booking dates for a subscription
const generateSubscriptionBookingDates = (startDate, weeklyDay, months = 1) => {
  const dates = [];
  let current = new Date(startDate);
  const endDate = new Date(startDate);
  endDate.setUTCMonth(endDate.getUTCMonth() + months);

  // Move current to the first occurrence of the weeklyDay on or after startDate
  const dayDiff = (weeklyDay - current.getUTCDay() + 7) % 7;
  current.setUTCDate(current.getUTCDate() + dayDiff);

  // Generate all dates until endDate (exclusive)
  while (current < endDate) {
    dates.push(new Date(current));
    current.setUTCDate(current.getUTCDate() + 7);
  }
  return dates;
};

// Client routes
export const createSubscription = async (req, res, next) => {
  try {
    const { slotId, startDate, weeklyDay, months = 1 } = req.body;
    const clientId = req.user._id;

    // Check if slot exists
    const slot = await Slot.findById(slotId);
    if (!slot) {
      const error = new Error("Slot not found");
      error.statusCode = 404;
      throw error;
    }

    // Validate weekly day
    if (weeklyDay < 0 || weeklyDay > 6) {
      const error = new Error("Invalid day of week (0-6, Sunday-Saturday)");
      error.statusCode = 400;
      throw error;
    }

    // Validate start date and convert to Somalia timezone then UTC
    const startDateTime = convertToSomaliaThenUTC(startDate);
    if (!isValidBookingDateInSomalia(startDate)) {
      const error = new Error("Start date cannot be in the past");
      error.statusCode = 400;
      throw error;
    }

    // Check for existing active subscription for this slot and day
    const existingSubscription = await Subscription.findOne({
      slotId,
      weeklyDay,
      status: "active",
      $or: [
        { clientId },
        {
          $and: [
            { startDate: { $lte: startDateTime } },
            { endDate: { $gte: startDateTime } },
          ],
        },
      ],
    });

    if (existingSubscription) {
      const error = new Error(
        "This slot is already subscribed for this day of the week"
      );
      error.statusCode = 400;
      throw error;
    }

    // Calculate subscription details
    const endDate = new Date(startDateTime);
    endDate.setUTCMonth(endDate.getUTCMonth() + months);

    // Generate all booking dates for the subscription
    const bookingDates = generateSubscriptionBookingDates(
      startDateTime,
      weeklyDay,
      months
    );
    const monthlyAmount = slot.price * bookingDates.length; // Accurate billing
    const totalAmount = monthlyAmount; // For now, 1 month = total, can adjust for multi-month

    // Create subscription with pending payment
    const subscription = await Subscription.create({
      clientId,
      slotId,
      startDate: startDateTime,
      endDate,
      weeklyDay,
      monthlyAmount,
      lastBillingDate: new Date(),
      nextBillingDate: new Date(startDateTime),
      paymentStatus: "pending",
    });

    try {
      const paymentResult = await initiateWaafiPayment(
        req.user.phone,
        totalAmount,
        subscription._id.toString()
      );

      if (!paymentResult.success) {
        await Subscription.findByIdAndDelete(subscription._id);
        const error = new Error(paymentResult.data.responseMsg);
        error.statusCode = 400;
        throw error;
      }

      // Update subscription with payment reference
      subscription.referenceId = paymentResult.referenceId;
      subscription.paymentStatus = "paid";
      await subscription.save();

      // Create individual bookings for the subscription period
      for (const date of bookingDates) {
        const otp = generateOTP();
        await Booking.create({
          clientId,
          slotId,
          date,
          amount: slot.price,
          paymentStatus: "paid",
          referenceId: `${subscription.referenceId}-${
            date.toISOString().split("T")[0]
          }`,
          isSubscriptionBooking: true,
          subscriptionId: subscription._id,
          otp,
        });
      }

      res.status(201).json({
        success: true,
        message:
          "Monthly subscription created and payment completed successfully",
        data: {
          subscription,
          payment: {
            referenceId: paymentResult.referenceId,
            status: "success",
            totalAmount,
            monthlyAmount,
            months,
          },
          bookingsCreated: bookingDates.length,
        },
      });
    } catch (paymentError) {
      await Subscription.findByIdAndDelete(subscription._id);
      const error = new Error(`Payment failed: ${paymentError.message}`);
      error.statusCode = 400;
      throw error;
    }
  } catch (error) {
    next(error);
  }
};

export const getClientSubscriptions = async (req, res, next) => {
  try {
    const { status } = req.query;
    const query = { clientId: req.user._id };

    if (status && ["active", "expired", "cancelled"].includes(status)) {
      query.status = status;
    }

    const subscriptions = await Subscription.find(query)
      .populate("slotId", "startTime endTime price")
      .sort({ createdAt: -1 })
      .lean();

    res.status(200).json({
      success: true,
      message: "Subscriptions retrieved successfully",
      data: subscriptions,
    });
  } catch (error) {
    next(error);
  }
};

export const cancelSubscription = async (req, res, next) => {
  try {
    const { subscriptionId } = req.params;
    const clientId = req.user._id;

    const subscription = await Subscription.findOne({
      _id: subscriptionId,
      clientId,
      status: "active",
    });

    if (!subscription) {
      const error = new Error("Subscription not found or not active");
      error.statusCode = 404;
      throw error;
    }

    subscription.status = "cancelled";
    subscription.autoRenew = false;
    await subscription.save();

    res.status(200).json({
      success: true,
      message: "Subscription cancelled successfully",
      data: subscription,
    });
  } catch (error) {
    next(error);
  }
};

// Manager routes
export const getAllSubscriptions = async (req, res, next) => {
  try {
    const { status, search } = req.query;
    let query = {};

    if (status && ["active", "expired", "cancelled"].includes(status)) {
      query.status = status;
    }

    let subscriptions = await Subscription.find(query)
      .populate("clientId", "name phone")
      .populate("slotId", "startTime endTime price")
      .sort({ createdAt: -1 })
      .lean();

    // Apply search filter
    if (search) {
      const lowerCaseSearch = search.toLowerCase();
      subscriptions = subscriptions.filter(
        (subscription) =>
          subscription.clientId?.name.toLowerCase().includes(lowerCaseSearch) ||
          subscription.clientId?.phone.includes(search)
      );
    }

    res.status(200).json({
      success: true,
      message: "Subscriptions retrieved successfully",
      data: subscriptions,
    });
  } catch (error) {
    next(error);
  }
};

export const createSubscriptionByManager = async (req, res, next) => {
  try {
    const { clientId, slotId, startDate, weeklyDay, months = 1 } = req.body;

    // Check if slot exists
    const slot = await Slot.findById(slotId);
    if (!slot) {
      const error = new Error("Slot not found");
      error.statusCode = 404;
      throw error;
    }

    // Check if client exists
    const client = await User.findById(clientId);
    if (!client) {
      const error = new Error("Client not found");
      error.statusCode = 404;
      throw error;
    }

    // Validate weekly day
    if (weeklyDay < 0 || weeklyDay > 6) {
      const error = new Error("Invalid day of week (0-6, Sunday-Saturday)");
      error.statusCode = 400;
      throw error;
    }

    // Validate start date and convert to Somalia timezone then UTC
    const startDateTime = convertToSomaliaThenUTC(startDate);
    if (!isValidBookingDateInSomalia(startDate)) {
      const error = new Error("Start date cannot be in the past");
      error.statusCode = 400;
      throw error;
    }

    // Check for existing active subscription
    const existingSubscription = await Subscription.findOne({
      slotId,
      weeklyDay,
      status: "active",
      $or: [
        { clientId },
        {
          $and: [
            { startDate: { $lte: startDateTime } },
            { endDate: { $gte: startDateTime } },
          ],
        },
      ],
    });

    if (existingSubscription) {
      const error = new Error(
        "This slot is already subscribed for this day of the week"
      );
      error.statusCode = 400;
      throw error;
    }

    // Calculate subscription details
    const endDate = new Date(startDateTime);
    endDate.setUTCMonth(endDate.getUTCMonth() + months);

    // Generate all booking dates for the subscription
    const bookingDates = generateSubscriptionBookingDates(
      startDateTime,
      weeklyDay,
      months
    );
    const monthlyAmount = slot.price * bookingDates.length; // Accurate billing

    // Create subscription
    const subscription = await Subscription.create({
      clientId,
      slotId,
      startDate: startDateTime,
      endDate,
      weeklyDay,
      monthlyAmount,
      lastBillingDate: new Date(),
      nextBillingDate: new Date(startDateTime),
      paymentStatus: "paid",
      referenceId: `MGR-SUB-${getSomaliaTimestamp()}`,
    });

    // Create individual bookings for the subscription period
    for (const date of bookingDates) {
      const otp = generateOTP();
      await Booking.create({
        clientId,
        slotId,
        date,
        amount: slot.price,
        paymentStatus: "paid",
        referenceId: `${subscription.referenceId}-${
          date.toISOString().split("T")[0]
        }`,
        isSubscriptionBooking: true,
        subscriptionId: subscription._id,
        otp,
      });
    }

    res.status(201).json({
      success: true,
      message: "Monthly subscription created successfully",
      data: {
        subscription,
        bookingsCreated: bookingDates.length,
      },
    });
  } catch (error) {
    next(error);
  }
};

export const updateSubscription = async (req, res, next) => {
  try {
    const { id } = req.params;
    const subscription = await Subscription.findByIdAndUpdate(id, req.body, {
      new: true,
      runValidators: true,
    });

    if (!subscription) {
      const error = new Error("Subscription not found");
      error.statusCode = 404;
      throw error;
    }

    res.status(200).json({
      success: true,
      message: "Subscription updated successfully",
      data: subscription,
    });
  } catch (error) {
    next(error);
  }
};

export const deleteSubscription = async (req, res, next) => {
  try {
    const subscription = await Subscription.findByIdAndDelete(req.params.id);

    if (!subscription) {
      const error = new Error("Subscription not found");
      error.statusCode = 404;
      throw error;
    }

    // Delete associated bookings
    await Booking.deleteMany({ subscriptionId: subscription._id });

    res.status(200).json({
      success: true,
      message: "Subscription deleted successfully",
    });
  } catch (error) {
    next(error);
  }
};
