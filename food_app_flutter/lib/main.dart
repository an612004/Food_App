import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app_flutter/Page login/login_screen.dart';
import 'package:food_app_flutter/firebase_options.dart';
import 'package:food_app_flutter/pages_user/home.dart';
import 'package:food_app_flutter/pages_user/home_user.dart';
import 'package:food_app_flutter/admin/admin_home.dart';
import 'package:food_app_flutter/pages_user/don_hang.dart';
import 'services/socket_service.dart';
import 'dart:developer';

final socketServiceProvider = Provider<SocketService>((ref) {
  final socketService = SocketService();
  return socketService;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    final socketService = ref.read(socketServiceProvider);
    socketService.connect(); // Kết nối socket tại đây
    print('🔄 SocketService.connect() called in initState');
  }

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
      routes: {
        '/donhang': (context) => const MonAnYeuThich(),
      },
    );
  }
}
