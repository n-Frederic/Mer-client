// lib/views/log_view_detail.dart
import 'package:flutter/material.dart';
import '../models/log.dart';
import '../services/log_service.dart';
import '../services/profile_service.dart';
import '../widgets/task_detail_view.dart';
import 'edit_log.dart';
import '../models/comment.dart';
import '../services/comment_service.dart';
import '../services/auth_service.dart';

class LogDetailView extends StatefulWidget {
  final String logId;
  const LogDetailView({Key? key, required this.logId}) : super(key: key);


  @override
  State<LogDetailView> createState() => _LogDetailViewState();
}

class _LogDetailViewState extends State<LogDetailView> {

  late Future<Log> _logFuture;
  late Future<Map<String, dynamic>> _authorFuture;
  late Future<CommentListResponse> _commentsFuture;
  final _commentController = TextEditingController();
  bool _isPostingComment = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _logFuture = LogService.fetchLogById(widget.logId);
    _authorFuture = _logFuture.then((log) {
      return ProfileService.fetchUserById(log.userId);
    });
  }

  // --- 辅助函数 ---
  void _loadComments() {
    _commentsFuture = CommentService.fetchComments(
      ownerType: 'log',
      ownerId: widget.logId,
    );
  }

  void _refreshComments() {
    setState(() {
      _loadComments();
    });
  }

  void _loadCurrentUserId() async {
    final id = await AuthService.getSavedUserId();
    if (mounted) {
      setState(() {
        _currentUserId = id?.toString();
        _loadComments();
      });
    }
  }
  Color _getStatusColor(String? status) {
    switch (status) {
      case '已通过': return Color(0xFF4ECDC4);
      case '待审批': return Color(0xFFFFE66D);
      case '已拒绝': return Color(0xFFFF6B9D);
      default: return Color(0xFF999999);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _refreshLog() {
    setState(() {
      // 重新执行 initState 中的所有加载逻辑
      _logFuture = LogService.fetchLogById(widget.logId);
      _authorFuture = _logFuture.then((log) {
        return ProfileService.fetchUserById(log.userId);
      }).catchError((e) {
        print("作者加载失败 (依赖于_logFuture): $e");
        return Future.error(e);
      });
    });
  }

  // 【新增】导航到编辑页面的逻辑
  void _navigateToEdit(Log log) async {
    // 导航到新页面，并等待它返回结果 (true 代表"已更新")
    final bool? didUpdate = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditLogScreen(logToEdit: log),
      ),
    );

    // 如果 EditLogScreen 返回 true，则刷新当前页面
    if (didUpdate == true) {
      _refreshLog();
    }
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
        actions: [
          // (我们使用 _logFuture 来确保日志加载完毕后才显示按钮)
          FutureBuilder<Log>(
              future: _logFuture,
              builder: (context, snapshot) {
                // 只有当日志加载成功时才显示编辑按钮
                if (snapshot.hasData) {
                  final log = snapshot.data!;
                  return IconButton(
                    icon: Icon(Icons.edit_outlined, color: Color(0xFF333333)),
                    onPressed: () {
                      // (调用我们刚刚添加的方法)
                      _navigateToEdit(log);
                    },
                  );
                }
                // 加载中或失败时，不显示按钮
                return SizedBox.shrink();
              }
          ),
        ],
      ),
      body: Container(
        color: Colors.transparent,
        child: FutureBuilder<Log>(
          future: _logFuture, // (在 initState 中设置)
          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('加载日志失败: ${snapshot.error}'),
                ),
              );
            }

            if (!snapshot.hasData) {
              return Center(child: Text('未找到日志'));
            }

            final log = snapshot.data!;

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
                              final authorData = authorSnapshot.data;
                              authorName = authorData?['name'] ?? '未知作者';

                            } else if (authorSnapshot.hasError) {
                              authorName = '作者加载失败';
                            }
                            return Column(
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
                   _buildRelatedTasks(log.relatedTasks),
                  SizedBox(height: 24),
                  _buildCommentsSection(),
                ],
              ),
            );
            // --- build 方法的主体结束 ---
          }, // <-- FutureBuilder.builder 结束
        ),
      ),
    );
  }
  void _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    if (_isPostingComment) return;

    setState(() {
      _isPostingComment = true;
    });

    try {
      await CommentService.createComment(
        ownerType: 'log',
        ownerId: widget.logId,
        content: content,
      );
      _commentController.clear(); // 清空输入框
      _refreshComments(); // 刷新列表
    } catch (e) {
      print('提交评论失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('评论失败: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPostingComment = false;
        });
      }
    }
  }

  // 【新增】删除评论
  void _deleteComment(String commentId) async {
    try {
      final success = await CommentService.deleteComment(commentId);
      if (success) {
        _refreshComments(); // 刷新列表
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('评论已删除'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception('API 返回 false');
      }
    } catch (e) {
      print('删除评论失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.red),
      );
    }
  }
  // 【新增】评论区 UI
  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '评论',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: 12),

        // 1. 评论输入框
        Container(
          padding: EdgeInsets.all(8),
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: '添加评论...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  maxLines: null,
                ),
              ),
              _isPostingComment
                  ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
                  : IconButton(
                icon: Icon(Icons.send, color: Color(0xFFFF8C42)),
                onPressed: _postComment,
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // 2. 评论列表
        FutureBuilder<CommentListResponse>(
          future: _commentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('加载评论失败: ${snapshot.error}', style: TextStyle(color: Colors.red)));
            }
            if (!snapshot.hasData || snapshot.data!.comments.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text('暂无评论', style: TextStyle(color: Colors.grey)),
                ),
              );
            }

            final comments = snapshot.data!.comments;
            return ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return _buildCommentItem(comment);
              },
              separatorBuilder: (context, index) => Divider(height: 16, color: Colors.transparent),
            );
          },
        ),
      ],
    );
  }

  // 【新增】单个评论项 UI
  Widget _buildCommentItem(Comment comment) {

    final String commentAuthorId = comment.authorInfo.userId.replaceAll(RegExp(r'[^0-9]'), '');
    final bool isAuthor = commentAuthorId == _currentUserId;
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.authorInfo.name,
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
              SizedBox(width: 8),
              Text(
                _formatDate(comment.createdAt), // (复用你的日期格式)
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Spacer(),
              if (isAuthor)
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[300]),
                  onPressed: () => _deleteComment(comment.commentId),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            comment.content,
            style: TextStyle(color: Color(0xFF333333), height: 1.4),
          ),
        ],
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