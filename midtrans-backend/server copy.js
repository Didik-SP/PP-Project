const express = require("express");
const mysql = require("mysql");
const cors = require("cors");
const bodyParser = require("body-parser");
const axios = require("axios");
const MIDTRANS_SERVER_KEY = "SB-Mid-server-vzI-RrwkJ2EeeyD0wy3KCRWC";
const MIDTRANS_CLIENT_KEY = "SB-Mid-client-CC0cQTYgMovaOc9O";
const MIDTRANS_BASE_URL =
  "https://app.sandbox.midtrans.com/snap/v1/transactions";

const AUTH_STRING = Buffer.from(MIDTRANS_SERVER_KEY + ":").toString("base64");
console.log(AUTH_STRING);
const app = express();
const port = 5001;
app.use(cors());
app.use(bodyParser.json());
app.post("/get-snap-token", async (req, res) => {
  try {
    const { order_id, gross_amount } = req.body;

    const parameter = {
      transaction_details: {
        order_id: order_id, // ID unik untuk transaksi
        gross_amount: gross_amount, // Total pembayaran
      },
    };

    const transaction = await axios.post(MIDTRANS_BASE_URL, parameter, {
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        Authorization:
          "Basic " + Buffer.from(MIDTRANS_SERVER_KEY + ":").toString("base64"),
      },
    });

    res.status(200).json({
      snap_token: transaction.data.token, // Token yang dihasilkan oleh Midtrans
    });
  } catch (error) {
    console.error("Error:", error.message);
    res.status(500).json({
      status: "error",
      message: "Gagal membuat transaksi Midtrans.",
    });
  }
});

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
