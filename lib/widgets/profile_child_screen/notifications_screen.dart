import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool enableNotifications = true;

  List<Map<String, String>> notificationHistory = [
    {'title': '任务已完成', 'time': '今天 10:30'},
    {'title': '日志已记录', 'time': '今天 09:15'},
    {'title': '周报已生成', 'time': '昨天 18:00'},
    {'title': '新消息提醒', 'time': '昨天 14:20'},
    {'title': '任务即将到期', 'time': '昨天 08:00'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('消息通知'),
        backgroundColor: Color(0xFFFF8C42),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '消息通知',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            enableNotifications ? '已启用所有通知' : '已禁用所有通知',
                            style: TextStyle(
                              fontSize: 13,
                              color: enableNotifications
                                  ? Color(0xFFFF8C42)
                                  : Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: enableNotifications,
                      onChanged: (value) {
                        setState(() => enableNotifications = value);
                      },
                      activeColor: Color(0xFFFF8C42),
                      inactiveThumbColor: Color(0xFFCCCCCC),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '通知历史',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showClearDialog,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF8C42).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '清空历史',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFF8C42),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              notificationHistory.isEmpty
                  ? Container(
                margin: EdgeInsets.only(top: 20),
                padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 48,
                        color: Color(0xFFCCCCCC),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '暂无通知历史',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: notificationHistory.length,
                itemBuilder: (context, index) {
                  return _buildHistoryCard(
                    notificationHistory[index]['title']!,
                    notificationHistory[index]['time']!,
                    index,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(String title, String time, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.notifications_active,
            color: Color(0xFFFF8C42).withOpacity(0.6),
            size: 20,
          ),
        ],
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('清空历史'),
        content: Text('确定要清空所有通知历史记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: Color(0xFF999999))),
          ),
          TextButton(
            onPressed: () {
              setState(() => notificationHistory.clear());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('通知历史已清空'),
                  backgroundColor: Color(0xFFFF8C42),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text('清空', style: TextStyle(color: Color(0xFFFF8C42))),
          ),
        ],
      ),
    );
  }
}
