// main.dart - Setup Provider
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/favorite_provider.dart';
import 'providers/product_provider.dart';
import 'providers/booking_provider.dart';
import 'pages/home.dart';
import 'pages/signin.dart';
import 'providers/transaksi_prov.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(
            create: (_) => FavoriteProvider()..loadFavorites()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => TransaksiProv()),

        // Tambahkan provider lain di sini jika diperlukan
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Wedding App',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: StreamBuilder(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return HomePage();
              }
              return Login();
            }),
      ),
    );
  }
}
