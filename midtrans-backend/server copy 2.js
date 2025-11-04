const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const axios = require("axios");

// Midtrans Configuration
const MIDTRANS_SERVER_KEY = "SB-Mid-server-vzI-RrwkJ2EeeyD0wy3KCRWC";
const MIDTRANS_CLIENT_KEY = "SB-Mid-client-CC0cQTYgMovaOc9O";
const MIDTRANS_BASE_URL =
  "https://app.sandbox.midtrans.com/snap/v1/transactions";

const AUTH_STRING = Buffer.from(MIDTRANS_SERVER_KEY + ":").toString("base64");
console.log("Midtrans Auth String:", AUTH_STRING);

const app = express();
const port = 5001;

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: "50mb" }));
app.use(bodyParser.urlencoded({ limit: "50mb", extended: true }));

// Enhanced Snap Token Endpoint
app.post("/get-snap-token", async (req, res) => {
  try {
    const {
      order_id,
      gross_amount,
      customer_details,
      item_details,
      transaction_details,
    } = req.body;

    // Validate required fields
    if (!order_id || !gross_amount) {
      return res.status(400).json({
        status: "error",
        message: "order_id dan gross_amount wajib diisi",
      });
    }

    // Enhanced parameter object
    const parameter = {
      transaction_details: {
        order_id: order_id,
        gross_amount: gross_amount,
      },
      credit_card: {
        secure: true,
      },
      customer_details: customer_details || {
        first_name: "Customer",
        last_name: "",
        email: "customer@example.com",
        phone: "08123456789",
      },
      item_details: item_details || [
        {
          id: "item1",
          price: gross_amount,
          quantity: 1,
          name: "Pembelian Produk",
        },
      ],
      callbacks: {
        finish: "https://your-app.com/payment/finish",
        error: "https://your-app.com/payment/error",
        pending: "https://your-app.com/payment/pending",
      },
    };

    console.log(
      "Creating transaction with parameter:",
      JSON.stringify(parameter, null, 2)
    );

    // Call Midtrans API
    const transaction = await axios.post(MIDTRANS_BASE_URL, parameter, {
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        Authorization: "Basic " + AUTH_STRING,
      },
    });

    console.log("✅ Midtrans response:", transaction.data);

    // Return snap token to Flutter app
    res.status(200).json({
      status: "success",
      snap_token: transaction.data.token,
      redirect_url: transaction.data.redirect_url,
      order_id: order_id,
      gross_amount: gross_amount,
    });
  } catch (error) {
    console.error(
      "❌ Error creating Midtrans transaction:",
      error.response?.data || error.message
    );

    res.status(500).json({
      status: "error",
      message: "Gagal membuat transaksi Midtrans.",
      error: error.response?.data || error.message,
    });
  }
});

// Webhook endpoint untuk menerima notifikasi dari Midtrans
app.post("/midtrans-webhook", (req, res) => {
  try {
    const notification = req.body;

    console.log("🔔 Midtrans webhook received:", notification);

    const orderId = notification.order_id;
    const transactionStatus = notification.transaction_status;
    const fraudStatus = notification.fraud_status;

    let status = "pending";

    // Determine final transaction status
    if (transactionStatus == "capture") {
      if (fraudStatus == "challenge") {
        status = "challenge";
      } else if (fraudStatus == "accept") {
        status = "success";
      }
    } else if (transactionStatus == "settlement") {
      status = "success";
    } else if (
      transactionStatus == "cancel" ||
      transactionStatus == "deny" ||
      transactionStatus == "expire"
    ) {
      status = "failed";
    } else if (transactionStatus == "pending") {
      status = "pending";
    }

    console.log(`📊 Transaction ${orderId} status: ${status}`);

    // Log webhook data for Flutter to potentially listen to
    // Flutter app should handle updating Firebase with this status
    console.log("📱 Flutter should update Firebase with:", {
      order_id: orderId,
      status: status,
      transaction_status: transactionStatus,
      fraud_status: fraudStatus,
      timestamp: new Date().toISOString(),
    });

    res.status(200).json({ status: "OK" });
  } catch (error) {
    console.error("❌ Webhook error:", error);
    res.status(500).json({ status: "ERROR" });
  }
});

// Check Midtrans transaction status directly
app.get("/check-transaction/:order_id", async (req, res) => {
  try {
    const orderId = req.params.order_id;

    const statusResponse = await axios.get(
      `https://api.sandbox.midtrans.com/v2/${orderId}/status`,
      {
        headers: {
          Accept: "application/json",
          Authorization: "Basic " + AUTH_STRING,
        },
      }
    );

    console.log(`📋 Transaction status for ${orderId}:`, statusResponse.data);

    res.json({
      status: "success",
      data: statusResponse.data,
    });
  } catch (error) {
    console.error(
      "❌ Error checking transaction status:",
      error.response?.data || error.message
    );

    res.status(500).json({
      status: "error",
      message: "Gagal mengecek status transaksi",
      error: error.response?.data || error.message,
    });
  }
});

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({
    status: "OK",
    timestamp: new Date().toISOString(),
    service: "Payment Gateway Server",
    midtrans_environment: "sandbox",
    version: "1.0.0",
  });
});

// Test endpoint untuk memastikan server berjalan
app.get("/", (req, res) => {
  res.json({
    message: "🚀 Payment Gateway Server is running!",
    endpoints: {
      "POST /get-snap-token": "Create payment token",
      "POST /midtrans-webhook": "Handle payment notifications",
      "GET /check-transaction/:order_id":
        "Check transaction status from Midtrans",
      "GET /health": "Health check",
    },
    timestamp: new Date().toISOString(),
  });
});

// Start server
app.listen(port, () => {
  console.log(
    `🚀 Payment Gateway Server is running on http://localhost:${port}`
  );
  console.log(`📋 Available endpoints:`);
  console.log(`   - GET  /                           - Server info`);
  console.log(`   - POST /get-snap-token             - Create payment token`);
  console.log(
    `   - POST /midtrans-webhook           - Handle payment notifications`
  );
  console.log(
    `   - GET  /check-transaction/:order_id - Check transaction status`
  );
  console.log(`   - GET  /health                     - Health check`);
  console.log(`\n💡 Tips for Flutter integration:`);
  console.log(`   - Use POST /get-snap-token to get payment token`);
  console.log(`   - Handle payment result in Flutter`);
  console.log(`   - Update Firebase from Flutter app`);
  console.log(`   - Use webhook for server-side verification`);
});

// Graceful shutdown
process.on("SIGTERM", () => {
  console.log("SIGTERM received, shutting down gracefully");
  process.exit(0);
});

process.on("SIGINT", () => {
  console.log("SIGINT received, shutting down gracefully");
  process.exit(0);
});
