// lib/views/log_view_detail.dart
import 'package:flutter/material.dart';
import '../models/log.dart';
import '../services/log_service.dart';
import '../services/profile_service.dart';
import '../widgets/task_detail_view.dart';

class LogDetailView extends StatefulWidget {
  final String logId;
  const LogDetailView({Key? key, required this.logId}) : super(key: key);

  @override
  State<LogDetailView> createState() => _LogDetailViewState();
}

class _LogDetailViewState extends State<LogDetailView> {

  late Future<Log> _logFuture;
  late Future<Map<String, dynamic>> _authorFuture;

  @override
  void initState() {
    super.initState();
    _logFuture = LogService.fetchLogById(widget.logId);
    _authorFuture = _logFuture.then((log) {
      return ProfileService.fetchUserById(log.userId);
    });
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

        // 【关键修改】我们用 FutureBuilder 包装整个 body
        // 它会等待 LogService.fetchLogById(widget.logId) 完成
        child: FutureBuilder<Log>(
          future: _logFuture, // (在 initState 中设置)
          builder: (context, snapshot) {

            // 1. 加载中
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            // 2. 加载失败
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('加载日志失败: ${snapshot.error}'),
                ),
              );
            }

            // 3. 没有数据
            if (!snapshot.hasData) {
              return Center(child: Text('未找到日志'));
            }

            // 4. 成功！
            // 【修改】从 snapshot (而不是 widget) 获取强类型数据
            final log = snapshot.data!;

            // --- 这是你之前 build 方法的全部内容 ---
            // --- 现在它在 FutureBuilder 内部 ---
            return SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 头部信息 (使用 *嵌套* FutureBuilder 加载作者) ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: FutureBuilder<Map<String, dynamic>>(
                          future: _authorFuture, // (在 initState 中设置)
                          builder: (context, authorSnapshot) {

                            String authorName = '加载中...';
                            String authorAvatar = '👤';

                            if (authorSnapshot.hasData) {
                              // (根据 ProfileService.fetchUserById 的 Map<String, dynamic> 响应)
                              // (我们假设它返回 { 'user': ... })
                              final authorData = authorSnapshot.data?['user'];
                              authorName = authorData?['name'] ?? '未知作者';
                              authorAvatar = (authorData?['username'] as String?)?.substring(0, 1) ?? '👤';
                            } else if (authorSnapshot.hasError) {
                              authorName = '作者加载失败';
                            }

                            return Row(
                              children: [
                                Text(authorAvatar, style: TextStyle(fontSize: 24)),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log.todaySummary ?? '日志 (ID: ${log.logId})',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
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
                          color: _getStatusColor(log.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          log.status ?? '未知',
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

                  // --- 【修改】显示三个新字段 ---
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

                  // --- 【修改】显示 Tags ---
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

                  SizedBox(height: 16),

                  // 【修复】
                  // (现在 log.relatedTasks 包含数据, 这个 Widget 会正确显示)
                  _buildRelatedTasks(log.relatedTasks),
                ],
              ),
            );
            // --- build 方法的主体结束 ---

          }, // <-- FutureBuilder.builder 结束
        ),
      ),
    );
  }

  Widget _buildRelatedTasks(List<RelatedTask> tasks) {
    // 如果没有关联任务，不显示任何东西
    if (tasks.isEmpty) {
      return SizedBox.shrink(); // 返回一个空的小部件
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 标题
        Text(
          '关联的任务', // (你的需求：只显示标题和跳转)
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: 8),

        // 2. 任务卡片列表
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                leading: Icon(Icons.task_alt, color: Color(0xFFFF8C42)),
                title: Text(task.title, style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  // 【核心】点击时跳转到任务详情页
                  print('导航到任务详情页, ID: ${task.taskId}');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailView(
                        taskId: task.taskId.toString(),
                      ),
                    ),
                  );
                },
              );
            },
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.grey[100],
            ),
          ),
        ),
      ],
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