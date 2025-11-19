// task_report_detail_view.dart - 支持图片显示版本
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
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
  Map<String, String> _imageUrlsWithAuth = {};

  @override
  void initState() {
    super.initState();
    _categorizeAttachments();
    _prepareImageUrls();
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

// 在 _prepareImageUrls 方法中确保使用正确的 URL
  void _prepareImageUrls() async {
    final authToken = await AuthService.getSavedToken();
    if (authToken != null) {
      for (final imageUrl in _imageAttachments) {
        final fileName = _getFileName(imageUrl);
        final fullUrl = '${TaskReportService.baseUrl}/files/${widget.taskId}/$fileName';
        _imageUrlsWithAuth[imageUrl] = fullUrl;
        print('🖼️ 图片URL: $fullUrl'); // 添加调试信息
      }
      if (mounted) setState(() {});
    }
  }

  bool _isImageFile(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }

// 修改下载方法中的 URL 生成
  Future<void> _downloadAttachment(String fileUrl) async {
    try {
      final authToken = await AuthService.getSavedToken();
      if (authToken == null) {
        throw Exception('用户未认证');
      }

      final fileName = _getFileName(fileUrl);
      // 使用新的文件服务 URL
      final fullUrl = '${TaskReportService.baseUrl}/files/${widget.taskId}/$fileName';

      print('📥 开始下载文件: $fullUrl');

      // 显示文件下载对话框
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('下载文件'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('文件名: $fileName'),
              SizedBox(height: 8),
              Text('类型: ${_getFileTypeDescription(fileUrl)}'),
              SizedBox(height: 8),
              Text('文件链接:'),
              SizedBox(height: 4),
              SelectableText(
                fullUrl,
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('文件链接已准备'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: Text('确定'),
            ),
          ],
        ),
      );

    } catch (e) {
      print('❌ 下载文件失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('操作失败: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
            if (_imageAttachments.isNotEmpty) _buildImageAttachments(),
            if (_otherAttachments.isNotEmpty) _buildOtherAttachments(),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 图片附件显示
  Widget _buildImageAttachments() {
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
                Icon(Icons.photo_library, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  '图片附件 (${_imageAttachments.length})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _imageAttachments.length,
              itemBuilder: (context, index) {
                final attachment = _imageAttachments[index];
                final imageUrl = _imageUrlsWithAuth[attachment];

                return GestureDetector(
                  onTap: () => _showImagePreview(attachment, index),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: imageUrl != null
                        ? _buildNetworkImage(imageUrl, attachment)
                        : Center(
                      child: CircularProgressIndicator(),
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

  // 构建网络图片组件
  // 构建网络图片组件
  Widget _buildNetworkImage(String imageUrl, String attachment) {
    final fileName = _getFileName(attachment);
    final fullImageUrl = '${TaskReportService.baseUrl}/files/${widget.taskId}/$fileName';

    print('🖼️ 加载图片: $fullImageUrl');

    return FutureBuilder<String?>(
      future: AuthService.getSavedToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final token = snapshot.data;
        if (token == null) {
          print('❌ Token为空');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(height: 4),
                Text('认证失败', style: TextStyle(fontSize: 10)),
              ],
            ),
          );
        }

        print('✅ 使用Token加载图片: $fullImageUrl');
        return CachedNetworkImage(
          imageUrl: fullImageUrl,
          httpHeaders: {
            'Authorization': 'Bearer $token',
          },
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) {
            print('❌ 图片加载失败: $url');
            print('❌ 错误类型: ${error.runtimeType}');
            print('❌ 错误信息: $error');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey),
                  SizedBox(height: 4),
                  Text('加载失败', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            );
          },
        );
      },
    );
  }
  // 其他附件显示
  Widget _buildOtherAttachments() {
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
                  '其他附件 (${_otherAttachments.length})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Column(
              children: _otherAttachments.map((attachment) =>
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

  // 图片预览
  // 图片预览
  void _showImagePreview(String imageUrl, int index) {
    final fileName = _getFileName(imageUrl);
    final fullUrl = '${TaskReportService.baseUrl}/files/${widget.taskId}/$fileName';

    print('🔍 图片预览URL: $fullUrl');

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<String?>(
        future: AuthService.getSavedToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Dialog(
              child: Container(
                width: 300,
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final token = snapshot.data;
          if (token == null) {
            return AlertDialog(
              title: Text('错误'),
              content: Text('认证失败，无法加载图片'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('关闭'),
                ),
              ],
            );
          }

          return Dialog(
            insetPadding: EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              height: 400,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '图片预览',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CachedNetworkImage(
                      imageUrl: fullUrl,
                      httpHeaders: {
                        'Authorization': 'Bearer $token',
                      },
                      fit: BoxFit.contain,
                      progressIndicatorBuilder: (context, url, progress) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress.progress,
                            ),
                            SizedBox(height: 8),
                            Text('加载中...'),
                          ],
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        print('❌ 预览图片加载失败: $error');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 48),
                              SizedBox(height: 16),
                              Text('图片加载失败', style: TextStyle(fontSize: 16)),
                              SizedBox(height: 8),
                              Text(
                                'URL: ${fullUrl.split('/').last}',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  String _formatDetailedTime(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }
}