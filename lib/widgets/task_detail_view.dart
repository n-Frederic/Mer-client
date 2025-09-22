import 'package:flutter/material.dart';
import 'subtask_detail_view.dart'; // 新建子任务详情页
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'enums.dart';

class TaskDetailView extends StatefulWidget {
  final Map<String, dynamic> task;
  final UserRole userRole;
  final String currentUserId;
  final Function(Map<String, dynamic>) onTaskUpdated;

  TaskDetailView({
    required this.task,
    required this.userRole,
    required this.currentUserId,
    required this.onTaskUpdated,
  });

  @override
  _TaskDetailViewState createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  late Map<String, dynamic> _currentTask;

  @override
  void initState() {
    super.initState();
    _currentTask = Map<String, dynamic>.from(widget.task);
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskInfo(),
            SizedBox(height: 20),
            _buildSubtasks(),
            SizedBox(height: 20),
            _buildCollaborators(),
            SizedBox(height: 20),
            _buildTaskLog(),
            SizedBox(height: 20),
            if (_currentTask['requiresLocationCheckIn'] && _currentTask['requiresPhotoCheckIn'] &&
                (_currentTask['assignedTo'] == widget.currentUserId || widget.userRole == UserRole.teamLeader))
              Center(
                child: ElevatedButton(
                  onPressed: _handleCheckIn,
                  child: Text('任务打卡'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskInfo() {
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
                  child: Center(child: Text(_currentTask['emoji'], style: TextStyle(fontSize: 24))),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _currentTask['title'],
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
              _currentTask['description'],
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), height: 1.5),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(_currentTask['type'], style: TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
                SizedBox(width: 8),
                Chip(
                  label: Text(
                    _getStatusText(_currentTask['status']),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: _getStatusColor(_currentTask['status']),
                ),
              ],
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: _currentTask['progress'],
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              '进度: ${(_currentTask['progress'] * 100).toInt()}%',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtasks() {
    List<dynamic> subtasks = _currentTask['subtasks'] ?? [];
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
                        currentUserId: widget.currentUserId,
                        onSubtaskUpdated: (updatedSubtask) {
                          setState(() {
                            subtasks[index] = updatedSubtask;
                            int completedCount = subtasks.where((s) => s['completed']).length;
                            _currentTask['progress'] = subtasks.isNotEmpty ? completedCount / subtasks.length : 0.0;
                            widget.onTaskUpdated(_currentTask);
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

  Widget _buildCollaborators() {
    List<String> collaborators = _currentTask['collaborators'] ?? [];
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

  Widget _buildTaskLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '任务日志',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: Text(
            _currentTask['log'] ?? '暂无日志',
            style: TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.5),
          ),
        ),
      ],
    );
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return '待开始';
      case TaskStatus.inProgress:
        return '进行中';
      case TaskStatus.completed:
        return '已完成';
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Color(0xFFFFE66D);
      case TaskStatus.inProgress:
        return Color(0xFF4ECDC4);
      case TaskStatus.completed:
        return Color(0xFF88D8B0);
    }
  }

  Future<void> _handleCheckIn() async {
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
              title: Text('任务打卡'),
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
                                      locationAddress = '北京市朝阳区'; // 模拟地址
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
                          setState(() {
                            _currentTask['checkIns'].add({
                              'userId': widget.currentUserId,
                              'timestamp': DateTime.now(),
                              'photo': capturedImage!.path,
                              'location': locationAddress ?? '${currentPosition!.latitude}, ${currentPosition!.longitude}',
                              'note': noteController.text.isNotEmpty ? noteController.text : '任务打卡'
                            });
                            widget.onTaskUpdated(_currentTask);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('打卡成功')),
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
}