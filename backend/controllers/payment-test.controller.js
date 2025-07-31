import axios from "axios";
import crypto from "crypto";
import {
  MERCHANT_U_ID,
  MERCHANT_API_USER_ID,
  MERCHANT_API_KEY,
} from "../config/env.js";

export const testWaafiPayment = async (req, res) => {
  try {
    const phone = "0619858211"; // Use provided or default number
    const amount = 10.0; // Use provided or default amount
    const testBookingId = "TEST-" + Date.now();

    // Create a unique reference ID for this transaction
    const referenceId = `TEST-${testBookingId}-${Date.now()}`;

    const paymentBody = {
      schemaVersion: "1.0",
      requestId: crypto.randomUUID(),
      timestamp: new Date().toISOString(),
      channelName: "WEB",
      serviceName: "API_PURCHASE",
      serviceParams: {
        merchantUid: MERCHANT_U_ID,
        apiUserId: MERCHANT_API_USER_ID,
        apiKey: MERCHANT_API_KEY,
        paymentMethod: "MWALLET_ACCOUNT",
        payerInfo: {
          accountNo: phone,
        },
        transactionInfo: {
          referenceId: referenceId,
          invoiceId: testBookingId,
          amount: amount.toFixed(2),
          currency: "USD",
          description: "Futsal Payment Test - Production",
        },
      },
    };

    const productionUrl = "https://api.waafipay.com/asm";

    const productionResponse = await axios.post(productionUrl, paymentBody, {
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
    });

    return res.status(200).json({
      success: true,
      request: paymentBody,
      response: productionResponse.data,
    });
  } catch (error) {
    console.error("Production payment error:", {
      message: error.message,
      response: error.response?.data,
      status: error.response?.status,
    });

    return res.status(500).json({
      success: false,
      error: error.message,
      details: {
        message: error.message,
        data: error.response?.data,
        status: error.response?.status,
      },
    });
  }
};
