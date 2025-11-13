import 'package:flutter/material.dart';
import '../models/log.dart';
import 'subtask_detail_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../models/task.dart';
import '../models/role.dart';
import 'log_view_detail.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';


class TaskDetailView extends StatefulWidget {
  final String taskId;
  final Role userRole;
  final Function(Task) onTaskUpdated;
  final String currentUserId; // 【新增】当前登录用户ID

  TaskDetailView({
    required this.taskId,
    required this.userRole,
    required this.onTaskUpdated,
    required this.currentUserId, // 【新增】
  });

  @override
  _TaskDetailViewState createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  late Future<Task> _taskFuture;

  @override
  void initState() {
    super.initState();
    _taskFuture = TaskService.fetchTaskById(widget.taskId);
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

            // 在 build 方法内部定义占位符
            final Map<String, dynamic> _dynamicProperties = {
              'emoji': '📝',
              'progress': 0.0,
              'log': '暂无日志',
              'assignedTo': loadedTask.creator?.userId??'未知',
              'subtasks': [],
              'checkIns': [],
              'collaborators': ['N/A'],
            };

            return SingleChildScrollView(
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
                  // 【修改】移除 currentUserId 检查，使用其他方式判断是否可以写日志
                  if (_canWriteLog(loadedTask))
                    Center(
                      child: ElevatedButton(
                        onPressed: () => _handleCheckIn(loadedTask),
                        child: Text('写日志'),
                      ),
                    ),
                ],
              ),
            );
          }

          return Center(child: Text('未知状态'));
        },
      ),
    );
  }

  // 【新增】判断是否可以写日志的方法
  bool _canWriteLog(Task task) {
    // 这里可以根据任务状态、用户角色等逻辑来判断
    // 例如：只有进行中、已分配状态的任务可以写日志
    return task.status == TaskStatus.inProgress ||
        task.status == TaskStatus.assigned;
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
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                Chip(
                  label: Text(
                    _getStatusText(loadedTask.status),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: _getStatusColor(loadedTask.status),
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

   Widget _buildTaskLog(Task loadedTask, Map<String, dynamic> dynamicProperties) {
    // 1. 获取核心内容 (保持不变)
    final String logContent = dynamicProperties['log'] ?? '暂无日志';

    // 2. 【修正】创建 Log 对象，使用 currentUserId 作为回退
    // 如果 creator 为 null，使用当前登录用户ID
    final String logUserId = loadedTask.creator?.userId ?? widget.currentUserId;
    
    // taskId 已经是 String 类型，不需要 toString()
    final Log placeholderLog = Log(
      logId: '0',
      userId: logUserId, // 【修正】使用回退逻辑
      logDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      todaySummary: logContent,
      tomorrowPlan: null,
      helpNeeded: null,
      status: '待审批',
      tags: ['任务', '汇报'],
      taskIds: [loadedTask.taskId], relatedTasks: [],
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
                        // 【修改】移除 currentUserId 参数
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
        return '已汇报';
      case TaskStatus.completed:
        return '已完成';
      case TaskStatus.closed:
        return '已关闭';
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.published:
        return Color(0xFF999999);
      case TaskStatus.assigned:
        return Color(0xFFFF8C42);
      case TaskStatus.inProgress:
        return Color(0xFF4ECDC4);
      case TaskStatus.reported:
        return Colors.purple;
      case TaskStatus.completed:
        return Color(0xFF88D8B0);
      case TaskStatus.closed:
        return Colors.black45;
    }
  }

  Future<void> _handleCheckIn(Task loadedTask) async {
    showDialog(
      context: context,
      builder: (context) {
        File? capturedImage;
        Position? currentPosition;
        String? locationAddress;
        final noteController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('写日志'),
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
                              Text('1. 拍照 *', style: TextStyle(fontWeight: FontWeight.w500)),
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
                              Text('2. 获取位置 *', style: TextStyle(fontWeight: FontWeight.w500)),
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
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: '备注',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('取消'),
                ),
                ElevatedButton(
                  onPressed: (capturedImage != null && currentPosition != null)
                      ? () {
                    Navigator.pop(context);

                    // TODO: 在这里调用 API (例如 TaskService.createCheckIn(...))
                    setState(() {
                      _taskFuture = TaskService.fetchTaskById(widget.taskId);
                      widget.onTaskUpdated(loadedTask);
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('日志记录成功，正在刷新...')),
                    );
                  }
                      : null,
                  child: Text('完成打卡'),
                ),
              ],
            );
          },
        );
      },
    );
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
                  value: loadedTask.creator?.name??'未知',
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