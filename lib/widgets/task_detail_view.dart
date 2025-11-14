import 'package:flutter/material.dart';
import 'subtask_detail_view.dart';
import '../models/task.dart';
import '../models/role.dart';
import 'log_view_detail.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class TaskDetailView extends StatefulWidget {
  final String taskId;

  const TaskDetailView({
    Key? key,
    required this.taskId,
  }) : super(key: key);

  @override
  _TaskDetailViewState createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final taskFuture = TaskService.fetchTaskById(widget.taskId);
    final userIdFuture = AuthService.getSavedUserId();
    final profileFuture = ProfileService.getUserProfile();

    final task = await taskFuture;
    final currentUserId = (await userIdFuture)?.toString() ?? '';
    final profile = await profileFuture;
    final role = _extractUserRole(profile);

    return {
      'task': task,
      'currentUserId': currentUserId,
      'role': role,
    };
  }

  Role _extractUserRole(Map<String, dynamic> profile) {
    final user = profile['user'] as Map<String, dynamic>? ?? {};
    final roleId = int.tryParse(user['role_id']?.toString() ?? '') ?? 0;
    final roleName = user['role_name']?.toString() ?? '未知角色';
    final roleDesc = user['role_desc']?.toString();
    return Role(roleId: roleId, name: roleName, description: roleDesc);
  }

  Future<void> _refreshData() async {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('加载任务详情失败: ${snapshot.error}',
                    style: TextStyle(color: Colors.red)),
              ),
            );
          }

          if (snapshot.hasData) {
            final Task loadedTask = snapshot.data!['task'] as Task;
            final String currentUserId = snapshot.data!['currentUserId'] as String;
            final Role currentUserRole = snapshot.data!['role'] as Role;

            final Map<String, dynamic> _dynamicProperties = {
              'emoji': '📝',
              'progress': _calculateProgress(loadedTask),
              'assignedTo': loadedTask.creator?.userId ?? currentUserId,
              'subtasks': [],
              'collaborators': ['N/A'],
            };

            return RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTaskInfo(loadedTask, _dynamicProperties),
                    SizedBox(height: 20),
                    _buildTaskDetailsList(loadedTask),
                    SizedBox(height: 20),
                    _buildSubtasks(loadedTask, _dynamicProperties, currentUserRole),
                    SizedBox(height: 20),
                    _buildCollaborators(_dynamicProperties),
                    SizedBox(height: 20),
                    _buildTaskLogsList(loadedTask.relatedLogs),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }

          return Center(child: Text('未知状态'));
        },
      ),
    );
  }

  // 计算任务进度
  double _calculateProgress(Task task) {
    switch (task.status) {
      case TaskStatus.published:
        return 0.25;
      case TaskStatus.assigned:
        return 0.5;
      case TaskStatus.inProgress:
        return 0.6;
      case TaskStatus.reported:
        return 0.75;
      case TaskStatus.completed:
        return 1.0;
      case TaskStatus.closed:
        return 1.0;
      default:
        return 0.0;
    }
  }

  Widget _buildTaskInfo(Task loadedTask, Map<String, dynamic> dynamicProperties) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF8C42), Color(0xFFFF6B9D)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(dynamicProperties['emoji'], style: TextStyle(fontSize: 24))),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loadedTask.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              loadedTask.description,
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), height: 1.5),
            ),
            SizedBox(height: 12),
            // 显示当前任务状态
            Row(
              children: [
                Chip(
                  label: Text(
                    _getStatusText(loadedTask.status),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: _getStatusColor(loadedTask.status),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '当前状态: ${_getStatusDescription(loadedTask.status)}',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: dynamicProperties['progress'],
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              '进度: ${(dynamicProperties['progress'] * 100).toInt()}%',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
            ),
          ],
        ),
      ),
    );
  }

  // 获取状态描述
  String _getStatusDescription(TaskStatus status) {
    switch (status) {
      case TaskStatus.published:
        return '任务已发布，等待提交报告';
      case TaskStatus.assigned:
        return '任务已分配，等待开始';
      case TaskStatus.inProgress:
        return '任务进行中';
      case TaskStatus.reported:
        return '已提交报告，等待审核';
      case TaskStatus.completed:
        return '任务已完成';
      case TaskStatus.closed:
        return '任务已关闭';
      default:
        return '未知状态';
    }
  }

  Widget _buildTaskLogsList(List<TaskRelatedLog> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '相关日志',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        SizedBox(height: 12),
        if (logs.isEmpty)
          Text(
            '当前任务还没有关联的日志',
            style: TextStyle(color: Color(0xFF666666)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final relatedLog = logs[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  relatedLog.title.isNotEmpty ? relatedLog.title : '日志 ${relatedLog.logId}',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'ID: ${relatedLog.logId}',
                  style: TextStyle(color: Color(0xFF666666)),
                ),
                trailing: Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LogDetailView(logId: relatedLog.logId),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildSubtasks(
    Task loadedTask,
    Map<String, dynamic> dynamicProperties,
    Role currentUserRole,
  ) {
    List<dynamic> subtasks = dynamicProperties['subtasks'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '子任务',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: 12),
        if (subtasks.isEmpty)
          Text(
            '暂无子任务',
            style: TextStyle(color: Color(0xFF666666)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: subtasks.length,
            itemBuilder: (context, index) {
              final subtask = subtasks[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubtaskDetailView(
                        subtask: subtask,
                        userRole: currentUserRole,
                        onSubtaskUpdated: (updatedSubtask) {
                          _refreshData();
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subtask['title'],
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '分配给: ${subtask['assignedTo']}',
                              style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(
                          subtask['completed'] ? '已完成' : '未完成',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        backgroundColor: subtask['completed'] ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCollaborators(Map<String, dynamic> dynamicProperties) {
    List<String> collaborators = dynamicProperties['collaborators'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '协作成员',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: collaborators.map((collaborator) => Chip(
            label: Text(collaborator, style: TextStyle(fontSize: 12)),
            avatar: CircleAvatar(child: Text(collaborator[0])),
            backgroundColor: Colors.white,
            elevation: 2,
          )).toList(),
        ),
      ],
    );
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.published:
        return '已发布';
      case TaskStatus.assigned:
        return '已分配';
      case TaskStatus.inProgress:
        return '进行中';
      case TaskStatus.reported:
        return '已提交';
      case TaskStatus.completed:
        return '已完成';
      case TaskStatus.closed:
        return '已关闭';
      default:
        return '未知';
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.published:
        return Color(0xFFFF8C42); // 橙色
      case TaskStatus.assigned:
        return Color(0xFF4ECDC4); // 青色
      case TaskStatus.inProgress:
        return Colors.blue; // 蓝色
      case TaskStatus.reported:
        return Colors.purple; // 紫色
      case TaskStatus.completed:
        return Color(0xFF88D8B0); // 绿色
      case TaskStatus.closed:
        return Colors.grey; // 灰色
      default:
        return Colors.grey;
    }
  }

  String _formatTaskDate(DateTime? date) {
    if (date == null) {
      return '未设置';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(title, style: TextStyle(fontSize: 15, color: Color(0xFF666666))),
      trailing: Text(
        value,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF333333)),
      ),
      dense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
    );
  }

  Widget _buildTaskDetailsList(Task loadedTask) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '任务详情',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        SizedBox(height: 12),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.person_outline,
                  title: '创建者',
                  value: loadedTask.creator?.name ?? '未知',
                  iconColor: Color(0xFF4ECDC4),
                ),
                Divider(height: 1),
                _buildDetailRow(
                  icon: Icons.flag_outlined,
                  title: '优先级',
                  value: loadedTask.priority.sqlValue,
                  iconColor: Color(0xFFFF6B9D),
                ),
                Divider(height: 1),
                _buildDetailRow(
                  icon: Icons.play_arrow_outlined,
                  title: '开始时间',
                  value: _formatTaskDate(loadedTask.startAt),
                  iconColor: Color(0xFF88D8B0),
                ),
                Divider(height: 1),
                _buildDetailRow(
                  icon: Icons.timer_outlined,
                  title: '截止时间',
                  value: _formatTaskDate(loadedTask.dueAt),
                  iconColor: Color(0xFFFF8C42),
                ),
                Divider(height: 1),
                _buildDetailRow(
                  icon: Icons.add_circle_outline,
                  title: '创建时间',
                  value: _formatTaskDate(loadedTask.createdAt),
                  iconColor: Color(0xFF999999),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}