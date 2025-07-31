import Booking from "../models/booking.model.js";
import Slot from "../models/slot.model.js";
import { initiateWaafiPayment } from "../services/payment.service.js";
import { generateOTP } from "../utils/otp.js";
import User from "../models/user.model.js";
import { 
  getSomaliTime, 
  getSomaliTimeString, 
  getSomaliDateString, 
  getTimezoneInfo 
} from "../utils/timezone.js";
import { EnhancedTimezone } from "../utils/enhanced_timezone.js";

// Helper function to convert date string to UTC Date object
const convertToUTCDate = (dateString) => {
  // If dateString is already a Date object, return it
  if (dateString instanceof Date) {
    return dateString;
  }

  // If it's a string in YYYY-MM-DD format, create UTC date
  if (typeof dateString === "string" && dateString.includes("-")) {
    const [year, month, day] = dateString.split("-").map(Number);
    // Create UTC date (midnight UTC)
    return new Date(Date.UTC(year, month - 1, day));
  }

  // For other formats, parse and convert to UTC
  const date = new Date(dateString);
  return new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate())
  );
};

// Helper function to format date for display (YYYY-MM-DD)
const formatDateForDisplay = (date) => {
  const utcDate = new Date(date);
  return utcDate.toISOString().split("T")[0];
};

// Client routes
export const createBooking = async (req, res, next) => {
  try {
    const { slotId, date } = req.body;
    const clientId = req.user._id;

    // Check if slot exists
    const slot = await Slot.findById(slotId);
    if (!slot) {
      const error = new Error("Slot not found");
      error.statusCode = 404;
      throw error;
    }

    // Convert date to UTC
    const utcDate = convertToUTCDate(date);

    // Check if slot is already booked for this date
    const existingBooking = await Booking.findOne({ slotId, date: utcDate });
    if (existingBooking) {
      const error = new Error("Slot is already booked for this date");
      error.statusCode = 400;
      throw error;
    }

    if (!isValidBookingDate(utcDate)) {
      const error = new Error("Cannot book slots for past dates");
      error.statusCode = 400;
      throw error;
    }

    // Create booking with pending payment status
    const otp = generateOTP();
    const booking = await Booking.create({
      clientId,
      slotId,
      date: utcDate, // Store in UTC
      amount: slot.price,
      paymentStatus: "pending",
      otp,
    });

    try {
      const paymentResult = await initiateWaafiPayment(
        req.user.phone,
        slot.price,
        booking._id.toString()
      );

      if (!paymentResult.success) {
        // Delete the booking if payment failed
        await Booking.findByIdAndDelete(booking._id);
        const error = new Error(paymentResult.data.responseMsg);
        error.statusCode = 400;
        throw error;
      }

      // Update booking with payment reference
      booking.referenceId = paymentResult.referenceId;
      booking.paymentStatus = "paid";
      await booking.save();

      res.status(201).json({
        success: true,
        message: "Booking created and payment completed successfully",
        data: {
          booking,
          payment: {
            referenceId: paymentResult.referenceId,
            status: "success",
            transactionId: paymentResult.data.params?.orderId,
          },
          otp: otp, // Include OTP in response for access
        },
      });
    } catch (paymentError) {
      // Delete the booking if payment failed
      await Booking.findByIdAndDelete(booking._id);
      const error = new Error(`Payment failed: ${paymentError.message}`);
      error.statusCode = 400;
      throw error;
    }
  } catch (error) {
    next(error);
  }
};

export const getClientBookings = async (req, res, next) => {
  try {
    const { status } = req.query;
    const today = new Date();
    today.setUTCHours(0, 0, 0, 0); // Use UTC midnight

    let query = {
      clientId: req.user._id,
    };

    // Only filter by date if specifically requesting upcoming or past
    if (status === "upcoming") {
      query.date = { $gte: today };
    } else if (status === "past") {
      query.date = { $lt: today };
    }

    // Add payment status filter if provided
    if (status === "paid" || status === "pending") {
      query.paymentStatus = status;
    }

    const bookings = await Booking.find(query)
      .populate("slotId", "startTime endTime price") // Populate slot details
      .sort({ date: -1, "slotId.startTime": 1 })
      .lean();

    res.status(200).json({
      success: true,
      message: "Bookings retrieved successfully",
      data: bookings,
    });
  } catch (error) {
    next(error);
  }
};

