import 'package:flutter/material.dart';

// (这是一个占位符页面，用于测试导航)

class NotificationsView extends StatelessWidget {
  const NotificationsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('通知中心'),
        // (使用和 home_screen.dart 类似的风格)
        backgroundColor: Color(0xFFFF8C42),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFE66D),
                Color(0xFFFF8C42),
              ],
            ),
          ),
        ),
        // (添加返回按钮)
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        // (使用和 ProfileView 一样的背景色)
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8E1),
              Color(0xFFFFE66D).withOpacity(0.3),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none,
                  size: 60, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                '通知中心',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              Text(
                '功能开发中...',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}