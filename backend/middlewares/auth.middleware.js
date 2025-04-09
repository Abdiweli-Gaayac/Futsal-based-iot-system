import jwt from "jsonwebtoken";
import User from "../models/user.model.js";
import { JWT_SECRET } from "../config/env.js";

export const isAuthenticated = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(" ")[1];

    if (!token) {
      return res.status(401).json({
        success: false,
        error: "Please login to access this resource",
      });
    }

    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findById(decoded.userId).select("-password");

    if (!user) {
      return res.status(401).json({
        success: false,
        error: "User not found or invalid token",
      });
    }

    req.user = user;
    next();
  } catch (error) {
    console.error("Auth Middleware Error:", error);
    res.status(401).json({
      success: false,
      error: "Invalid token or session expired",
    });
  }
};

export const isManager = (req, res, next) => {
  if (!req.user || req.user.role !== "manager") {
    return res.status(403).json({
      success: false,
      error: "Access denied. Manager role required.",
    });
  }
  next();
};