// Helper function to convert time to minutes
function timeToMinutes(time) {
  const [hours, minutes] = time.split(":").map(Number);
  return hours * 60 + minutes;
}

// Helper function to subtract minutes from time
function subtractMinutes(time, mins) {
  const totalMinutes = timeToMinutes(time) - mins;
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  return `${hours.toString().padStart(2, "0")}:${minutes
    .toString()
    .padStart(2, "0")}`;
}

export const verifyBookingOTP = async (req, res, next) => {
  try {
    const { otp } = req.body;
    
    // Get Somali time instead of server time
    const somaliTime = getSomaliTime();
    const currentTime = getSomaliTimeString(); // HH:MM in Somali timezone
    const today = getSomaliDateString(); // YYYY-MM-DD in Somali timezone

    console.log("🕒 Verification Request (Somali Timezone):");
    console.log("- OTP:", otp);
    console.log("- Current Somali Time:", currentTime);
    console.log("- Today (Somali):", today);
    
    // Log timezone information for debugging
    const timezoneInfo = getTimezoneInfo();
    console.log("- Timezone Info:", timezoneInfo);

    // First check if OTP exists and get booking
    const booking = await Booking.findOne({ otp }).populate("slotId");

    if (!booking) {
      console.log("❌ Error: Invalid OTP");
      const error = new Error("Invalid OTP");
      error.statusCode = 400;
      error.code = 1; // Add error code
      throw error;
    }

    const bookingDate = formatDateForDisplay(booking.date);

    // Get time values
    const slotStartTime = booking.slotId.startTime;
    const slotEndTime = booking.slotId.endTime;

    // Calculate slot duration and remaining time in minutes
    const startMinutes = timeToMinutes(slotStartTime);
    const endMinutes = timeToMinutes(slotEndTime);
    const currentMinutes = timeToMinutes(currentTime);

    const slotDuration = endMinutes - startMinutes;
    const remainingMinutes = endMinutes - currentMinutes;

    console.log("\n📅 Booking Details:");
    console.log("- Booking Date:", bookingDate);
    console.log(
      "- Slot Time:",
      `${slotStartTime}-${slotEndTime} (${slotDuration} minutes)`
    );
    console.log("- Remaining Time:", `${remainingMinutes} minutes`);
    console.log("- Payment Status:", booking.paymentStatus);
    console.log("- Is Used:", booking.isUsed);

    // Check payment status
    if (booking.paymentStatus !== "paid") {
      console.log("❌ Error: Unpaid booking");
      const error = new Error("Booking is not paid yet");
      error.statusCode = 400;
      error.code = 3; // Add error code
      throw error;
    }

    // Check if booking is for today (using Somali timezone)
    if (bookingDate !== today) {
      console.log("❌ Error: Date mismatch");
      console.log("- Booking Date:", bookingDate);
      console.log("- Today (Somali):", today);
      const error = new Error(
        `Access denied. Your booking is for ${bookingDate}, not today (${today}) in Somali timezone`
      );
      error.statusCode = 400;
      error.code = 4; // Add error code
      throw error;
    }

    // Check if current time is within the slot time (no early access) - using Somali timezone
    console.log("\n⏰ Time Comparison (Somali Timezone):");
    console.log("- Current Somali Time:", currentTime);
    console.log("- Slot Time:", `${slotStartTime}-${slotEndTime}`);

    // Use enhanced time comparison
    const timeComparison = EnhancedTimezone.compareTimeStrings(currentTime, slotStartTime);
    const endTimeComparison = EnhancedTimezone.compareTimeStrings(currentTime, slotEndTime);

    if (timeComparison < 0 || endTimeComparison >= 0) {
      console.log("❌ Error: Outside time window");
      const error = new Error(
        `Access denied. Your slot is ${slotStartTime}-${slotEndTime}. ` +
          `You can only enter during your exact slot time (Somali timezone).`
      );
      error.statusCode = 400;
      error.code = 5; // Add error code
      throw error;
    }

    // All checks passed, grant access
    console.log("\n✅ Access Granted!");

    // Determine if this is the first access
    const isFirstAccess = !booking.isUsed;

    // Mark booking as used on first access
    if (isFirstAccess) {
      booking.isUsed = true;
      await booking.save();
      console.log("- OTP marked as used (first access)");

      // Send detailed response on first access with correct remaining time
      res.status(200).json({
        success: true,
        code: 6, // Success code for first access
        message: "Access granted. Gate will open now.",
        data: {
          slotTime: `${slotStartTime}-${slotEndTime}`,
          duration: remainingMinutes > 0 ? remainingMinutes : 0,
          fullDuration: slotDuration,
          clientId: booking.clientId,
          date: today,
          timezone: "Africa/Mogadishu", // Include timezone info
          currentTime: currentTime,
        },
      });
    } else {
      // Send a simpler response on subsequent accesses
      res.status(200).json({
        success: true,
        code: 7, // Different success code for subsequent access
        message: "Access granted. Gate will open now.",
      });
    }
  } catch (error) {
    console.log("\n❌ Final Error:", error.message);
    // Pass the error code if it exists
    res.status(error.statusCode || 500).json({
      success: false,
      code: error.code || 0, // Use error code or default to 0
      message: error.message,
    });
  }
};

