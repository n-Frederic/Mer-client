import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../models/task.dart';
import '../services/task_report_service.dart';
import '../services/task_service.dart';

class TaskReportView extends StatefulWidget {
  final Task task;
  final Function()? onReportSubmitted;

  const TaskReportView({
    Key? key,
    required this.task,
    this.onReportSubmitted,
  }) : super(key: key);

  @override
  _TaskReportViewState createState() => _TaskReportViewState();
}

class _TaskReportViewState extends State<TaskReportView> {
  List<File> _selectedFiles = []; // 改为列表存储多个文件
  Position? _currentPosition;
  String? _locationAddress;
  final TextEditingController _contentController = TextEditingController();
  bool _isSubmitting = false;
  bool _isGettingLocation = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('提交工作报告'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTaskInfo(),
              SizedBox(height: 20),
              _buildFileSelection(),
              SizedBox(height: 16),
              _buildLocationSelection(),
              SizedBox(height: 16),
              _buildContentInput(),
              SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '任务信息',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            SizedBox(height: 8),
            Text(
              widget.task.title,
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            SizedBox(height: 4),
            Text(
              widget.task.description,
              style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file,
                  color: _selectedFiles.isNotEmpty ? Colors.green : Colors.grey),
              SizedBox(width: 8),
              Text('选择附件', style: TextStyle(fontWeight: FontWeight.w500)),
              Spacer(),
              if (_selectedFiles.isNotEmpty)
                Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          SizedBox(height: 12),

          // 显示已选择的文件列表
          if (_selectedFiles.isNotEmpty)
            Column(
              children: [
                ..._selectedFiles.asMap().entries.map((entry) {
                  int index = entry.key;
                  File file = entry.value;
                  return _buildFileItem(file, index);
                }).toList(),
                SizedBox(height: 8),
              ],
            ),

          // 选择文件按钮
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectFiles,
                  icon: Icon(Icons.add_photo_alternate),
                  label: Text('添加文件'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue,
                  ),
                ),
              ),
              if (_selectedFiles.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedFiles.clear();
                      });
                    },
                    icon: Icon(Icons.clear_all, size: 16, color: Colors.red),
                    label: Text('清空全部', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      side: BorderSide(color: Colors.red),
                    ),
                  ),
                ),
            ],
          ),

          // 提示信息
          if (_selectedFiles.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '可选，最多可上传5个文件',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileItem(File file, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 文件预览
          if (_isImageFile(file.path))
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: FileImage(file),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.insert_drive_file, color: Colors.grey[600]),
            ),

          SizedBox(width: 12),

          // 文件信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getFileName(file.path),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  '${_getFileSize(file)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // 删除按钮
          IconButton(
            onPressed: () {
              setState(() {
                _selectedFiles.removeAt(index);
              });
            },
            icon: Icon(Icons.delete, size: 18, color: Colors.red),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on,
                  color: _currentPosition != null ? Colors.green : Colors.grey),
              SizedBox(width: 8),
              Text('获取位置', style: TextStyle(fontWeight: FontWeight.w500)),
              Spacer(),
              if (_currentPosition != null)
                Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          SizedBox(height: 12),
          if (_currentPosition != null && _locationAddress != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.place, size: 16, color: Colors.green),
                          SizedBox(width: 4),
                          Text('当前位置:', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        _locationAddress!,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '坐标: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            )
          else
            _isGettingLocation
                ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('正在获取位置...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            )
                : ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: Icon(Icons.location_searching),
              label: Text('获取当前位置'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '工作内容',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF333333)),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _contentController,
          decoration: InputDecoration(
            hintText: '请输入今天完成的工作内容...',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(16),
          ),
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_currentPosition != null &&
            _contentController.text.isNotEmpty &&
            !_isSubmitting)
            ? _submitReport
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFF8C42),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Text('提交中...'),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in, size: 20),
            SizedBox(width: 8),
            Text('提交工作报告', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFiles() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> selectedXFiles = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (selectedXFiles.isNotEmpty) {
        // 检查文件数量限制
        if (_selectedFiles.length + selectedXFiles.length > 5) {
          _showError('最多只能上传5个文件');
          return;
        }

        setState(() {
          _selectedFiles.addAll(selectedXFiles.map((xfile) => File(xfile.path)).toList());
        });
      }
    } catch (e) {
      _showError('选择文件失败: ${e.toString()}');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('请在系统设置中授予位置权限');
        return;
      }

      if (permission == LocationPermission.denied) {
        _showError('需要位置权限才能获取详细地址');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      String address = await TaskReportService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentPosition = position;
        _locationAddress = address;
        _isGettingLocation = false;
      });

    } catch (e) {
      setState(() {
        _isGettingLocation = false;
      });
      _showError('获取位置失败: $e');
    }
  }

  Future<void> _submitReport() async {
    if (_currentPosition == null || _contentController.text.isEmpty) {
      _showError('请填写工作内容并获取位置');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await TaskReportService.createTaskReport(
        taskId: widget.task.taskId,
        files: _selectedFiles, // 传递文件列表
        location: _currentPosition!,
        content: _contentController.text,
        address: _locationAddress,
      );

      await TaskService.updateTaskStatus(widget.task.taskId, TaskStatus.reported);

      if (widget.onReportSubmitted != null) {
        widget.onReportSubmitted!();
      }

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('工作报告提交成功，任务状态已更新')),
      );
    } catch (e) {
      _showError('提交报告失败: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  bool _isImageFile(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }

  String _getFileSize(File file) {
    final sizeInBytes = file.lengthSync();
    if (sizeInBytes < 1024) {
      return '${sizeInBytes}B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}