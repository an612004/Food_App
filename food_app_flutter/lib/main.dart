import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app_flutter/Page%20login/login_screen.dart';
import 'package:food_app_flutter/firebase_options.dart';
import 'package:food_app_flutter/pages_user/home.dart';
import 'package:food_app_flutter/pages_user/home_user.dart';
// import 'package:food_app_flutter/pages_user/mon_an_yeu_thich.dart'; // Added import for MonAnYeuThich
import 'admin/admin_home.dart';
import 'package:food_app_flutter/pages_user/don_hang.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 16)),
      ),
      home: const LoginScreen(),
      // home: AdminHome(userRole: 'admin'),
      routes: {
        '/donhang': (context) => const MonAnYeuThich(),
        // ...add other routes if needed...
      },
    );
  }
}
