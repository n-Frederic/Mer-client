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
  File? _selectedFile;
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
                  color: _selectedFile != null ? Colors.green : Colors.grey),
              SizedBox(width: 8),
              Text('选择附件', style: TextStyle(fontWeight: FontWeight.w500)),
              Spacer(),
              if (_selectedFile != null)
                Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          SizedBox(height: 12),
          if (_selectedFile != null && _selectedFile!.path.isNotEmpty)
            Column(
              children: [
                if (_isImageFile(_selectedFile!.path))
                  Image.file(_selectedFile!, height: 100, width: 100, fit: BoxFit.cover),
                SizedBox(height: 8),
                Text(
                  '已选择: ${_getFileName(_selectedFile!.path)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _selectFile,
                      icon: Icon(Icons.change_circle, size: 16),
                      label: Text('更换'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedFile = null;
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
              onPressed: _selectFile,
              icon: Icon(Icons.attach_file),
              label: Text('选择文件'),
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

  Future<void> _selectFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? selectedXFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (selectedXFile != null && selectedXFile.path.isNotEmpty) {
        setState(() {
          _selectedFile = File(selectedXFile.path);
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
        file: _selectedFile,
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