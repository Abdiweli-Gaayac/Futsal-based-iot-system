import mongoose from "mongoose";
import { DB_URI } from "../config/env.js";

if (!DB_URI) {
  throw new Error("Please define the DB_URI environment variable inside .env");
}

const connectToDatabase = async () => {
  try {
    // const options = {
    //   // These options help with MongoDB Atlas connection
    //   useNewUrlParser: true,
    //   useUnifiedTopology: true,
    //   // If you're getting SSL certificate errors, you might need this:
    //   // ssl: true,
    //   // sslValidate: false,
    // };

    await mongoose.connect(DB_URI);
    console.log(`Connected to MongoDB Atlas in  mode`);
  } catch (error) {
    console.error("MongoDB Atlas Connection Error:", error);
    process.exit(1);
  }
};

export default connectToDatabase;