// Manager routes
export const getAllBookings = async (req, res, next) => {
  try {
    const { date, search } = req.query;
    const query = date ? { date: convertToUTCDate(date) } : {};

    let bookings = await Booking.find(query)
      .populate("clientId", "name phone")
      .populate("slotId")
      .sort("date startTime");
    // Apply search filter for client name or phone
    if (search) {
      const lowerCaseSearch = search.toLowerCase();
      bookings = bookings.filter(
        (booking) =>
          booking.clientId?.name.toLowerCase().includes(lowerCaseSearch) ||
          booking.clientId?.phone.includes(search)
      );
    }
    res.status(200).json({ success: true, data: bookings });
  } catch (error) {
    next(error);
  }
};

export const createBookingByManager = async (req, res, next) => {
  try {
    const { clientId, slotId, date } = req.body;

    // Check if slot exists
    const slot = await Slot.findById(slotId);
    if (!slot) {
      const error = new Error("Slot not found");
      error.statusCode = 404;
      throw error;
    }
    //check if client exists
    const client = await User.findById(clientId);
    if (!client) {
      const error = new Error("Client not found");
      error.statusCode = 404;
      throw error;
    }

    // Convert date to UTC
    const utcDate = convertToUTCDate(date);

    // Check if slot is already booked for this date
    const existingBooking = await Booking.findOne({ slotId, date: utcDate });
    if (existingBooking) {
      const error = new Error("Slot is already booked for this date");
      error.statusCode = 400;
      throw error;
    }

    if (!isValidBookingDate(utcDate)) {
      const error = new Error("Cannot book slots for past dates");
      error.statusCode = 400;
      throw error;
    }

    const otp = generateOTP();
    const booking = await Booking.create({
      clientId,
      slotId,
      date: utcDate, // Store in UTC
      amount: slot.price,
      paymentStatus: "paid",
      otp,
      referenceId: `MGR-${Date.now()}`,
    });

    res.status(201).json({
      success: true,
      data: booking,
      message: `Booking created successfully. OTP: ${otp}`,
    });
  } catch (error) {
    next(error);
  }
};

export const updateBooking = async (req, res, next) => {
  try {
    const booking = await Booking.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });

    if (!booking) {
      const error = new Error("Booking not found");
      error.statusCode = 404;
      throw error;
    }

    res.status(200).json({
      success: true,
      data: booking,
    });
  } catch (error) {
    next(error);
  }
};

export const deleteBooking = async (req, res, next) => {
  try {
    const booking = await Booking.findByIdAndDelete(req.params.id);

    if (!booking) {
      const error = new Error("Booking not found");
      error.statusCode = 404;
      throw error;
    }

    // Free up the slot
    await Slot.findByIdAndUpdate(booking.slotId, { isBooked: false });

    res.status(200).json({
      success: true,
      message: "Booking deleted successfully",
    });
  } catch (error) {
    next(error);
  }
};

// Add this helper function
const isValidBookingDate = (date) => {
  const bookingDate = new Date(date);
  const today = new Date();
  today.setUTCHours(0, 0, 0, 0); // Use UTC midnight
  return bookingDate >= today;
};

// Test endpoint for timezone debugging
export const testTimezone = async (req, res, next) => {
  try {
    const timezoneInfo = getTimezoneInfo();
    
    res.status(200).json({
      success: true,
      message: "Timezone test endpoint",
      data: {
        ...timezoneInfo,
        testCases: {
          currentSomaliTime: getSomaliTimeString(),
          currentSomaliDate: getSomaliDateString(),
          serverTime: new Date().toISOString(),
          serverTimeString: new Date().toTimeString(),
        }
      }
    });
  } catch (error) {
    next(error);
  }
};
