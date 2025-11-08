// lib/views/log_view_detail.dart
import 'package:flutter/material.dart';
import '../models/log.dart'; // <-- 【修改】导入 Log 模型
import '../models/user.dart'; // <-- 【新增】
import '../services/profile_service.dart'; // <-- 【新增】

class LogDetailView extends StatefulWidget {
  // 【修改】不再接收 Map，而是接收强类型 Log 对象
  final Log log;
  const LogDetailView({Key? key, required this.log}) : super(key: key);

  @override
  State<LogDetailView> createState() => _LogDetailViewState();
}

class _LogDetailViewState extends State<LogDetailView> {

  // 【新增】用于异步加载作者信息
  late Future<Map<String, dynamic>> _authorFuture;

  @override
  void initState() {
    super.initState();
    // 【新增】调用 API 获取作者信息
    // (我们使用您已有的 ProfileService.fetchUserById)
    _authorFuture = ProfileService.fetchUserById(widget.log.userId);
  }

  // --- 辅助函数 ---

  Color _getStatusColor(String? status) {
    switch (status) {
      case '已通过': return Color(0xFF4ECDC4);
      case '待审批': return Color(0xFFFFE66D);
      case '已拒绝': return Color(0xFFFF6B9D);
      default: return Color(0xFF999999);
    }
  }

  String _formatDate(DateTime date) {
    // 详情页我们显示完整日期
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }


  @override
  Widget build(BuildContext context) {
    // 【修改】直接从 widget.log 获取强类型数据
    final log = widget.log;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '日志详情',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
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
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 头部信息 (使用 FutureBuilder 加载作者) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 【修改】使用 FutureBuilder 显示头像和姓名
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _authorFuture,
                      builder: (context, snapshot) {

                        // (根据 ProfileService.fetchUserById 的 Map<String, dynamic> 响应)
                        final authorData = snapshot.data;

                        final authorName = authorData?['name'] ?? '加载中...';
                        final authorAvatar = (authorData?['username'] as String?)?.substring(0, 1) ?? '👤';

                        return Row(
                          children: [
                            Text(authorAvatar, style: TextStyle(fontSize: 24)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    // 【修改】使用 todaySummary
                                    log.todaySummary ?? '日志 (ID: ${log.logId})',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    // 【修改】使用 authorName 和 logDate
                                    '$authorName · ${_formatDate(log.logDate)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(log.status), // 【修改】
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      log.status ?? '未知', // 【修改】
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // --- 【修改】显示三个新字段 (替换旧的 'content') ---
              _buildDetailSection(
                  '今日总结',
                  log.todaySummary,
                  Color(0xFF4ECDC4) // 绿色
              ),
              SizedBox(height: 16),
              _buildDetailSection(
                  '明日计划',
                  log.tomorrowPlan,
                  Color(0xFFFF8C42) // 橙色
              ),
              SizedBox(height: 16),
              _buildDetailSection(
                  '需要的协调与帮助',
                  log.helpNeeded,
                  Color(0xFFFF6B9D) // 粉色
              ),

              SizedBox(height: 16),

              // --- 【修改】显示 Tags (使用 log.tags) ---
              if (log.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: log.tags
                      .map((tag) => Container(
                    padding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF8C42), Color(0xFFFFE66D)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 【新增】用于显示新字段的辅助 Widget
  Widget _buildDetailSection(String title, String? content, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: accentColor, width: 4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            (content != null && content.isNotEmpty) ? content : '未填写',
            style: TextStyle(
              fontSize: 15,
              color: (content != null && content.isNotEmpty) ? Color(0xFF333333) : Colors.grey,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}