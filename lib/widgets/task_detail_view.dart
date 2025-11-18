import 'package:flutter/material.dart';
import 'package:pandora_app/widgets/reject_reason_dialog.dart';
import 'package:pandora_app/widgets/task_report_detail_view.dart';
import '../models/task.dart';
import '../models/task_report.dart';
import '../models/role.dart';
import '../models/task_user.dart';
import '../models/log.dart';
import 'subtask_detail_view.dart';
import 'log_view_detail.dart';
import 'task_report_view.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/task_report_service.dart';

class TaskDetailView extends StatefulWidget {
  final String taskId;
  final Function(Task)? onTaskUpdated;

  const TaskDetailView({
    Key? key,
    required this.taskId,
    this.onTaskUpdated,
  }) : super(key: key);

  @override
  _TaskDetailViewState createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  late Future<Map<String, dynamic>> _dataFuture;
  List<TaskReport> _taskReports = [];
  List<TaskUser> _taskAssignees = [];
  TaskUser? _taskAssigner;
  bool _isLoadingReports = false;
  bool _isLoadingAssignment = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingReports = true;
          _isLoadingAssignment = true;
        });
      }

      _dataFuture = _loadData();
      await Future.wait([
        _loadTaskReports(),
        _loadTaskAssignmentInfo(),
      ]);
    } catch (e) {
      print('初始化数据失败: $e');
    }
  }

  Future<Map<String, dynamic>> _loadData() async {
    print('🚀 开始加载任务数据，任务ID: ${widget.taskId}');
    try {
      final task = await TaskService.fetchTaskById(widget.taskId);
      print('✅ 任务数据加载成功: ${task.title}');

      final currentUserId = (await AuthService.getSavedUserId())?.toString() ?? '';
      print('👤 当前用户ID: $currentUserId');

      final profile = await ProfileService.getUserProfile();
      final role = _extractUserRole(profile);
      print('🎭 用户角色: ${role.name} (ID: ${role.roleId})');

      return {
        'task': task,
        'currentUserId': currentUserId,
        'role': role,
      };
    } catch (e) {
      print('❌ 加载任务数据失败: $e');
      rethrow;
    }
  }

  // 统一加载任务分配信息
  Future<void> _loadTaskAssignmentInfo() async {
    if (mounted) {
      setState(() {
        _isLoadingAssignment = true;
      });
    }

    try {
      final assignmentInfo = await TaskService.fetchTaskAssignmentInfo(widget.taskId);

      if (mounted) {
        setState(() {
          _taskAssignees = assignmentInfo['assignees'] ?? [];
          _taskAssigner = assignmentInfo['assigner'];
          _isLoadingAssignment = false;
        });
      }
    } catch (e) {
      print('加载任务分配信息失败: $e');
      if (mounted) {
        setState(() {
          _taskAssignees = [];
          _taskAssigner = null;
          _isLoadingAssignment = false;
        });
      }
    }
  }
  Future<void> _loadTaskReports() async {
    if (mounted) {
      setState(() {
        _isLoadingReports = true;
      });
    }

    try {
      final reports = await TaskReportService.fetchTaskReports(widget.taskId);

      if (mounted) {
        setState(() {
          _taskReports = reports;
          _isLoadingReports = false;
        });
      }
    } catch (e) {
      print('加载任务报告失败: $e');
      if (mounted) {
        setState(() {
          _taskReports = [];
          _isLoadingReports = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _dataFuture = _loadData();
      _isLoadingReports = true;
      _isLoadingAssignment = true;
    });
    await Future.wait([
      _loadTaskReports(),
      _loadTaskAssignmentInfo(),
    ]);
  }

  Role _extractUserRole(Map<String, dynamic> profile) {
    final user = profile['user'] as Map<String, dynamic>? ?? {};
    final roleId = int.tryParse(user['role_id']?.toString() ?? '') ?? 0;
    final roleName = user['role_name']?.toString() ?? '未知角色';
    final roleDesc = user['role_desc']?.toString();
    return Role(roleId: roleId, name: roleName, description: roleDesc);
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
                    _buildCollaborators(),
                    SizedBox(height: 20),
                    _buildTaskLogsList(loadedTask.relatedLogs),
                    SizedBox(height: 20),
                    _buildReportSection(loadedTask, currentUserRole, currentUserId),
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

  // 报告部分显示逻辑
  Widget _buildReportSection(Task task, Role currentUserRole, String currentUserId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReportInfo(),
        SizedBox(height: 16),

        if (task.status == TaskStatus.published && _canSubmitReport(currentUserRole, task, currentUserId))
          _buildSubmitReportButton(task),

        if (task.status == TaskStatus.reported && _canApproveReport(task, currentUserRole, currentUserId))
          _buildApproveRejectButtons(task),
      ],
    );
  }

  bool _canSubmitReport(Role role, Task task, String currentUserId) {
    // 检查当前用户是否在被指派人列表中
    final isAssignee = _taskAssignees.any((assignee) => assignee.userId == currentUserId);

    print('🔍 检查提交报告权限:');
    print('   当前用户ID: $currentUserId');
    print('   被指派人列表: ${_taskAssignees.map((e) => '${e.name}(${e.userId})').toList()}');
    print('   是否有提交权限: $isAssignee');

    return isAssignee;
  }

  bool _canApproveReport(Task task, Role currentUserRole, String currentUserId) {
    print('🔍 检查审批权限:');
    print('   任务创建者ID: ${task.creator?.userId}');
    print('   当前用户ID: $currentUserId');
    print('   用户角色ID: ${currentUserRole.roleId}');
    print('   用户角色名称: ${currentUserRole.name}');
    print('   任务状态: ${task.status}');
    print('   指派人ID: ${_taskAssigner?.userId}');
    print('   指派人姓名: ${_taskAssigner?.name}');

    // 检查是否是任务创建者
    final isCreator = task.creator?.userId == currentUserId;
    // 检查是否是管理员（roleId == 5）
    final isAdmin = currentUserRole.roleId == 5;
    // 检查是否是指派人
    final isAssigner = _taskAssigner?.userId == currentUserId;

    print('   是否是创建者: $isCreator');
    print('   是否是管理员: $isAdmin');
    print('   是否是指派人: $isAssigner');
    print('   是否有审批权限: ${isCreator || isAdmin || isAssigner}');

    return isCreator || isAdmin || isAssigner;
  }

  Widget _buildSubmitReportButton(Task task) {
    return Center(
      child: ElevatedButton(
        onPressed: () => _handleReport(task),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFF8C42),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_turned_in, size: 20),
            SizedBox(width: 8),
            Text('提交工作报告', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // 批阅按钮
  Widget _buildApproveRejectButtons(Task task) {
    return Column(
      children: [
        // 添加查看报告详情按钮
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            onPressed: () {
              if (_taskReports.isNotEmpty) {
                // 查看最新的报告
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskReportDetailView(
                      report: _taskReports.first,
                      taskId: widget.taskId,
                    ),
                  ),
                );
              }
            },
            icon: Icon(Icons.remove_red_eye, size: 20),
            label: Text('查看报告详情', style: TextStyle(fontSize: 16)),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: Colors.blue),
            ),
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _handleApproveReport(task),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 20),
                  SizedBox(width: 8),
                  Text('通过报告', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            SizedBox(width: 16),
            OutlinedButton(
              onPressed: () => _handleRejectReport(task),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                side: BorderSide(color: Colors.red),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('拒绝报告', style: TextStyle(fontSize: 16, color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '工作报告',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            SizedBox(width: 8),
            if (_isLoadingReports)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        SizedBox(height: 12),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: _isLoadingReports
                ? Center(child: CircularProgressIndicator())
                : _taskReports.isEmpty
                ? Column(
              children: [
                Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[400]),
                SizedBox(height: 8),
                Text('暂无工作报告', style: TextStyle(color: Color(0xFF666666))),
              ],
            )
                : Column(
              children: _taskReports.map((report) => _buildReportItem(report)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // 在 TaskDetailView 中修改 _buildReportItem 方法
  Widget _buildReportItem(TaskReport report) {
    return GestureDetector(
      onTap: () {
        // 点击报告项查看详情
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskReportDetailView(
              report: report,
              taskId: widget.taskId,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    report.reporterName?.isNotEmpty == true ? report.reporterName![0] : 'U',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.reporterName ?? '未知用户', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(_formatReportTime(report.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (report.attachments.isNotEmpty)
                      Icon(Icons.photo_library, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Icon(Icons.location_on, size: 16, color: Colors.blue),
                  ],
                ),
                Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
            SizedBox(height: 12),
            if (report.content.isNotEmpty)
              Text(
                  report.content.length > 100
                      ? '${report.content.substring(0, 100)}...'
                      : report.content,
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666))
              ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                      report.address.length > 50
                          ? '${report.address.substring(0, 50)}...'
                          : report.address,
                      style: TextStyle(fontSize: 12, color: Colors.grey)
                  ),
                ),
              ],
            ),
            if (report.attachments.isNotEmpty) ...[
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text('${report.attachments.length}个附件', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.blue[50],
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCollaborators() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('任务分配', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            SizedBox(width: 8),
            if (_isLoadingAssignment)
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        SizedBox(height: 12),

        if (_isLoadingAssignment)
          Center(child: CircularProgressIndicator())
        else if (_taskAssigner == null && _taskAssignees.isEmpty)
          Text('暂无分配信息', style: TextStyle(color: Color(0xFF666666)))
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 显示指派人
              if (_taskAssigner != null) ...[
                _buildAssignmentSection('指派人', [_taskAssigner!]),
                SizedBox(height: 16),
              ],

              // 显示被指派人
              if (_taskAssignees.isNotEmpty)
                _buildAssignmentSection('被指派人', _taskAssignees),
            ],
          ),
      ],
    );
  }

  Widget _buildAssignmentSection(String title, List<TaskUser> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: users.map((user) => Chip(
            label: Text(
              user.name,
              style: TextStyle(fontSize: 12),
            ),
            avatar: CircleAvatar(
              backgroundColor: title == '指派人' ? Color(0xFFFF8C42) : Colors.blue[100],
              radius: 12,
              child: Text(
                user.name.isNotEmpty ? user.name[0] : '?',
                style: TextStyle(
                  fontSize: 10,
                  color: title == '指派人' ? Colors.white : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 2,
            side: BorderSide(
              color: title == '指派人' ? Color(0xFFFF8C42).withOpacity(0.3) : Colors.blue.withOpacity(0.3),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildTaskInfo(Task loadedTask, Map<String, dynamic> dynamicProperties) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFFF8C42), Color(0xFFFF6B9D)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(dynamicProperties['emoji'], style: TextStyle(fontSize: 24))),
                ),
                SizedBox(width: 12),
                Expanded(child: Text(loadedTask.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
              ],
            ),
            SizedBox(height: 12),
            Text(loadedTask.description, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), height: 1.5)),
            SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(_getStatusText(loadedTask.status), style: TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: _getStatusColor(loadedTask.status),
                ),
                SizedBox(width: 8),
                Expanded(child: Text('当前状态: ${_getStatusDescription(loadedTask.status)}', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)))),
              ],
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: dynamicProperties['progress'],
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 8),
            Text('进度: ${(dynamicProperties['progress'] * 100).toInt()}%', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }

  // 处理报告相关操作 - 添加缺失的 _handleReport 方法
  Future<void> _handleReport(Task loadedTask) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskReportView(
          task: loadedTask,
          onReportSubmitted: _refreshData,
        ),
      ),
    );

    if (result == true) {
      await _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('工作报告提交成功，任务状态已更新')),
      );
    }
  }

  // 在 TaskDetailView 中优化批阅方法 - 只保留一个定义
