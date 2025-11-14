import 'package:flutter/material.dart';
import '../models/log.dart';
import 'subtask_detail_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../models/task.dart';
import '../models/task_report.dart';
import '../models/role.dart';
import 'log_view_detail.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';

class TaskDetailView extends StatefulWidget {
  final String taskId;
  final Role userRole;
  final Function(Task) onTaskUpdated;
  final String currentUserId;

  TaskDetailView({
    required this.taskId,
    required this.userRole,
    required this.onTaskUpdated,
    required this.currentUserId,
  });

  @override
  _TaskDetailViewState createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  late Future<Task> _taskFuture;
  List<TaskReport> _taskReports = [];
  bool _isLoadingReports = false;
  // 任务分配人员相关状态
  Map<String, dynamic>? _taskAssignees;
  bool _isLoadingAssignees = false;

  @override
  void initState() {
    super.initState();
    _taskFuture = TaskService.fetchTaskById(widget.taskId);
    Future.microtask(() => _loadTaskReports());
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
      _taskFuture = TaskService.fetchTaskById(widget.taskId);
      _isLoadingReports = true;
    });
    await _loadTaskReports();
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
      body: FutureBuilder<Task>(
        future: _taskFuture,
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
            final Task loadedTask = snapshot.data!;

            final Map<String, dynamic> _dynamicProperties = {
              'emoji': '📝',
              'progress': _calculateProgress(loadedTask),
              'log': '暂无日志',
              'assignedTo': loadedTask.creator?.userId ?? '未知',
              'subtasks': [],
              'collaborators': ['N/A'],
            };

            return RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTaskInfo(loadedTask, _dynamicProperties),
                    SizedBox(height: 20),
                    _buildTaskDetailsList(loadedTask),
                    SizedBox(height: 20),
                    _buildSubtasks(loadedTask, _dynamicProperties),
                    SizedBox(height: 20),
                    _buildCollaborators(_dynamicProperties),
                    SizedBox(height: 20),
                    _buildTaskLog(loadedTask, _dynamicProperties),
                    SizedBox(height: 20),
                    // 显示报告相关部分
                    _buildReportSection(loadedTask),
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

  // 报告部分显示逻辑
  Widget _buildReportSection(Task task) {
    if (task.status == TaskStatus.published) {
      // 任务发布状态 - 显示提交报告按钮
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
    } else {
      // 其他状态 - 显示报告信息
      return _buildReportInfo();
    }
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                _formatReportTime(report.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Spacer(),
              if (report.attachments.isNotEmpty)
                Icon(Icons.photo_camera, size: 16, color: Colors.green),
              SizedBox(width: 4),
              Icon(Icons.location_on, size: 16, color: Colors.blue),
            ],
          ),
          SizedBox(height: 8),
          if (report.content.isNotEmpty)
            Text(
              report.content,
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
          SizedBox(height: 4),
          Text(
            '位置: ${report.address}',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (report.attachments.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              '附件: ${report.attachments.length} 个文件',
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
        ],
      ),
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

  Widget _buildTaskLog(Task loadedTask, Map<String, dynamic> dynamicProperties) {
    final String logContent = dynamicProperties['log'] ?? '暂无日志';
    final String logUserId = loadedTask.creator?.userId.toString() ?? widget.currentUserId;

    final Log placeholderLog = Log(
      logId: '0',
      userId: logUserId,
      logDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      todaySummary: logContent,
      tomorrowPlan: null,
      helpNeeded: null,
      status: '待审批',
      tags: ['任务', '汇报'],
      taskIds: [loadedTask.taskId],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '任务日志',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LogDetailView(
                  log: placeholderLog,
                ),
              ),
            );
          },
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                logContent,
                style: TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.5),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtasks(Task loadedTask, Map<String, dynamic> dynamicProperties) {
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
                        userRole: widget.userRole,
                        onSubtaskUpdated: (updatedSubtask) {
                          setState(() {
                            _taskFuture = TaskService.fetchTaskById(widget.taskId);
                            widget.onTaskUpdated(loadedTask);
                          });
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

  // 处理提交报告
  Future<void> _handleReport(Task loadedTask) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        File? capturedImage;
        Position? currentPosition;
        String? locationAddress;
        final contentController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('提交工作报告'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                              Icon(Icons.camera_alt, color: capturedImage != null ? Colors.green : Colors.grey),
                              SizedBox(width: 8),
                              Text('1. 拍照附件', style: TextStyle(fontWeight: FontWeight.w500)),
                              Spacer(),
                              if (capturedImage != null)
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                            ],
                          ),
                          SizedBox(height: 8),
                          if (capturedImage != null)
                            Image.file(capturedImage!, height: 100)
                          else
                            ElevatedButton.icon(
                              onPressed: () async {
                                final ImagePicker picker = ImagePicker();
                                final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                                if (photo != null) {
                                  setDialogState(() {
                                    capturedImage = File(photo.path);
                                  });
                                }
                              },
                              icon: Icon(Icons.camera_alt),
                              label: Text('拍照'),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
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
                                try {
                                  LocationPermission permission = await Geolocator.checkPermission();
                                  if (permission == LocationPermission.denied) {
                                    permission = await Geolocator.requestPermission();
                                  }
                                  if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
                                    Position position = await Geolocator.getCurrentPosition();
                                    setDialogState(() {
                                      currentPosition = position;
                                      locationAddress = '北京市朝阳区';
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('请授予位置权限')),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('定位失败: $e')),
                                  );
                                }
                              },
                              icon: Icon(Icons.location_on),
                              label: Text('获取位置'),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
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
                        photo: capturedImage,
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