import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/profile_view.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('个人中心')),

      // (不再显示占位符, 而是显示真正的 ProfileView 内容)
      body: ProfileView(),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 4,
        onTap: (index) => _navigateToPage(context, index),
      ),
    );
  }

  void _navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/tasks');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/logs');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/analytics');
        break;
    }
  }
}