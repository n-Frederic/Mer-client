import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import '../models/task.dart';

class TaskScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('任务管理')),
      body: Center(child: Text('任务管理页面')),
    );
  }
}
