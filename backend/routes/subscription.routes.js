import express from "express";
import {
  createSubscription,
  getClientSubscriptions,
  cancelSubscription,
  getAllSubscriptions,
  createSubscriptionByManager,
  updateSubscription,
  deleteSubscription,
} from "../controllers/subscription.controller.js";
import { isAuthenticated, isManager } from "../middlewares/auth.middleware.js";

const router = express.Router();

// Client routes (require authentication)
router.use(isAuthenticated);

// Client subscription routes
router.post("/", createSubscription);
router.get("/my-subscriptions", getClientSubscriptions);
router.put("/cancel/:subscriptionId", cancelSubscription);

// Manager routes (require manager role)
router.get("/all", isManager, getAllSubscriptions);
router.post("/manager", isManager, createSubscriptionByManager);
router.put("/:id", isManager, updateSubscription);
router.delete("/:id", isManager, deleteSubscription);

export default router;
