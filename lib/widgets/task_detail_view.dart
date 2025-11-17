import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../models/task.dart';
import '../models/task_report.dart';
import '../models/role.dart';
import '../models/task_user.dart';
import '../models/log.dart';
import 'subtask_detail_view.dart';
import 'log_view_detail.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

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
  bool _isLoadingReports = false;
  bool _isLoadingAssignees = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {

    try {
      // 先设置加载状态
      if (mounted) {
        setState(() {
          _isLoadingReports = true;
          _isLoadingAssignees = true;
        });
      }

      // 并行加载所有数据
      _dataFuture = _loadData();
      await Future.wait([
        _loadTaskReports(),
        _loadTaskAssignees(),
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

  // 加载任务指派者
  Future<void> _loadTaskAssignees() async {
    if (mounted) {
      setState(() {
        _isLoadingAssignees = true;
      });
    }

    try {
      final assignees = await TaskService.fetchTaskAssigneesList(widget.taskId);

      if (mounted) {
        setState(() {
          _taskAssignees = assignees;
          _isLoadingAssignees = false;
        });
      }
    } catch (e) {
      print('加载任务指派者失败: $e');
      if (mounted) {
        setState(() {
          _taskAssignees = [];
          _isLoadingAssignees = false;
        });
      }
    }
  }


  Role _extractUserRole(Map<String, dynamic> profile) {
    final user = profile['user'] as Map<String, dynamic>? ?? {};
    final roleId = int.tryParse(user['role_id']?.toString() ?? '') ?? 0;
    final roleName = user['role_name']?.toString() ?? '未知角色';
    final roleDesc = user['role_desc']?.toString();
    return Role(roleId: roleId, name: roleName, description: roleDesc);
  }

  // 加载任务报告
  Future<void> _loadTaskReports() async {
    if (mounted) {
      setState(() {
        _isLoadingReports = true;
      });
    }

    try {
      final reports = await TaskService.fetchTaskReports(widget.taskId);

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

  // 刷新所有数据
  Future<void> _refreshData() async {
    setState(() {
      _dataFuture = _loadData();
      _isLoadingReports = true;
      _isLoadingAssignees = true;
    });
    await Future.wait([
      _loadTaskReports(),
      _loadTaskAssignees(),
    ]);
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

          if (_dataFuture == null) {
            return Center(child: CircularProgressIndicator());
          }

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
                    // 显示报告相关部分
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

  // 计算任务进度
  double _calculateProgress(Task task) {
    switch (task.status) {
      case TaskStatus.published:
        return 0.33;
      case TaskStatus.reported:
        return 0.66;
      case TaskStatus.completed:
        return 1.0;
      case TaskStatus.closed:
        return 1.0;
      default:
        return 0.0;
    }
  }

  // 报告部分显示逻辑
  Widget _buildReportSection(Task task, Role currentUserRole, String currentUserId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 报告信息显示
        _buildReportInfo(),

        SizedBox(height: 16),

        // 操作按钮区域
        if (task.status == TaskStatus.published && _canSubmitReport(currentUserRole, task, currentUserId))
          _buildSubmitReportButton(task),

        if (task.status == TaskStatus.reported && _canApproveReport(task, currentUserRole, currentUserId))
          _buildApproveRejectButtons(task),
      ],
    );
  }

  // 检查用户是否可以提交报告
  bool _canSubmitReport(Role role, Task task, String currentUserId) {
    // 只有任务执行者可以提交报告
    return _taskAssignees.any((assignee) => assignee.userId == currentUserId);
  }

  // 检查用户是否可以审批报告
  bool _canApproveReport(Task task, Role currentUserRole, String currentUserId) {
    // 只有任务创建者或管理员可以审批报告
    return task.creator?.userId == currentUserId ||
        currentUserRole.roleId == 5; // 假设1是管理员角色ID
  }

  // 提交报告按钮
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

  // 审批拒绝按钮
  Widget _buildApproveRejectButtons(Task task) {
    return Row(
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
    );
  }

  // 报告信息查看组件
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
                Icon(Icons.assignment_outlined,
                    size: 48, color: Colors.grey[400]),
                SizedBox(height: 8),
                Text(
                  '暂无工作报告',
                  style: TextStyle(color: Color(0xFF666666)),
                ),
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

  // 单个报告信息项
  Widget _buildReportItem(TaskReport report) {
    return Container(
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
          // 报告头部信息
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[100],
                child: Text(
                  report.reporterName?.isNotEmpty == true
                      ? report.reporterName![0]
                      : 'U',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.reporterName ?? '未知用户',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _formatReportTime(report.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
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
            ],
          ),

          SizedBox(height: 12),

          // 报告内容
          if (report.content.isNotEmpty)
            Text(
              report.content,
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),

          SizedBox(height: 8),

          // 位置信息
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.address,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),

          // 附件显示 - 修复空指针问题
          if (report.attachments.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              '附件 (${report.attachments.length})',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: report.attachments
                  .where((attachment) => attachment != null && attachment.isNotEmpty)
                  .map((attachment) {
                final fileName = _getFileName(attachment);
                final isImage = _isImageFile(attachment);

                return Chip(
                  label: Text(
                    fileName.length > 10
                        ? '${fileName.substring(0, 10)}...'
                        : fileName,
                    style: TextStyle(fontSize: 10),
                  ),
                  avatar: isImage
                      ? Icon(Icons.photo, size: 16)
                      : Icon(Icons.attach_file, size: 16),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // 协作成员显示
  Widget _buildCollaborators() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '协作成员',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            SizedBox(width: 8),
            if (_isLoadingAssignees)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        SizedBox(height: 12),
        if (_isLoadingAssignees)
          Center(child: CircularProgressIndicator())
        else if (_taskAssignees.isEmpty)
          Text(
            '暂无协作成员',
            style: TextStyle(color: Color(0xFF666666)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _taskAssignees.map((assignee) => Chip(
              label: Text(assignee.name, style: TextStyle(fontSize: 12)),
              avatar: CircleAvatar(
                child: Text(assignee.name.isNotEmpty ? assignee.name[0] : '?'),
                backgroundColor: Colors.blue[100],
              ),
              backgroundColor: Colors.white,
              elevation: 2,
            )).toList(),
          ),
      ],
    );
  }

  // 格式化报告时间
  String _formatReportTime(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
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

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.published:
        return '已发布';
      case TaskStatus.reported:
        return '报告已提交';
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

// 处理提交报告 - 支持多平台文件选择
  Future<void> _handleReport(Task loadedTask) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        File? selectedFile;
        Position? currentPosition;
        String? locationAddress;
        final contentController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            // 创建本地变量来处理文件
            final fileForDisplay = selectedFile;
            final filePath = selectedFile?.path;

            return AlertDialog(
              title: Text('提交工作报告'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 文件选择部分
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.attach_file, color: selectedFile != null ? Colors.green : Colors.grey),
                              SizedBox(width: 8),
                              Text('1. 选择附件', style: TextStyle(fontWeight: FontWeight.w500)),
                              Spacer(),
                              if (selectedFile != null)
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                            ],
                          ),
                          SizedBox(height: 8),
                          if (fileForDisplay != null && filePath != null)
                            Column(
                              children: [
                                // 如果是图片，显示预览
                                if (_isImageFile(filePath))
                                  Image.file(fileForDisplay, height: 100, width: 100, fit: BoxFit.cover),
                                SizedBox(height: 8),
                                Text(
                                  '已选择: ${_getFileName(filePath)}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final newFile = await _selectFile();
                                        if (newFile != null) {
                                          setDialogState(() {
                                            selectedFile = newFile;
                                          });
                                        }
                                      },
                                      icon: Icon(Icons.change_circle, size: 16),
                                      label: Text('更换'),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        setDialogState(() {
                                          selectedFile = null;
                                        });
                                      },
                                      icon: Icon(Icons.delete, size: 16, color: Colors.red),
                                      label: Text('移除', style: TextStyle(color: Colors.red)),
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        side: BorderSide(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () async {
                                final file = await _selectFile();
                                if (file != null) {
                                  setDialogState(() {
                                    selectedFile = file;
                                  });
                                }
                              },
                              icon: Icon(Icons.attach_file),
                              label: Text('选择文件'),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    // 位置获取部分
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: currentPosition != null ? Colors.green : Colors.grey),
                              SizedBox(width: 8),
                              Text('2. 获取位置', style: TextStyle(fontWeight: FontWeight.w500)),
                              Spacer(),
                              if (currentPosition != null)
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                            ],
                          ),
                          SizedBox(height: 8),
                          if (currentPosition != null)
                            Text(
                              locationAddress ?? '${currentPosition!.latitude.toStringAsFixed(4)}, ${currentPosition!.longitude.toStringAsFixed(4)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () async {
                                await _getCurrentLocation(setDialogState, (position, address) {
                                  setDialogState(() {
                                    currentPosition = position;
                                    locationAddress = address;
                                  });
                                });
                              },
                              icon: Icon(Icons.location_on),
                              label: Text('获取位置'),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    // 内容输入部分
                    TextField(
                      controller: contentController,
                      decoration: InputDecoration(
                        labelText: '工作内容',
                        border: OutlineInputBorder(),
                        hintText: '请输入今天完成的工作内容...',
                      ),
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('取消'),
                ),
                ElevatedButton(
                  onPressed: (currentPosition != null && contentController.text.isNotEmpty)
                      ? () async {
                    try {
                      // 调用提交报告API
                      await TaskService.createTaskReport(
                        taskId: loadedTask.taskId,
                        file: selectedFile,
                        location: currentPosition!,
                        content: contentController.text,
                        address: locationAddress,
                      );

                      // 更新任务状态为 reported
                      await TaskService.updateTaskStatus(loadedTask.taskId, TaskStatus.reported);

                      Navigator.pop(context, true);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('提交报告失败: $e')),
                      );
                      Navigator.pop(context, false);
                    }
                  }
                      : null,
                  child: Text('提交报告'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      // 提交报告成功，刷新数据
      await _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('工作报告提交成功，任务状态已更新')),
      );
    }
  }

  // 选择文件的方法 - 支持多平台
  Future<File?> _selectFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? selectedXFile = await picker.pickImage(
        source: ImageSource.gallery, // 使用图库，兼容所有平台
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (selectedXFile != null && selectedXFile.path.isNotEmpty) {
        return File(selectedXFile.path);
      }
      return null;
    } catch (e) {
      print('选择文件失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择文件失败: ${e.toString()}')),
      );
      return null;
    }
  }

  // 检查文件是否为图片 - 添加空值检查
  bool _isImageFile(String? filePath) {
    if (filePath == null || filePath.isEmpty) return false;
    final extension = filePath.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  // 获取文件名 - 添加空值检查
  String _getFileName(String? filePath) {
    if (filePath == null || filePath.isEmpty) return '未知文件';
    return filePath.split('/').last;
  }

  // 获取当前位置的方法
  Future<void> _getCurrentLocation(StateSetter setDialogState, Function(Position, String) onSuccess) async {
    try {
      // 显示加载状态
      setDialogState(() {
        // 可以在这里设置加载状态，比如显示"正在获取位置..."
      });

      // 1. 检查位置权限
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请在系统设置中授予位置权限')),
        );
        return;
      }

      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('需要位置权限才能获取详细地址')),
        );
        return;
      }

      // 2. 获取设备真实位置
      print('📍 开始获取设备位置...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best, // 最高精度
      );

      print('✅ 获取到设备坐标: ${position.latitude}, ${position.longitude}');
      print('📱 位置来源: ${position.accuracy}');
      print('⏰ 定位时间: ${position.timestamp}');

      // 3. 使用腾讯位置服务获取详细地址
      print('🗺️ 开始获取详细地址...');
      String address = await TaskService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      print('🎯 最终地址: $address');

      // 4. 返回结果
      onSuccess(position, address);

    } catch (e) {
      print('❌ 定位过程失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取位置失败: $e')),
      );
    }
  }

  // 处理审批报告
  Future<void> _handleApproveReport(Task task) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('确认通过'),
          content: Text('确定要通过这个工作报告吗？通过后任务将标记为完成。'),
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
        await TaskService.approveTaskReport(task.taskId);
        await _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('报告已通过，任务标记为完成')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e')),
      );
    }
  }

  // 处理拒绝报告
  Future<void> _handleRejectReport(Task task) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('确认拒绝'),
          content: Text('确定要拒绝这个工作报告吗？拒绝后任务将返回待提交状态。'),
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
        await TaskService.rejectTaskReport(task.taskId);
        await _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('报告已拒绝，任务返回待提交状态')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e')),
      );
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