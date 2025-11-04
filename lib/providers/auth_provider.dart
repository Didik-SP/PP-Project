// import 'dart:convert';
import 'package:dina_app/pages/auth_page.dart';
import 'package:dina_app/pages/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  FirebaseAuth auth = FirebaseAuth.instance;

  Stream<User?> get streamAuthStatus => auth.authStateChanges();

  Future<void> signup(
      {required String email,
      required String password,
      required BuildContext context}) async {
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      // await Future.delayed(const Duration(seconds: 0));
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (BuildContext context) => MyApp()));
      // await saveUserData(username, phoneNumber)
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with that email.';
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
        );
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {
      print(e);
    }
  }

  Future<void> signin(
      {required String email,
      required String password,
      required BuildContext context}) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      // await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (BuildContext context) => HomePage()));
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'invalid-email') {
        message = 'No user found for that email.';
      } else if (e.code == 'invalid-credential') {
        message = 'Wrong password provided for that user.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {}
  }

  Future<void> signout({required BuildContext context}) async {
    try {
      await FirebaseAuth.instance.signOut();
      await Future.delayed(const Duration(seconds: 1));

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyApp()),
      );
    } catch (e) {
      // Handle any potential errors during sign out
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Future<bool> sendOTPViaWhatsApp(
      {required String email,
      required String password,
      required String username,
      required String whatsapp,
      required BuildContext context}) async {
    const String apiUrl = 'https://api.fonnte.com/send';
    const String apiKey = 'V6HUVKJDCtsZga1Y45gf';
    String otp = (100000 +
            (999999 - 100000) *
                (new DateTime.now().millisecondsSinceEpoch % 1000000) /
                1000000)
        .toInt()
        .toString();
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'target': whatsapp,
          'message': 'Dina Griya Rias "Kode OTP Anda adalah: $otp"',
          'countryCode': '62',
          'delay': '2',
        },
      );
      if (response.statusCode == 200) {
        print('OTP sent successfully');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              otp: otp,
              username: username,
              wa: whatsapp,
              email: email,
              password: password,
            ),
          ),
        );
        return true;
      } else {
        print('Failed to send OTP: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  // verifikasi(
  //     {required String otp,
  //     required String expectedOTP,
  //     required BuildContext context}) async {}

  Future<void> saveUserData({
    required String username,
    required String wa,
    // required BuildContext context,
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'username': username,
          'wa': wa,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Gagal menyimpan data pengguna: $e');
    }
  }

  Future<void> updateUserData({
    required String username,
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'username': username,
        });
        Fluttertoast.showToast(
          msg: "Nama pengguna berhasil diperbarui!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Gagal memperbarui nama pengguna: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      }
    }
    return null;
  }

  Future<void> sendPasswordResetEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
      Fluttertoast.showToast(
        msg: "Link untuk mereset kata sandi telah dikirim! Periksa email Anda.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan. Silakan coba lagi.';
      if (e.code == 'user-not-found') {
        message = 'Pengguna dengan email tersebut tidak ditemukan.';
      } else if (e.code == 'invalid-email') {
        message = 'Alamat email tidak valid.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.red[400],
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }
}
