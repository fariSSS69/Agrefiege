import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:agrefiege/pages/splash_screen.dart';
import 'package:agrefiege/pages/home_page.dart';
import 'package:agrefiege/pages/sign_up_page.dart';
import 'package:agrefiege/pages/login_page.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyBtTRvwHwh3LVBiSnIJ6mZi8tg8brigcFw",
        appId: "1:688730428333:android:1ade68149ab52118460724",
        messagingSenderId: "688730428333",
        projectId: "agrefiege-9e11a",
        // Your web Firebase config options
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase',
      routes: {
        '/': (context) => SplashScreen(
          // Here, you can decide whether to show the LoginPage or HomePage based on user authentication
          child: LoginPage(),
        ),
        '/login': (context) => LoginPage(),
        '/signUp': (context) => SignUpPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}