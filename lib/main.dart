import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/log_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(PandoraApp());
}

class PandoraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pandora',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColor: Color(0xFFFF8C42),
        scaffoldBackgroundColor: Color(0xFFFFF8E1),
        fontFamily: 'Nunito',
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFFF8C42),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'DancingScript',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF8C42),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 4,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFFF8C42),
          brightness: Brightness.light,
        ).copyWith(
          primary: Color(0xFFFF8C42),
          secondary: Color(0xFFFFE66D),
          surface: Colors.white,
          background: Color(0xFFFFF8E1),
        ),
      ),
      // home: HomeScreen(),
      home: LoginScreen(),  // 修改这里：直接跳转到登录页面
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/tasks': (context) => CalendarScreen(),
        '/logs': (context) => LogScreen(),
        '/analytics': (context) => AnalyticsScreen(),
        '/profile': (context) => ProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
