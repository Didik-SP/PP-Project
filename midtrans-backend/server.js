const express = require("express");
const midtransClient = require("midtrans-client");
const cors = require("cors");
const bodyParser = require("body-parser");
require("dotenv").config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Initialize Midtrans Snap
const snap = new midtransClient.Snap({
  isProduction: false, // Ubah ke true untuk production
  serverKey:
    process.env.MIDTRANS_SERVER_KEY || "SB-Mid-server-vzI-RrwkJ2EeeyD0wy3KCRWC",
  clientKey:
    process.env.MIDTRANS_CLIENT_KEY || "SB-Mid-client-CC0cQTYgMovaOc9O",
});

// Health check endpoint
app.get("/", (req, res) => {
  res.json({ status: "Server is running", timestamp: new Date() });
});

// Create Midtrans transaction
app.post("/api/create-transaction", async (req, res) => {
  try {
    const {
      transaksiId,
      orderId,
      grossAmount,
      customerName,
      customerEmail,
      customerPhone,
    } = req.body;

    console.log("Creating transaction:", {
      orderId,
      grossAmount,
      customerName,
    });

    // Validasi input
    if (!orderId || !grossAmount || !customerName) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields",
      });
    }

    // Parameter transaksi
    const parameter = {
      transaction_details: {
        order_id: orderId,
        gross_amount: parseInt(grossAmount),
      },
      customer_details: {
        first_name: customerName,
        email: customerEmail || "customer@example.com",
        phone: customerPhone || "08123456789",
      },
      item_details: [
        {
          id: transaksiId || "item-1",
          price: parseInt(grossAmount),
          quantity: 1,
          name: `DP Booking - ${customerName}`,
        },
      ],
      callbacks: {
        finish: "myapp://payment/finish",
        error: "myapp://payment/error",
        pending: "myapp://payment/pending",
      },
    };

    // Buat transaksi
    const transaction = await snap.createTransaction(parameter);

    console.log("Transaction created successfully");

    res.json({
      success: true,
      snapToken: transaction.token,
      redirectUrl: transaction.redirect_url,
    });
  } catch (error) {
    console.error("Error creating transaction:", error);
    res.status(500).json({
      success: false,
      message: error.message || "Failed to create transaction",
    });
  }
});

// Webhook handler - untuk menerima notifikasi dari Midtrans
app.post("/api/webhook", async (req, res) => {
  try {
    const notification = req.body;

    console.log("Webhook received:", notification);

    const orderId = notification.order_id;
    const transactionStatus = notification.transaction_status;
    const fraudStatus = notification.fraud_status;
    const transactionId = notification.transaction_id;

    let status = "pending";

    // Tentukan status berdasarkan notifikasi
    if (transactionStatus == "capture") {
      if (fraudStatus == "accept") {
        status = "diproses";
      }
    } else if (transactionStatus == "settlement") {
      status = "diproses";
    } else if (
      transactionStatus == "cancel" ||
      transactionStatus == "deny" ||
      transactionStatus == "expire"
    ) {
      status = "dibatalkan";
    } else if (transactionStatus == "pending") {
      status = "pending";
    }

    console.log(`Order ${orderId} status updated to: ${status}`);

    // Di sini Anda bisa menambahkan logika untuk update Firebase
    // Misalnya menggunakan Firebase Admin SDK
    // await admin.firestore().collection('transaksi').doc(transaksiId).update({
    //   statusPembayaran: status,
    //   paymentDetails: notification,
    //   updatedAt: admin.firestore.FieldValue.serverTimestamp()
    // });

    res.status(200).json({
      success: true,
      message: "Webhook processed successfully",
    });
  } catch (error) {
    console.error("Webhook error:", error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Check transaction status
app.post("/api/check-status", async (req, res) => {
  try {
    const { orderId } = req.body;

    const statusResponse = await snap.transaction.status(orderId);

    res.json({
      success: true,
      data: statusResponse,
    });
  } catch (error) {
    console.error("Error checking status:", error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(
    `📍 API endpoint: http://localhost:${PORT}/api/create-transaction`
  );
  console.log(`📍 Webhook endpoint: http://localhost:${PORT}/api/webhook`);
});
