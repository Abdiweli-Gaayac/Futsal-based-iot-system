import mongoose from "mongoose";
import { DB_URI } from "../config/env.js";

if (!DB_URI) {
  throw new Error("Please define the DB_URI environment variable inside .env");
}

const connectToDatabase = async () => {
  try {
    await mongoose.connect(DB_URI);
    console.log(`Connected to MongoDB Atlas in  mode`);
    await seedManagerUser();
  } catch (error) {
    console.error("MongoDB Atlas Connection Error:", error);
    process.exit(1);
  }
};

// --- Seed manager user if not exists ---
import User from "../models/user.model.js";
import bcrypt from "bcryptjs";
import Booking from "../models/booking.model.js";
import Subscription from "../models/subscription.model.js";

const seedManagerUser = async () => {
  // await Booking.deleteMany({});
  // await Subscription.deleteMany({});

  const phone = "0612995362";
  const password = "123456";
  const existing = await User.findOne({ phone, role: "manager" });
  if (!existing) {
    // const hashedPassword = await bcrypt.hash(password, 10);
    await User.create({
      name: "Manager",
      phone,
      password: password,
      role: "manager",
    });
    console.log(
      "Seeded manager user with phone 0612995362 and password 123456"
    );
  } else {
    console.log("Manager user with phone 0612995362 already exists");
  }
};

export default connectToDatabase;
