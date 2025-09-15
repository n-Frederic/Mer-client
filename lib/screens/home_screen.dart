import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/eisenhower_matrix.dart';
import '../widgets/calendar_view.dart';
import '../widgets/log_view.dart';
import '../widgets/analytics_view.dart';
import '../widgets/profile_view.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimationController.forward();
  }

  final List<Widget> _pages = [
    EisenhowerMatrix(),
    CalendarView(),
    LogView(),
    AnalyticsView(),
    ProfileView(),
  ];

  final List<String> _titles = [
    'MER',
    'MER',
    'MER',
    'MER',
    'MER',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
          ),
        ),
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
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
      floatingActionButton: _currentIndex == 0 ? Container(
        margin: EdgeInsets.only(bottom: 20), // 添加底部边距，让按钮向上移动
        child: ScaleTransition(
          scale: _fabAnimationController,
          child: FloatingActionButton(
            onPressed: () {
              _showAddDialog();
            },
            backgroundColor: Color(0xFFFF6B9D),
            child: Icon(Icons.add, color: Colors.white, size: 28),
            elevation: 8,
          ),
        ),
      ) : null, // 只在第一个页面（导图页）显示
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // 改为 centerFloat 让按钮浮动
    );
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '添加新内容',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildAddOption(Icons.task_alt, '新建任务', '创建一个新的任务项目'),
                    SizedBox(height: 12),
                    _buildAddOption(Icons.edit_note, '写日志', '记录今天的工作心得'),
                    SizedBox(height: 12),
                    _buildAddOption(Icons.event, '添加日程', '安排新的日程计划'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddOption(IconData icon, String title, String subtitle) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title 功能开发中...'),
            backgroundColor: Color(0xFFFF8C42),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFFFE66D), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(0xFFFF8C42),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }
}
