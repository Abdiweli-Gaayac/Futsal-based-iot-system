import Slot from "../models/slot.model.js";
import Booking from "../models/booking.model.js";

// Helper function to validate time format and convert to minutes
function timeToMinutes(time) {
  const [hours, minutes] = time.split(":").map(Number);
  return hours * 60 + minutes;
}

// Helper function to check for time overlap
function doTimesOverlap(start1, end1, start2, end2) {
  const start1Mins = timeToMinutes(start1);
  const end1Mins = timeToMinutes(end1);
  const start2Mins = timeToMinutes(start2);
  const end2Mins = timeToMinutes(end2);

  return start1Mins < end2Mins && end1Mins > start2Mins;
}

// Helper function to validate slot times
function validateSlotTimes(startTime, endTime) {
  const startMinutes = timeToMinutes(startTime);
  const endMinutes = timeToMinutes(endTime);

  // // Minimum duration 30 minutes, maximum 180 minutes (3 hours)
  // const duration = endMinutes - startMinutes;
  // if (duration < 30) {
  //   throw new Error("Slot duration must be at least 30 minutes");
  // }
  // if (duration > 180) {
  //   throw new Error("Slot duration cannot exceed 3 hours");
  // }

  return true;
}

// Public routes
export const getPublicSlots = async (req, res, next) => {
  try {
    const { date } = req.query;
    const slots = await Slot.find().sort({ startTime: 1 });

    // If date is provided, check booking status for each slot
    if (date) {
      const selectedDate = new Date(date);
      selectedDate.setUTCHours(0, 0, 0, 0); // Use UTC for consistent date boundaries

      // Get all bookings for the selected date
      const bookings = await Booking.find({
        date: {
          $gte: selectedDate,
          $lt: new Date(selectedDate.getTime() + 24 * 60 * 60 * 1000),
        },
      }).populate("clientId", "name");

      // Create a map of slotId to booking info
      const bookingMap = new Map();
      bookings.forEach((booking) => {
        bookingMap.set(booking.slotId.toString(), {
          isBooked: true,
          bookedBy: booking.clientId?.name || "Unknown",
          paymentStatus: booking.paymentStatus,
          isSubscriptionBooking: booking.isSubscriptionBooking,
        });
      });

      // Add booking status to each slot
      const slotsWithBookingStatus = slots.map((slot) => {
        const bookingInfo = bookingMap.get(slot._id.toString());
        return {
          ...slot.toObject(),
          isBooked: bookingInfo ? bookingInfo.isBooked : false,
          bookedBy: bookingInfo ? bookingInfo.bookedBy : null,
          paymentStatus: bookingInfo ? bookingInfo.paymentStatus : null,
          isSubscriptionBooking: bookingInfo
            ? bookingInfo.isSubscriptionBooking
            : false,
        };
      });

      res.status(200).json({ success: true, data: slotsWithBookingStatus });
    } else {
      res.status(200).json({ success: true, data: slots });
    }
  } catch (error) {
    next(error);
  }
};

// Manager routes
export const getAllSlots = async (req, res, next) => {
  try {
    const slots = await Slot.find().sort({ startTime: 1 });
    res.status(200).json({ success: true, data: slots });
  } catch (error) {
    next(error);
  }
};

export const createSlot = async (req, res, next) => {
  try {
    const { startTime, endTime, price } = req.body;

    // Validate time format
    if (
      !/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/.test(startTime) ||
      !/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/.test(endTime)
    ) {
      const error = new Error(
        "Invalid time format. Use HH:MM in 24-hour format"
      );
      error.statusCode = 400;
      throw error;
    }

    // Validate price
    if (
      isNaN(price) ||
      price < 0 ||
      !/^\d+(\.\d{1,2})?$/.test(price.toString())
    ) {
      const error = new Error(
        "Invalid price. Must be a positive number with up to 2 decimal places"
      );
      error.statusCode = 400;
      throw error;
    }

    // Validate slot duration
    validateSlotTimes(startTime, endTime);

    // Check for overlapping slots
    const existingSlots = await Slot.find();
    const hasOverlap = existingSlots.some((slot) =>
      doTimesOverlap(startTime, endTime, slot.startTime, slot.endTime)
    );

    if (hasOverlap) {
      const error = new Error("This slot overlaps with an existing slot");
      error.statusCode = 409;
      throw error;
    }

    const slot = await Slot.create({ startTime, endTime, price });
    res.status(201).json({
      success: true,
      message: "Slot created successfully",
      data: slot,
    });
  } catch (error) {
    if (error.code === 11000) {
      // Duplicate key error
      error.statusCode = 409;
      error.message = "A slot with these exact times already exists";
    }
    next(error);
  }
};

export const updateSlot = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { startTime, endTime, price } = req.body;

    // Validate time format if provided
    if (startTime && endTime) {
      if (
        !/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/.test(startTime) ||
        !/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/.test(endTime)
      ) {
        const error = new Error(
          "Invalid time format. Use HH:MM in 24-hour format"
        );
        error.statusCode = 400;
        throw error;
      }

      // Validate slot duration
      validateSlotTimes(startTime, endTime);

      // Check for overlapping slots
      const existingSlots = await Slot.find({ _id: { $ne: id } });
      const hasOverlap = existingSlots.some((slot) =>
        doTimesOverlap(startTime, endTime, slot.startTime, slot.endTime)
      );

      if (hasOverlap) {
        const error = new Error(
          "This slot would overlap with an existing slot"
        );
        error.statusCode = 409;
        throw error;
      }
    }

    // Validate price if provided
    if (price !== undefined) {
      if (
        isNaN(price) ||
        price < 0 ||
        !/^\d+(\.\d{1,2})?$/.test(price.toString())
      ) {
        const error = new Error(
          "Invalid price. Must be a positive number with up to 2 decimal places"
        );
        error.statusCode = 400;
        throw error;
      }
    }

    // Check if slot has any future bookings before updating times
    if (startTime || endTime) {
      const hasBookings = await Booking.exists({
        slotId: id,
        date: { $gte: new Date() },
      });

      if (hasBookings) {
        const error = new Error(
          "Cannot modify slot times with existing future bookings"
        );
        error.statusCode = 400;
        throw error;
      }
    }

    const slot = await Slot.findByIdAndUpdate(id, req.body, {
      new: true,
      runValidators: true,
    });

    if (!slot) {
      const error = new Error("Slot not found");
      error.statusCode = 404;
      throw error;
    }

    res.status(200).json({
      success: true,
      message: "Slot updated successfully",
      data: slot,
    });
  } catch (error) {
    if (error.code === 11000) {
      error.statusCode = 409;
      error.message = "A slot with these exact times already exists";
    }
    next(error);
  }
};

export const deleteSlot = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Check if slot has any bookings
    const hasBookings = await Booking.exists({ slotId: id });
    if (hasBookings) {
      const error = new Error("Cannot delete slot with existing bookings");
      error.statusCode = 400;
      throw error;
    }

    const slot = await Slot.findByIdAndDelete(id);
    if (!slot) {
      const error = new Error("Slot not found");
      error.statusCode = 404;
      throw error;
    }

    res.status(200).json({
      success: true,
      message: "Slot deleted successfully",
    });
  } catch (error) {
    next(error);
  }
};
