
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'firebase_options.dart'; // ✅ Added for Firebase config
import 'epartment_provider.dart';
import 'admin.dart';
import 'login_screen.dart';
import 'register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase before anything else
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await requestStoragePermission();

  runApp(
    ChangeNotifierProvider(
      create: (_) => DepartmentProvider(),
      child: const MyApp(),
    ),
  );
}

Future<void> requestStoragePermission() async {
  if (await Permission.storage.request().isDenied) {
    print('Storage permission denied');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shasan Mitra',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        primarySwatch: Colors.indigo,
      ),
      home: LoginScreen(),
      routes: {
        '/admin': (_) => AdminScreen(),
        '/register': (_) => RegisterScreen(),
      },
    );
  }
}
