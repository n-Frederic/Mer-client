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

    print('📦 === 开始分类附件 ===');
    print('📦 报告ID: ${widget.report.id}');
    print('📦 任务ID: ${widget.taskId}');
    print('📦 原始附件数据: ${widget.report.attachments}');
    print('📦 附件类型: ${widget.report.attachments.runtimeType}');
    print('📦 附件长度: ${widget.report.attachments.length}');

    // 检查每个附件
    for (final attachment in widget.report.attachments) {
      print('🔍 处理附件: $attachment');
      print('🔍 附件类型: ${attachment.runtimeType}');

      // 检查是否是有效的URL
      if (attachment is String && attachment.isNotEmpty) {
        if (_isImageFile(attachment)) {
          _imageAttachments.add(attachment);
          print('✅ 识别为图片: $attachment');
        } else {
          _otherAttachments.add(attachment);
          print('📄 识别为其他文件: $attachment');
        }
      } else {
        print('⚠️ 跳过无效附件: $attachment');
      }
    }

    print('📊 分类结果:');
    print('📷 图片附件 (${_imageAttachments.length}): $_imageAttachments');
    print('📄 其他附件 (${_otherAttachments.length}): $_otherAttachments');
  }

// 在 _prepareImageUrls 方法中确保使用正确的 URL
  void _prepareImageUrls() async {
    _imageUrlsWithAuth.clear();

    print('🔄 === 准备图片URL ===');
    print('🔄 图片附件数量: ${_imageAttachments.length}');

    // 方案1: 直接使用COS URL（推荐）
    bool useDirectCosUrl = true; // 设为true直接访问COS，false通过代理

    for (final imageUrl in _imageAttachments) {
      if (useDirectCosUrl) {
        // 直接使用COS URL
        _imageUrlsWithAuth[imageUrl] = imageUrl;
        print('🌐 直接使用COS URL: $imageUrl');
      } else {
        // 通过后端代理（需要认证）
        final authToken = await AuthService.getSavedToken();
        if (authToken != null) {
          final fileName = _getFileName(imageUrl);
          final proxyUrl = '${TaskReportService.baseUrl}/files/${widget.taskId}/$fileName';
          _imageUrlsWithAuth[imageUrl] = proxyUrl;
          print('🔗 使用代理URL: $proxyUrl');
        }
      }
    }

    print('✅ 图片URL准备完成，共 ${_imageUrlsWithAuth.length} 张图片');
    if (mounted) setState(() {});
  }


  bool _isImageFile(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }

  Future<void> _downloadAttachment(String fileUrl) async {
    try {
      print('📥 开始下载文件: $fileUrl');

      // 检查是否是COS URL
      bool isCosUrl = fileUrl.contains('cos.myqcloud.com');

      String downloadUrl = fileUrl;
      String fileName = _getFileName(fileUrl);

      if (!isCosUrl) {
        // 如果是相对路径，通过代理下载
        final authToken = await AuthService.getSavedToken();
        if (authToken == null) {
          throw Exception('用户未认证');
        }
        downloadUrl = '${TaskReportService.baseUrl}/files/${widget.taskId}/$fileName';
      }

      print('📥 下载信息:');
      print('   原始URL: $fileUrl');
      print('   下载URL: $downloadUrl');
      print('   文件名: $fileName');

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
              Text('文件大小: 未知'),
              SizedBox(height: 8),
              Text('下载链接:'),
              SizedBox(height: 4),
              SelectableText(
                downloadUrl,
                style: TextStyle(fontSize: 10, color: Colors.blue),
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
                // 在实际应用中，这里可以使用url_launcher打开链接
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已准备下载链接'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: Text('复制链接'),
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
  Widget _buildNetworkImage(String originalUrl, String attachment) {
    final displayUrl = _imageUrlsWithAuth[originalUrl] ?? originalUrl;

    print('🖼️ 加载图片:');
    print('   原始URL: $originalUrl');
    print('   显示URL: $displayUrl');

    // 检查是否是直接COS URL（包含cos.myqcloud.com）
    bool isDirectCosUrl = displayUrl.contains('cos.myqcloud.com') ||
        displayUrl.contains('cos.ap-beijing.myqcloud.com');

    if (isDirectCosUrl) {
      print('✅ 直接访问COS图片');
      return _buildDirectCosImage(displayUrl);
    } else {
      print('🔗 通过代理访问图片');
      return _buildProxyImage(displayUrl);
    }
  }

  // 直接访问COS图片（不需要认证）
  Widget _buildDirectCosImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) {
        print('❌ COS图片加载失败: $error');
        print('❌ URL: $url');
        return _buildErrorWidget();
      },
    );
  }

// 通过代理访问图片（需要认证）
  Widget _buildProxyImage(String imageUrl) {
    return FutureBuilder<String?>(
      future: AuthService.getSavedToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final token = snapshot.data;
        if (token == null) {
          print('❌ Token为空，无法加载代理图片');
          return _buildErrorWidget();
        }

        print('✅ 使用Token加载代理图片: $imageUrl');
        return CachedNetworkImage(
          imageUrl: imageUrl,
          httpHeaders: {
            'Authorization': 'Bearer $token',
          },
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) {
            print('❌ 代理图片加载失败: $error');
            print('❌ URL: $url');
            return _buildErrorWidget();
          },
        );
      },
    );
  }

  Widget _buildErrorWidget() {
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
  void _showImagePreview(String imageUrl, int index) {
    final displayUrl = _imageUrlsWithAuth[imageUrl] ?? imageUrl;

    print('🔍 图片预览:');
    print('   原始URL: $imageUrl');
    print('   显示URL: $displayUrl');
    print('   索引: $index');

    bool isDirectCosUrl = displayUrl.contains('cos.myqcloud.com');

    showDialog(
      context: context,
      builder: (context) => isDirectCosUrl
          ? _buildDirectCosPreview(displayUrl)
          : _buildProxyPreview(displayUrl),
    );
  }

  Widget _buildDirectCosPreview(String imageUrl) {
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
                  Text('图片预览', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('加载中...'),
                    ],
                  ),
                ),
                errorWidget: (context, url, error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text('图片加载失败'),
                        SizedBox(height: 8),
                        SelectableText(
                          imageUrl,
                          style: TextStyle(fontSize: 10, color: Colors.grey),
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
  }

  Widget _buildProxyPreview(String imageUrl) {
    return FutureBuilder<String?>(
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
            content: Text('认证失败'),
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
                      Text('图片预览', style: TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    httpHeaders: {'Authorization': 'Bearer $token'},
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 48),
                            SizedBox(height: 16),
                            Text('图片加载失败'),
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
    );
  }

  String _formatDetailedTime(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }
}