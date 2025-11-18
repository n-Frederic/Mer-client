// task_report_detail_view.dart - 简化版本
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task_report.dart';
import '../services/task_report_service.dart';
import '../services/auth_service.dart';

class TaskReportDetailView extends StatefulWidget {
  final TaskReport report;
  final String taskId;

  const TaskReportDetailView({
    Key? key,
    required this.report,
    required this.taskId,
  }) : super(key: key);

  @override
  _TaskReportDetailViewState createState() => _TaskReportDetailViewState();
}

class _TaskReportDetailViewState extends State<TaskReportDetailView> {
  List<String> _imageAttachments = [];
  List<String> _otherAttachments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _categorizeAttachments();
  }

  void _categorizeAttachments() {
    _imageAttachments.clear();
    _otherAttachments.clear();

    for (final attachment in widget.report.attachments) {
      if (_isImageFile(attachment)) {
        _imageAttachments.add(attachment);
      } else {
        _otherAttachments.add(attachment);
      }
    }
  }

  bool _isImageFile(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }

  // 下载文件方法
  Future<void> _downloadAttachment(String fileUrl) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authToken = await AuthService.getSavedToken();
      if (authToken == null) {
        throw Exception('用户未认证');
      }

      final fullUrl = '${TaskReportService.baseUrl}/$fileUrl';
      print('📥 开始下载文件: $fullUrl');

      // 使用 url_launcher 打开下载链接
      if (await canLaunch(fullUrl)) {
        await launch(
          fullUrl,
          headers: {'Authorization': 'Bearer $authToken'},
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('正在下载: ${_getFileName(fileUrl)}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('无法打开下载链接');
      }
    } catch (e) {
      print('❌ 下载文件失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('下载失败: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 获取文件类型图标
  IconData _getFileIcon(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      case 'txt':
        return Icons.text_snippet;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  // 获取文件类型描述
  String _getFileTypeDescription(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf': return 'PDF 文档';
      case 'doc': case 'docx': return 'Word 文档';
      case 'xls': case 'xlsx': return 'Excel 表格';
      case 'ppt': case 'pptx': return 'PowerPoint 演示文稿';
      case 'zip': case 'rar': return '压缩文件';
      case 'txt': return '文本文件';
      case 'mp4': case 'avi': case 'mov': return '视频文件';
      case 'jpg': case 'jpeg': case 'png': return '图片文件';
      default: return '文件';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('工作报告详情'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReporterInfo(),
            SizedBox(height: 20),
            _buildContentSection(),
            SizedBox(height: 20),
            _buildLocationSection(),
            SizedBox(height: 20),
            if (widget.report.attachments.isNotEmpty) _buildAllAttachments(),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildReporterInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue[100],
              child: Text(
                widget.report.reporterName?.isNotEmpty == true
                    ? widget.report.reporterName![0].toUpperCase()
                    : 'U',
                style: TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.report.reporterName ?? '未知用户',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '提交时间: ${_formatDetailedTime(widget.report.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  '工作内容',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                widget.report.content,
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text(
                  '工作位置',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.report.address,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '坐标: ${widget.report.latitude.toStringAsFixed(6)}, ${widget.report.longitude.toStringAsFixed(6)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllAttachments() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_file, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  '所有附件 (${widget.report.attachments.length})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Column(
              children: widget.report.attachments.map((attachment) =>
                  _buildAttachmentItem(attachment)
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(String attachment) {
    final fileName = _getFileName(attachment);
    final fileType = _getFileTypeDescription(attachment);
    final icon = _getFileIcon(attachment);
    final isImage = _isImageFile(attachment);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  fileType,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _downloadAttachment(attachment),
            icon: Icon(Icons.download, color: Colors.blue),
            tooltip: '下载文件',
          ),
        ],
      ),
    );
  }

  String _formatDetailedTime(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }
}