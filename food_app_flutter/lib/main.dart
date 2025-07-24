import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app_flutter/Page%20login/login_screen.dart';
import 'package:food_app_flutter/pages_user/home.dart';
import 'package:food_app_flutter/pages_user/home_user.dart';
import 'admin/admin_home.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KFC Food App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 16)),
      ),
      // home: const HomeUser(),
      // home: const AdminHome(),
      home: const LoginScreen(),
    );
  }
}
