import express from "express";
import cookieParser from "cookie-parser";
import cors from "cors";
import { PORT } from "./config/env.js";
import authRouter from "./routes/auth.routes.js";
import managerRoutes from "./routes/manager.routes.js";
import publicRoutes from "./routes/public.routes.js";
import subscriptionRoutes from "./routes/subscription.routes.js";
import { testWaafiPayment } from "./controllers/payment-test.controller.js";

import connectToDatabase from "./database/db.js";
import errorMiddleware from "./middlewares/error.middleware.js";
import { getSomaliaTime } from "./utils/timezone.js";

const app = express();

console.log();
const corsOptions = {
  origin: "*", // Allow all origins during development
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE"],
  allowedHeaders: ["Content-Type", "Authorization", "X-API-Key"], // Added X-API-Key
  credentials: true,
};

app.use(cors(corsOptions));
// Add basic request logging with Somalia timezone
app.use((req, res, next) => {
  const somaliaTime = getSomaliaTime();
  console.log(`${somaliaTime.toISOString()} (Somalia) - ${req.method} ${req.url}`);
  next();
});
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.get("/test", (req, res) => {
  res.json({ status: "ok" });
});
app.use("/auth", authRouter);
app.use("/manager", managerRoutes);
app.use("/public", publicRoutes);
app.use("/subscriptions", subscriptionRoutes);
// Error Middleware (should be last)
app.use(errorMiddleware);
app.get("/test-payment", testWaafiPayment);

app.get("/", (req, res) => {
  res.send("Welcome to the Futsal Management System API!");
});

const server = app.listen(PORT, "0.0.0.0", async () => {
  console.log(
    `Futsal Management System API is running on http://localhost:${PORT}`
  );
  // Connect to database first
  await connectToDatabase();
});

export default app;
