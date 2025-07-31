import mongoose from "mongoose";

const subscriptionSchema = new mongoose.Schema(
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
    startDate: {
      type: Date,
      required: true,
    },
    endDate: {
      type: Date,
      required: true,
    },
    weeklyDay: {
      type: Number,
      required: true,
      min: 0, // Sunday
      max: 6, // Saturday
    },
    monthlyAmount: {
      type: Number,
      required: true,
      min: 0,
    },
    status: {
      type: String,
      enum: ["active", "expired", "cancelled"],
      default: "active",
    },
    autoRenew: {
      type: Boolean,
      default: true,
    },
    lastBillingDate: {
      type: Date,
      required: true,
    },
    nextBillingDate: {
      type: Date,
      required: true,
    },
    paymentStatus: {
      type: String,
      enum: ["pending", "paid"],
      default: "pending",
    },
    referenceId: {
      type: String,
      unique: true,
    },
    description: {
      type: String,
      default: "Monthly Futsal Subscription",
    },
  },
  { timestamps: true }
);

// Index for efficient queries
subscriptionSchema.index({ clientId: 1, status: 1 });
subscriptionSchema.index({ slotId: 1, weeklyDay: 1, status: 1 });
subscriptionSchema.index({ nextBillingDate: 1 });

const Subscription = mongoose.model("Subscription", subscriptionSchema);
export default Subscription;