// 在 TaskDetailView 中优化审批方法
  Future<void> _handleApproveReport(Task task) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('确认通过报告'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('确定要通过这个工作报告吗？'),
              SizedBox(height: 8),
              Text(
                '通过后：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 任务状态将更新为"已完成"'),
              Text('• 任务进度将达到100%'),
              Text('• 任务将标记为完成状态'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('确定通过'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        setState(() {
          _isLoadingReports = true;
        });

        await TaskService.approveTaskReport(task.taskId);
        await _refreshData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('报告已通过，任务标记为完成状态'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ 审批报告失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('操作失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReports = false;
        });
      }
    }
  }

  Future<void> _handleRejectReport(Task task) async {
    try {
      final reason = await showDialog<String>(
        context: context,
        builder: (context) => RejectReasonDialog(),
      );

      if (reason != null) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('确认拒绝报告'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('确定要拒绝这个工作报告吗？'),
                if (reason.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text('拒绝原因:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(reason, style: TextStyle(color: Colors.red)),
                ],
                SizedBox(height: 8),
                Text(
                  '拒绝后：',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• 任务状态将返回"已发布"'),
                Text('• 执行人可以重新提交报告'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('确定拒绝'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          setState(() {
            _isLoadingReports = true;
          });

          await TaskService.rejectTaskReport(task.taskId);
          await _refreshData();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('报告已拒绝，任务返回待提交状态${reason.isNotEmpty ? '，原因: $reason' : ''}'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ 拒绝报告失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('操作失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReports = false;
        });
      }
    }
  }
  // 辅助方法
  double _calculateProgress(Task task) {
    switch (task.status) {
      case TaskStatus.published: return 0.33;
      case TaskStatus.reported: return 0.66;
      case TaskStatus.completed: return 1.0;
      case TaskStatus.closed: return 1.0;
      default: return 0.0;
    }
  }

  String _formatReportTime(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.published: return '已发布';
      case TaskStatus.reported: return '报告已提交';
      case TaskStatus.completed: return '已完成';
      case TaskStatus.closed: return '已关闭';
      default: return '未知';
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.published: return Color(0xFFFF8C42);
      case TaskStatus.reported: return Colors.purple;
      case TaskStatus.completed: return Color(0xFF88D8B0);
      case TaskStatus.closed: return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _getStatusDescription(TaskStatus status) {
    switch (status) {
      case TaskStatus.published: return '任务已发布，等待提交报告';
      case TaskStatus.reported: return '已提交报告，等待审核';
      case TaskStatus.completed: return '任务已完成';
      case TaskStatus.closed: return '任务已关闭';
      default: return '未知状态';
    }
  }

  // 其他UI组件（_buildTaskDetailsList, _buildSubtasks, _buildTaskLogsList）保持不变...
  Widget _buildTaskDetailsList(Task loadedTask) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('任务详情', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
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
                    iconColor: Color(0xFF4ECDC4)
                ),
                Divider(height: 1),
                _buildDetailRow(
                    icon: Icons.person_add,
                    title: '指派人',
                    value: _taskAssigner?.name ?? '未指定',
                    iconColor: Color(0xFFFF8C42)
                ),
                Divider(height: 1),
                _buildDetailRow(
                    icon: Icons.people_outline,
                    title: '被指派人',
                    value: _taskAssignees.isEmpty ? '无' : '${_taskAssignees.length}人',
                    iconColor: Colors.blue
                ),
                Divider(height: 1),
                _buildDetailRow(
                    icon: Icons.flag_outlined,
                    title: '优先级',
                    value: loadedTask.priority.sqlValue,
                    iconColor: Color(0xFFFF6B9D)
                ),
                Divider(height: 1),
                _buildDetailRow(
                    icon: Icons.play_arrow_outlined,
                    title: '开始时间',
                    value: _formatTaskDate(loadedTask.startAt),
                    iconColor: Color(0xFF88D8B0)
                ),
                Divider(height: 1),
                _buildDetailRow(
                    icon: Icons.timer_outlined,
                    title: '截止时间',
                    value: _formatTaskDate(loadedTask.dueAt),
                    iconColor: Color(0xFFFF8C42)
                ),
                Divider(height: 1),
                _buildDetailRow(
                    icon: Icons.add_circle_outline,
                    title: '创建时间',
                    value: _formatTaskDate(loadedTask.createdAt),
                    iconColor: Color(0xFF999999)
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({required IconData icon, required String title, required String value, required Color iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(title, style: TextStyle(fontSize: 15, color: Color(0xFF666666))),
      trailing: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF333333))),
      dense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
    );
  }

  String _formatTaskDate(DateTime? date) {
    if (date == null) return '未设置';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSubtasks(Task loadedTask, Map<String, dynamic> dynamicProperties, Role currentUserRole) {
    List<dynamic> subtasks = dynamicProperties['subtasks'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('子任务', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        SizedBox(height: 12),
        if (subtasks.isEmpty)
          Text('暂无子任务', style: TextStyle(color: Color(0xFF666666)))
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
                            Text(subtask['title'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                            SizedBox(height: 4),
                            Text('分配给: ${subtask['assignedTo']}', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(subtask['completed'] ? '已完成' : '未完成', style: TextStyle(color: Colors.white, fontSize: 12)),
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

  Widget _buildTaskLogsList(List<TaskRelatedLog> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('相关日志', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        SizedBox(height: 12),
        if (logs.isEmpty)
          Text('当前任务还没有关联的日志', style: TextStyle(color: Color(0xFF666666)))
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
                title: Text(relatedLog.title.isNotEmpty ? relatedLog.title : '日志 ${relatedLog.logId}', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('ID: ${relatedLog.logId}', style: TextStyle(color: Color(0xFF666666))),
                trailing: Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LogDetailView(logId: relatedLog.logId)),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}