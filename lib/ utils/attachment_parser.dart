// utils/attachment_parser.dart
class AttachmentParser {
  /// 核心方法：解析任何格式的附件数据为URL列表
  static List<String> parseAttachments(dynamic attachmentsData) {
    if (attachmentsData == null) {
      return [];
    }

    print('🔍 原始附件数据: $attachmentsData');
    print('🔍 数据类型: ${attachmentsData.runtimeType}');

    // 1. 如果是字符串
    if (attachmentsData is String) {
      return _parseStringAttachments(attachmentsData);
    }

    // 2. 如果是数组
    if (attachmentsData is List) {
      return _parseListAttachments(attachmentsData);
    }

    // 3. 其他类型尝试转换为字符串再解析
    return _parseStringAttachments(attachmentsData.toString());
  }

  /// 解析字符串格式的附件
  static List<String> _parseStringAttachments(String str) {
    // 清理字符串
    String cleaned = str.trim();

    // 空值检查
    if (cleaned.isEmpty || cleaned == '[]' || cleaned == 'null' || cleaned == '""') {
      return [];
    }

    print('📄 处理字符串: "$cleaned"');

    // 情况1: 竖线分隔 (您数据库的格式)
    // 例如: "url1|url2|url3"
    if (cleaned.contains('|')) {
      final List<String> urls = cleaned.split('|')
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList();
      print('✅ 竖线分隔解析结果: $urls');
      return urls;
    }

    // 情况2: JSON数组字符串
    // 例如: '["url1","url2"]' 或 "[url1,url2]"
    if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
      return _parseJsonArray(cleaned);
    }

    // 情况3: 逗号分隔
    // 例如: "url1,url2,url3"
    if (cleaned.contains(',')) {
      final List<String> urls = cleaned.split(',')
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList();
      print('✅ 逗号分隔解析结果: $urls');
      return urls;
    }

    // 情况4: 单个URL
    print('✅ 单个URL解析结果: [$cleaned]');
    return [cleaned];
  }

  /// 解析JSON数组格式
  static List<String> _parseJsonArray(String jsonStr) {
    try {
      // 移除方括号
      String content = jsonStr.substring(1, jsonStr.length - 1);

      // 如果为空
      if (content.trim().isEmpty) {
        return [];
      }

      // 移除引号
      content = content.replaceAll('"', '').replaceAll("'", '');

      // 按逗号分割
      final List<String> urls = content.split(',')
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList();

      print('✅ JSON数组解析结果: $urls');
      return urls;
    } catch (e) {
      print('❌ JSON解析失败: $e');
      // 如果解析失败，返回原始字符串（去掉方括号）
      String content = jsonStr.substring(1, jsonStr.length - 1);
      return [content.trim()];
    }
  }

  /// 解析数组格式
  static List<String> _parseListAttachments(List list) {
    final List<String> urls = [];

    for (var item in list) {
      if (item is String) {
        urls.add(item);
      } else {
        urls.add(item.toString());
      }
    }

    print('✅ 数组格式解析结果: $urls');
    return urls;
  }

  /// 判断是否为图片
  static bool isImage(String url) {
    try {
      final lowerUrl = url.toLowerCase();
      return lowerUrl.endsWith('.jpg') ||
          lowerUrl.endsWith('.jpeg') ||
          lowerUrl.endsWith('.png') ||
          lowerUrl.endsWith('.gif') ||
          lowerUrl.endsWith('.bmp') ||
          lowerUrl.endsWith('.webp') ||
          lowerUrl.contains('.jpg') ||
          lowerUrl.contains('.jpeg') ||
          lowerUrl.contains('.png');
    } catch (e) {
      return false;
    }
  }

  /// 从URL提取文件名
  static String getFileName(String url) {
    try {
      return url.split('/').last;
    } catch (e) {
      return url;
    }
  }
}