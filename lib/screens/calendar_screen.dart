import 'package:flutter/material.dart';

import '../widgets/calendar_graph_tab.dart';
import '../widgets/task_list_tab.dart';


class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 初始化 Tab 控制器，管理 2 个页面
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 保持原本温暖的渐变背景
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8E1),
              Color(0xFFFFE66D).withAlpha(120),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  // 这里不再是一堆复杂的逻辑，而是两个干净的组件
                  children: [
                    CalendarGraphTab(), // 日历视图组件
                    TaskListTab(),      // 列表视图组件
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 顶部 TabBar 保持不变
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Color(0xFFFF8C42),
              unselectedLabelColor: Color(0xFF999999),
              indicatorColor: Color(0xFFFF8C42),
              tabs: [
                Tab(text: '日历视图'),
                Tab(text: '任务列表'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}