import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../models/role.dart';

class SubtaskDetailView extends StatefulWidget {
  final Map<String, dynamic> subtask;
  final Role userRole;
  final String currentUserId;
  final Function(Map<String, dynamic>) onSubtaskUpdated;

  SubtaskDetailView({
    required this.subtask,
    required this.userRole,
    required this.currentUserId,
    required this.onSubtaskUpdated,
  });

  @override
  _SubtaskDetailViewState createState() => _SubtaskDetailViewState();
}

class _SubtaskDetailViewState extends State<SubtaskDetailView> {
  late Map<String, dynamic> _currentSubtask;
  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;
  Position? _currentPosition;
  String? _locationAddress;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentSubtask = Map<String, dynamic>.from(widget.subtask);
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> checkIns = _currentSubtask['checkIns'] ?? [];
    bool isOwnSubtask = _currentSubtask['assignedTo'] == widget.currentUserId;
    bool hasManagementPermission = widget.userRole.roleId <= 3;

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
            Text(
              _currentSubtask['title'],
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333)),
            ),
            SizedBox(height: 8),
            Text(
              '状态: ${_currentSubtask['completed'] ? '已完成' : '未完成'}',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            SizedBox(height: 8),
            Text(
              '分配给: ${_currentSubtask['assignedTo']}',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            SizedBox(height: 20),
            if (isOwnSubtask || hasManagementPermission)
              ElevatedButton(
                onPressed: _showCheckInDialog,
                child: Text('打卡'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF8C42),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            SizedBox(height: 20),
            Text(
              '打卡记录',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333)),
            ),
            SizedBox(height: 12),
            if (checkIns.isEmpty)
              Text('暂无打卡记录', style: TextStyle(color: Color(0xFF666666)))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: checkIns.length,
                itemBuilder: (context, index) {
                  final checkIn = checkIns[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${checkIn['userId']} · ${checkIn['timestamp'].toString().substring(0, 19)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          if (checkIn['photo'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(checkIn['photo']),
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          SizedBox(height: 12),
                          Text(
                            '位置: ${checkIn['location']}',
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFF666666)),
                          ),
                          SizedBox(height: 8),
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                                child: Text('地图占位符',
                                    style:
                                        TextStyle(color: Color(0xFF666666)))),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '备注: ${checkIn['note'] ?? '无备注'}',
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFF666666)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showCheckInDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('子任务打卡'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                              Icon(Icons.camera_alt,
                                  color: _capturedImage != null
                                      ? Colors.green
                                      : Colors.grey),
                              SizedBox(width: 8),
                              Text('1. 拍照 *',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w500)),
                              Spacer(),
                              if (_capturedImage != null)
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 20),
                            ],
                          ),
                          SizedBox(height: 8),
                          if (_capturedImage != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_capturedImage!,
                                  height: 100, fit: BoxFit.cover),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () async {
                                final XFile? photo = await _picker.pickImage(
                                    source: ImageSource.camera);
                                if (photo != null) {
                                  setDialogState(() {
                                    _capturedImage = File(photo.path);
                                  });
                                }
                              },
                              icon: Icon(Icons.camera_alt),
                              label: Text('拍照'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFF8C42),
                                foregroundColor: Colors.white,
                              ),
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
                              Icon(Icons.location_on,
                                  color: _currentPosition != null
                                      ? Colors.green
                                      : Colors.grey),
                              SizedBox(width: 8),
                              Text('2. 获取位置 *',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w500)),
                              Spacer(),
                              if (_currentPosition != null)
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 20),
                            ],
                          ),
                          SizedBox(height: 8),
                          if (_currentPosition != null)
                            Text(
                              _locationAddress ??
                                  '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  LocationPermission permission =
                                      await Geolocator.checkPermission();
                                  if (permission == LocationPermission.denied) {
                                    permission =
                                        await Geolocator.requestPermission();
                                  }
                                  if (permission ==
                                          LocationPermission.whileInUse ||
                                      permission == LocationPermission.always) {
                                    Position position =
                                        await Geolocator.getCurrentPosition();
                                    setDialogState(() {
                                      _currentPosition = position;
                                      _locationAddress = '北京市朝阳区'; // 模拟地址
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFF8C42),
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: '备注',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
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
                  onPressed:
                      (_capturedImage != null && _currentPosition != null)
                          ? () {
                              Navigator.pop(context);
                              setState(() {
                                List<dynamic> checkIns =
                                    _currentSubtask['checkIns'] ?? [];
                                checkIns.add({
                                  'userId': widget.currentUserId,
                                  'timestamp': DateTime.now(),
                                  'photo': _capturedImage!.path,
                                  'location': _locationAddress ??
                                      '${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
                                  'note': _noteController.text.isNotEmpty
                                      ? _noteController.text
                                      : '子任务打卡'
                                });
                                _currentSubtask['checkIns'] = checkIns;
                                _currentSubtask['completed'] = true;
                                widget.onSubtaskUpdated(_currentSubtask);
                              });
                              _capturedImage = null;
                              _currentPosition = null;
                              _locationAddress = null;
                              _noteController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('打卡成功')),
                              );
                            }
                          : null,
                  child: Text('完成打卡'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF8C42),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
