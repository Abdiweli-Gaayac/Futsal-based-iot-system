import Booking from "../models/booking.model.js";
import Slot from "../models/slot.model.js";
import { initiateWaafiPayment } from "../services/payment.service.js";
import { generateOTP } from "../utils/otp.js";
import User from "../models/user.model.js";

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

    // Check if slot is already booked for this date
    const existingBooking = await Booking.findOne({ slotId, date });
    if (existingBooking) {
      const error = new Error("Slot is already booked for this date");
      error.statusCode = 400;
      throw error;
    }

    if (!isValidBookingDate(date)) {
      const error = new Error("Cannot book slots for past dates");
      error.statusCode = 400;
      throw error;
    }

    // Create booking with pending payment status
    const booking = await Booking.create({
      clientId,
      slotId,
      date,
      amount: slot.price,
      paymentStatus: "pending",
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
    today.setHours(0, 0, 0, 0);

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

export const verifyBookingOTP = async (req, res, next) => {
  try {
    const { otp } = req.body;
    const now = new Date();
    const currentTime = now.toTimeString().split(" ")[0].slice(0, 5); // HH:MM
    const today = now.toISOString().split("T")[0]; // YYYY-MM-DD format

    console.log("🕒 Verification Request:");
    console.log("- OTP:", otp);
    console.log("- Current Time:", currentTime);
    console.log("- Today:", today);

    // First check if OTP exists and get booking
    const booking = await Booking.findOne({ otp }).populate("slotId");

    if (!booking) {
      console.log("❌ Error: Invalid OTP");
      const error = new Error("Invalid OTP");
      error.statusCode = 400;
      error.code = 1; // Add error code
      throw error;
    }

    const bookingDate = booking.date.toISOString().split("T")[0];

    // Calculate slot duration in minutes
    const startMinutes = timeToMinutes(booking.slotId.startTime);
    const endMinutes = timeToMinutes(booking.slotId.endTime);
    const slotDuration = endMinutes - startMinutes;

    // Calculate remaining duration
    const currentMinutes = timeToMinutes(currentTime);
    const remainingMinutes = endMinutes - currentMinutes;
    console.log("\n📅 Booking Details:");
    console.log("- Booking Date:", bookingDate);
    console.log(
      "- Slot Time:",
      `${booking.slotId.startTime}-${booking.slotId.endTime} (${slotDuration} minutes)`
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

    // Check if booking is for today
    if (bookingDate !== today) {
      console.log("❌ Error: Date mismatch");
      console.log("- Booking Date:", bookingDate);
      console.log("- Today:", today);
      const error = new Error(
        `Access denied. Your booking is for ${bookingDate}, not today (${today})`
      );
      error.statusCode = 400;
      error.code = 4; // Add error code
      throw error;
    }

    // Check time slot with 5-minute window
    const slotStartTime = booking.slotId.startTime;
    const slotEndTime = booking.slotId.endTime;
    const earlyWindow = subtractMinutes(slotStartTime, 5); // 5 minutes before start
    const lateWindow = subtractMinutes(slotEndTime, 5); // 5 minutes before end

    console.log("\n⏰ Time Comparison:");
    console.log("- Current Time:", currentTime);
    console.log("- Valid Window:", `${earlyWindow}-${lateWindow}`);
    console.log("- Original Slot:", `${slotStartTime}-${slotEndTime}`);

    if (currentTime < earlyWindow || currentTime > lateWindow) {
      console.log("❌ Error: Outside time window");
      const error = new Error(
        `Access denied. Your slot is ${slotStartTime}-${slotEndTime}. ` +
          `You can enter between ${earlyWindow}-${lateWindow} only`
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

      // Send detailed response on first access
      res.status(200).json({
        success: true,
        code: 6, // Success code for first access
        message: "Access granted. Gate will open now.",
        data: {
          slotTime: `${slotStartTime}-${slotEndTime}`,
          duration: remainingMinutes > 0 ? remainingMinutes : 0,
          fullDuration: slotDuration,
          clientId: booking.clientId,
          validWindow: `${earlyWindow}-${lateWindow}`,
          date: today,
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

// Helper functions to handle time calculations
function addMinutes(time, minutes) {
  const [hours, mins] = time.split(":").map(Number);
  const date = new Date();
  date.setHours(hours, mins + minutes);
  return date.toTimeString().split(" ")[0].slice(0, 5);
}

function subtractMinutes(time, minutes) {
  const [hours, mins] = time.split(":").map(Number);
  const date = new Date();
  date.setHours(hours, mins - minutes);
  return date.toTimeString().split(" ")[0].slice(0, 5);
}

// Add helper function to convert time to minutes
function timeToMinutes(time) {
  const [hours, minutes] = time.split(":").map(Number);
  return hours * 60 + minutes;
}

// Manager routes
export const getAllBookings = async (req, res, next) => {
  try {
    const { date, search } = req.query;
    const query = date ? { date: new Date(date) } : {};

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

    // Check if slot is already booked for this date
    const existingBooking = await Booking.findOne({ slotId, date });
    if (existingBooking) {
      const error = new Error("Slot is already booked for this date");
      error.statusCode = 400;
      throw error;
    }

    if (!isValidBookingDate(date)) {
      const error = new Error("Cannot book slots for past dates");
      error.statusCode = 400;
      throw error;
    }

    const otp = generateOTP();
    const booking = await Booking.create({
      clientId,
      slotId,
      date,
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
  today.setHours(0, 0, 0, 0);
  return bookingDate >= today;
};
