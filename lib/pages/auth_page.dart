import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import 'widget/button.dart';

class OTPVerificationScreen extends StatelessWidget {
  final String username;
  final String wa;
  final String otp;
  final String email;
  final String password;

  final TextEditingController otpController = TextEditingController();

  OTPVerificationScreen({
    required this.username,
    required this.wa,
    required this.otp,
    required this.email,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi OTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Kode OTP telah dikirim ke WhatsApp Anda.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Masukkan Kode OTP',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 20),

            GradientButton(
              text: 'Verifikasi',
              onPressed: () async {
                if (otpController.text == otp) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("OTP berhasil diverifikasi!"),
                    ),
                  );
                  // Arahkan ke halaman utama atau halaman selanjutnya setelah verifikasi
                  await AuthService().signup(
                    email: email,
                    password: password,
                    context: context,
                  );
                  await AuthService().saveUserData(
                    username: username,
                    wa: wa,
                  );
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => MyApp(),
                  // ),
                  // );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Kode OTP salah, coba lagi."),
                    ),
                  );
                }
              },
            ),

            // ElevatedButton(
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.blue,
            //     minimumSize: const Size(double.infinity, 50),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(10),
            //     ),
            //   ),
            //   onPressed: () async {
            //     if (otpController.text == otp) {
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         const SnackBar(
            //           content: Text("OTP berhasil diverifikasi!"),
            //         ),
            //       );
            //       // Arahkan ke halaman utama atau halaman selanjutnya setelah verifikasi
            //       await AuthService().signup(
            //         email: email,
            //         password: password,
            //         context: context,
            //       );
            //       await AuthService().saveUserData(
            //         username: username,
            //         wa: wa,
            //       );
            //       // Navigator.push(
            //       //   context,
            //       //   MaterialPageRoute(
            //       //     builder: (context) => MyApp(),
            //       // ),
            //       // );
            //     } else {
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         const SnackBar(
            //           content: Text("Kode OTP salah, coba lagi."),
            //         ),
            //       );
            //     }
            //   },
            //   child: const Text('Verifikasi'),
            // ),
          ],
        ),
      ),
    );
  }
}
