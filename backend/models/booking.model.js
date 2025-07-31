import mongoose from "mongoose";

const bookingSchema = new mongoose.Schema(
  {
    clientId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    slotId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Slot",
      required: true,
    },
    date: {
      type: Date,
      required: true,
    },
    amount: {
      type: Number,
      required: true,
    },
    paymentStatus: {
      type: String,
      enum: ["pending", "paid"],
      default: "pending",
    },
    otp: {
      type: String,
    },
    isUsed: {
      type: Boolean,
      default: false,
    },
    referenceId: {
      type: String,
      unique: true,
    },
    // New fields for subscription support
    isSubscriptionBooking: {
      type: Boolean,
      default: false,
    },
    subscriptionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Subscription",
    },
  },
  { timestamps: true }
);

// Compound index to prevent double booking
bookingSchema.index({ slotId: 1, date: 1 }, { unique: true });

const Booking = mongoose.model("Booking", bookingSchema);
export default Booking;
