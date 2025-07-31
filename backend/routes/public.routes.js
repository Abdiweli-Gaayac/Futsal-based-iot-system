import express from "express";
import { getPublicSlots } from "../controllers/slot.controller.js";
import {
  createBooking,
  getClientBookings,
  verifyBookingOTP,
  testTimezone,
} from "../controllers/booking.controller.js";
import { isAuthenticated } from "../middlewares/auth.middleware.js";

const router = express.Router();

// Public routes
router.get("/slots", getPublicSlots);

// Protected client routes
router
  .route("/my-bookings")
  .get(isAuthenticated, getClientBookings)
  .post(isAuthenticated, createBooking);
router.post("/verify-otp", verifyBookingOTP);
router.get("/test-timezone", testTimezone);

export default router;
