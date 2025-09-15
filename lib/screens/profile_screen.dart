import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('个人中心')),
      body: Center(child: Text('个人中心页面')),
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
      case 4:
        // 已在个人中心页面
        break;
    }
  }
}
