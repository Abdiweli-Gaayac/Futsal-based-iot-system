// For testing: always return success without making a real payment
import crypto from "crypto";

export const initiateWaafiPayment = async (phone, amount, bookingId) => {
  // Simulate a successful payment response for testing
  console.log(amount);
  const referenceId = `BK-${bookingId}-${Date.now()}`;
  return {
    success: true,
    referenceId: referenceId,
    data: {
      responseCode: "2001",
      responseMsg: "Payment successful (test mode)",
      phone,
      amount,
      bookingId,
      timestamp: new Date().toISOString(),
    },
  };
};
// import axios from "axios";
// import crypto from "crypto";
// import {
//   MERCHANT_U_ID,
//   MERCHANT_API_USER_ID,
//   MERCHANT_API_KEY,
// } from "../config/env.js";

// // Replace your current initiateWaafiPayment function with this improved version
// export const initiateWaafiPayment = async (phone, amount, bookingId) => {
//   try {
//     const referenceId = `BK-${bookingId}-${Date.now()}`;

//     const paymentBody = {
//       schemaVersion: "1.0",
//       requestId: crypto.randomUUID(),
//       timestamp: new Date().toISOString(),
//       channelName: "WEB",
//       serviceName: "API_PURCHASE",
//       serviceParams: {
//         merchantUid: MERCHANT_U_ID,
//         apiUserId: MERCHANT_API_USER_ID,
//         apiKey: MERCHANT_API_KEY,
//         paymentMethod: "MWALLET_ACCOUNT",
//         payerInfo: {
//           accountNo: phone,
//         },
//         transactionInfo: {
//           referenceId: referenceId,
//           invoiceId: bookingId,
//           amount: amount.toFixed(2),
//           currency: "USD",
//           description: "Car Wash Service Payment",
//         },
//       },
//     };

//     const response = await axios.post(
//       "https://api.waafipay.com/asm",
//       paymentBody,
//       {
//         headers: {
//           "Content-Type": "application/json",
//           Accept: "application/json",
//         },
//       }
//     );

//     // Check response codes based on WaafiPay documentation
//     const responseCode = response.data.responseCode;

//     // Success case
//     if (responseCode === "2001") {
//       return {
//         success: true,
//         referenceId: referenceId,
//         data: response.data,
//       };
//     }

//     // Handle all possible error codes
//     const errorMessages = {
//       // User-related errors
//       5306: "Payment cancelled by user",
//       5307: "Payment token expired",
//       5309: "Payment timeout",
//       5310: "Payment rejected by user",
//       5311: "Incorrect PIN entered",
//       5312: "Insufficient balance",
//       5313: "Transaction limit exceeded",

//       // System-related errors
//       5001: "System error",
//       5002: "Invalid merchant credentials",
//       5003: "Invalid payment method",
//       5004: "Invalid currency",
//       5005: "Invalid amount format",

//       // Account-related errors
//       5101: "Account not found",
//       5102: "Account inactive",
//       5103: "Account blocked",

//       // Network-related errors
//       5201: "Network error",
//       5202: "Service temporarily unavailable",
//     };

//     // Get user-friendly error message or use the one from response
//     const errorMessage =
//       errorMessages[responseCode] || response.data.responseMsg;
//     throw new Error(errorMessage);
//   } catch (error) {
//     // If it's our custom error, throw it directly
//     if (error.message) {
//       throw error;
//     }
//     // For unexpected errors
//     throw new Error("Payment service unavailable");
//   }
// };
