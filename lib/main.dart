import 'package:flutter/material.dart';
import 'pages/routes.dart';
// routes.dart already imports individual page files
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize Realtime Database. If you need a custom databaseURL for web,
  // set it in your Firebase console and replace below.
  if (kIsWeb) {
    // For web you can pass a databaseURL to instanceFor if needed.
    // Example: FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://<PROJECT-ID>.firebaseio.com');
    FirebaseDatabase.instance;
  } else {
    FirebaseDatabase.instance;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Citas Médicas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        scaffoldBackgroundColor: const Color(0xFFF4F9FF),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      initialRoute: Routes.login,
      routes: Routes.getRoutes(),
      onGenerateRoute: Routes.generateRoute,
    );
  }
}
