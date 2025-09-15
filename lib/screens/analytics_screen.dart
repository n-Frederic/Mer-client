import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/chart_widget.dart';

class AnalyticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('数据分析')),
      body: Center(child: Text('数据分析页面')),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 3,
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
        // 已在分析页面
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }
}
