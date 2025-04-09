import express from "express";
import {
  login,
  register,
  updateProfile,
} from "../controllers/auth.controller.js";
import { isAuthenticated } from "../middlewares/auth.middleware.js";

const router = express.Router();

// Public routes
router.post("/register", register);
router.post("/login", login);

// Protected routes - need authentication
router.patch("/update-profile", isAuthenticated, updateProfile);

export default router;
