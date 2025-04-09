import mongoose from "mongoose";

const slotSchema = new mongoose.Schema(
  {
    startTime: {
      type: String,
      required: [true, "Start time is required"],
      validate: {
        validator: function (v) {
          // Validate time format (HH:MM)
          return /^([01]?[0-9]|2[0-3]):[0-5][0-9]$/.test(v);
        },
        message: "Start time must be in 24-hour format (HH:MM)",
      },
    },
    endTime: {
      type: String,
      required: [true, "End time is required"],
      validate: {
        validator: function (v) {
          // Validate time format (HH:MM)
          return /^([01]?[0-9]|2[0-3]):[0-5][0-9]$/.test(v);
        },
        message: "End time must be in 24-hour format (HH:MM)",
      },
    },
    price: {
      type: Number,
      required: [true, "Price is required"],
      min: [0, "Price cannot be negative"],
      validate: {
        validator: function (v) {
          // Ensure price has at most 2 decimal places
          return /^\d+(\.\d{1,2})?$/.test(v.toString());
        },
        message: "Price can only have up to 2 decimal places",
      },
    },
  },
  { timestamps: true }
);

// Prevent duplicate slots with same time
slotSchema.index({ startTime: 1, endTime: 1 }, { unique: true });

// Add custom validation methods
slotSchema.methods.validateTimeOrder = function () {
  const startMinutes = timeToMinutes(this.startTime);
  const endMinutes = timeToMinutes(this.endTime);
  return endMinutes > startMinutes;
};

// Add pre-save middleware for validation
slotSchema.pre("save", function (next) {
  if (!this.validateTimeOrder()) {
    next(new Error("End time must be after start time"));
  }
  next();
});

// Helper function to convert time to minutes
function timeToMinutes(time) {
  const [hours, minutes] = time.split(":").map(Number);
  return hours * 60 + minutes;
}

const Slot = mongoose.model("Slot", slotSchema);
export default Slot;
