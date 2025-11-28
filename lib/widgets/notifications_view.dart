import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/notification.dart';
import '../widgets/log_view_detail.dart';
import '../widgets/task_detail_view.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({Key? key}) : super(key: key);

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late Future<NotificationListResponse> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notificationsFuture = NotificationService.fetchNotifications();
    });
  }

  // 【核心】跳转逻辑
  void _navigateToDetail(NotificationItem item) {
    // 1. 先标记为已读 (静默执行)
    if (!item.isRead) {
      NotificationService.markAsRead(item.id).then((_) {
        // 成功后刷新列表，去掉红点
        _loadNotifications();
      });
    }

    // 2. 根据 type 跳转
    if (item.type == 'task' ||
        item.type == 'task_assigned' ||
        item.type == 'task_reported' ||
        item.type == 'task_due_soon') { // <-- 【新增】截止提醒也跳转任务详情

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskDetailView(taskId: item.ownerId),
        ),
      );

    } else if (item.type == 'log' ||
        item.type == 'journal' ||
        item.type == 'log_commented') {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LogDetailView(logId: item.ownerId),
        ),
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('未知通知类型: ${item.type}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('通知中心'),
        backgroundColor: Color(0xFFFF8C42),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8E1), Color(0xFFFFE66D).withOpacity(0.3)],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async => _loadNotifications(),
          child: FutureBuilder<NotificationListResponse>(
            future: _notificationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('加载失败: ${snapshot.error}', style: TextStyle(color: Colors.red)));
              }
              if (!snapshot.hasData || snapshot.data!.notifications.isEmpty) {
                return Center(child: Text('暂无通知', style: TextStyle(color: Colors.grey)));
              }

              final list = snapshot.data!.notifications;
              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  return _buildNotificationItem(item);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem item) {
    IconData icon;
    Color iconColor;

    // 简单的图标逻辑
    if (item.type.contains('task')) {
      icon = Icons.assignment;
      iconColor = Colors.orange;
    } else {
      icon = Icons.comment;
      iconColor = Colors.blue;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(item.title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(item.message, maxLines: 2, overflow: TextOverflow.ellipsis),
        // 未读红点
        trailing: !item.isRead
            ? Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle))
            : null,
        onTap: () => _navigateToDetail(item),
      ),
    );
  }
}