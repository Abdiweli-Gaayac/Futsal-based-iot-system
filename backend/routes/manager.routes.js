import express from "express";
import { isAuthenticated, isManager } from "../middlewares/auth.middleware.js";
import {
  getAllSlots,
  createSlot,
  updateSlot,
  deleteSlot,
} from "../controllers/slot.controller.js";
import {
  getAllBookings,
  createBookingByManager,
  updateBooking,
  deleteBooking,
} from "../controllers/booking.controller.js";
import {
  getUsers,
  createUser,
  getUser,
  updateUser,
  deleteUser,
} from "../controllers/user.controller.js";

const router = express.Router();

// Protect all routes
router.use(isAuthenticated, isManager);

// User routes
router.route("/users").get(getUsers).post(createUser);

router.route("/users/:id").get(getUser).patch(updateUser).delete(deleteUser);

// Slot routes
router.route("/slots").get(getAllSlots).post(createSlot);

router.route("/slots/:id").patch(updateSlot).delete(deleteSlot);

// Booking routes
router.route("/bookings").get(getAllBookings).post(createBookingByManager);

router.route("/bookings/:id").patch(updateBooking).delete(deleteBooking);

export default router;
