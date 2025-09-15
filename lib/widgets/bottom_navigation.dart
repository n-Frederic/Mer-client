import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF8E1),
            Color(0xFFFFE66D).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Color(0xFFFF8C42),
          unselectedItemColor: Color(0xFF999999),
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 11,
          ),
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.dashboard, 0),
              label: '导图',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.calendar_today, 1),
              label: '视图',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.edit_note, 2),
              label: '日志',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.analytics, 3),
              label: '分析',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.person, 4),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    bool isSelected = currentIndex == index;
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFFFF8C42).withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: isSelected ? 26 : 24,
        color: isSelected ? Color(0xFFFF8C42) : Color(0xFF999999),
      ),
    );
  }
}
