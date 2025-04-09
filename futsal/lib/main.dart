// lib/main.dart (Updated)
import 'package:flutter/material.dart';
import 'package:futsal/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:futsal/providers/auth_provider.dart';
import 'package:futsal/screens/auth/register_screen.dart';
import 'package:futsal/screens/splash_screen.dart';
import 'package:futsal/screens/client/client_dashboard.dart';
import 'package:futsal/screens/manager/manager_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Futsal Booking',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/client': (context) => const ClientDashboard(),
          '/manager': (context) => const ManagerDashboard(),
        },
        initialRoute: '/',
        onGenerateRoute: (settings) {
          if (settings.name == '/') {
            return MaterialPageRoute(
              builder: (_) => const SplashScreen(),
            );
          }
          return null;
        },
      ),
    );
  }
}
