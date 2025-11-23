import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'auth_service.dart';
import '../models/task_report.dart';
import '../config/app_config.dart';
import 'package:http_parser/http_parser.dart';

class TaskReportService {
  static final String baseUrl = AppConfig.baseUrl;

// 在 TaskReportService 中修改获取报告的方法
  static Future<Map<String, List<TaskReport>>> fetchTaskReportsByUser(String taskId) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$baseUrl/tasks/$taskId/reports');

    print('🔄 [fetchTaskReportsByUser] 获取任务报告');
    print('   📍 请求URL: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📥 [fetchTaskReportsByUser] 响应状态码: ${response.statusCode}');
      print('📥 [fetchTaskReportsByUser] 响应体: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = json.decode(jsonString);

        if (responseData['ok'] == true) {
          List<dynamic> reportsJson = [];

          if (responseData.containsKey('reports')) {
            reportsJson = responseData['reports'];
          } else if (responseData.containsKey('data')) {
            reportsJson = responseData['data'];
          } else if (responseData.containsKey('list')) {
            reportsJson = responseData['list'];
          }

          print('📊 [fetchTaskReportsByUser] 解析到的报告数量: ${reportsJson.length}');

          // 按用户ID分组报告
          Map<String, List<TaskReport>> userReports = {};
          for (var reportJson in reportsJson) {
            final report = TaskReport.fromJson(reportJson);
            print('   📝 报告ID: ${report.id}, 用户: ${report.createdBy}, 状态: ${report.status}');

            if (!userReports.containsKey(report.createdBy)) {
              userReports[report.createdBy] = [];
            }
            userReports[report.createdBy]!.add(report);
          }

          print('✅ [fetchTaskReportsByUser] 报告分组完成: ${userReports.keys.toList()}');
          return userReports;
        } else {
          print('❌ [fetchTaskReportsByUser] 服务器返回错误');
          return {};
        }
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else if (response.statusCode == 404) {
        print('📭 [fetchTaskReportsByUser] 没有找到报告');
        return {};
      } else {
        throw Exception('无法加载报告记录，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 [fetchTaskReportsByUser] 捕获到错误: $e');
      return {};
    }
  }
  // 审批单个用户的报告
  static Future<bool> approveUserReport(String taskId, String reporterId) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final currentUserId = await AuthService.getSavedUserId();
    final uri = Uri.parse('$baseUrl/tasks/$taskId/reports/$reporterId/approve');

    // 添加请求体
    final body = jsonEncode({
      'approved_by': currentUserId?.toString(),
      'approved_at': DateTime.now().toIso8601String(),
    });

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: body,  // 添加这行
      );

      print('📥 审批用户报告响应状态码: ${response.statusCode}');
      print('📥 审批用户报告响应体: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData['ok'] == true;
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('审批报告失败，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskReportService 捕获到原始错误 (approveUserReport): $e');
      throw Exception('审批报告失败: $e');
    }
  }

  // 拒绝单个用户的报告
  static Future<bool> rejectUserReport(String taskId, String reporterId, String reason) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final currentUserId = await AuthService.getSavedUserId();
    final uri = Uri.parse('$baseUrl/tasks/$taskId/reports/$reporterId/reject');

    final body = jsonEncode({
      'rejected_by': currentUserId?.toString(),
      'rejected_at': DateTime.now().toIso8601String(),
      'reason': reason,
    });

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: body,
      );

      print('📥 拒绝用户报告响应状态码: ${response.statusCode}');
      print('📥 拒绝用户报告响应体: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData['ok'] == true;
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('拒绝报告失败，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskReportService 捕获到原始错误 (rejectUserReport): $e');
      throw Exception('拒绝报告失败: $e');
    }
  }

  // 批量审批所有待审核报告
  static Future<bool> batchApproveReports(String taskId) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final currentUserId = await AuthService.getSavedUserId();
    final uri = Uri.parse('$baseUrl/tasks/$taskId/reports/batch-approve');

    final body = jsonEncode({
      'approved_by': currentUserId?.toString(),
      'approved_at': DateTime.now().toIso8601String(),
    });

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: body,
      );

      print('📥 批量审批响应状态码: ${response.statusCode}');
      print('📥 批量审批响应体: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData['ok'] == true;
      } else {
        throw Exception('批量审批失败，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('批量审批失败: $e');
      throw Exception('批量审批失败: $e');
    }
  }

  // 检查所有报告是否都已通过
  static Future<bool> checkAllReportsApproved(String taskId) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$baseUrl/tasks/$taskId/reports/check-all-approved');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData['all_approved'] == true;
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('检查报告状态失败，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskReportService 捕获到原始错误 (checkAllReportsApproved): $e');
      return false;
    }
  }

  // 获取任务的报告记录
  static Future<List<TaskReport>> fetchTaskReports(String taskId) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$baseUrl/tasks/$taskId/reports');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📥 获取任务报告响应状态码: ${response.statusCode}');
      print('📥 获取任务报告响应体: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = json.decode(jsonString);

        if (responseData['ok'] == true) {
          List<dynamic> reportsJson = [];

          if (responseData.containsKey('reports')) {
            reportsJson = responseData['reports'];
          } else if (responseData.containsKey('data')) {
            reportsJson = responseData['data'];
          } else if (responseData.containsKey('list')) {
            reportsJson = responseData['list'];
          }

          return reportsJson.map((json) => TaskReport.fromJson(json)).toList();
        } else {
          return [];
        }
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('无法加载报告记录，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskReportService 捕获到原始错误 (fetchTaskReports): $e');
      return [];
    }
  }

  // 创建任务报告
  static Future<bool> createTaskReport({required String taskId, List<File>? files, required Position location, required String content, String? address,}) async {
    try {
      final authToken = await AuthService.getSavedToken();
      if (authToken == null) {
        throw Exception('用户未认证，请先登录');
      }

      final currentUserId = await AuthService.getSavedUserId();
      if (currentUserId == null) {
        throw Exception('无法获取用户ID');
      }

      String finalAddress = address ?? await getAddressFromCoordinates(
          location.latitude,
          location.longitude
      );

      print('📤 提交任务报告请求: $baseUrl/tasks/$taskId/reports');
      print('👤 当前用户ID: $currentUserId');
      print('📍 位置: ${location.latitude}, ${location.longitude}');
      print('📝 内容: $content');
      print('🏠 地址: $finalAddress');
      print('📎 附件数量: ${files?.length ?? 0}');

      var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/tasks/$taskId/reports')
      );

      request.headers['Authorization'] = 'Bearer $authToken';

      request.fields.addAll({
        'latitude': location.latitude.toString(),
        'longitude': location.longitude.toString(),
        'content': content,
        'address': finalAddress,
        'reporter_id': currentUserId.toString(),
      });

      print('📋 请求字段: ${request.fields}');

      // 添加多个文件
      if (files != null && files.isNotEmpty) {
        for (int i = 0; i < files.length; i++) {
          final file = files[i];

          // 检查文件是否存在
          if (!await file.exists()) {
            print('⚠️ 文件不存在: ${file.path}');
            continue;
          }

          try {
            final fileExtension = file.path.split('.').last.toLowerCase();
            final mimeType = _getMimeType(fileExtension);

            final multipartFile = await http.MultipartFile.fromPath(
              'files',
              file.path,
              contentType: mimeType != null ? MediaType.parse(mimeType) : null,
              filename: 'report_${DateTime.now().millisecondsSinceEpoch}_$i.$fileExtension',
            );

            request.files.add(multipartFile);
            print('✅ 成功添加附件 $i: ${file.path}');

          } catch (e) {
            print('❌ 添加文件失败: ${file.path}, 错误: $e');
          }
        }  print('📦 总共添加了 ${request.files.length} 个文件到请求中');
      } else {
        print('📝 没有附件需要上传');
      }

      // 发送请求并处理响应
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 提交任务报告响应状态码: ${response.statusCode}');
      print('📥 提交任务报告响应体: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          print('✅ 报告创建成功');
          return true;
        } else {
          final errorMsg = data['message'] ?? '未知错误';
          throw Exception('服务器返回错误: $errorMsg');
        }
      } else {
        String errorDetail = '请求失败';
        try {
          final errorData = json.decode(response.body);
          errorDetail = errorData['message'] ?? response.body;
        } catch (e) {
          errorDetail = response.body;
        }
        throw Exception('提交报告失败: ${response.statusCode} - $errorDetail');
      }
    } catch (e) {
      print('💥 提交报告失败: $e');
      rethrow;
    }
  }

  // 获取任务统计方法
  static Future<Map<String, dynamic>> fetchReportStatistics(String taskId) async {
    try {
      final authToken = await AuthService.getSavedToken();
      if (authToken == null) {
        throw Exception('用户未认证，请先登录');
      }

      final uri = Uri.parse('$baseUrl/tasks/$taskId/reports/statistics');

      print('📊 请求报告统计信息: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📥 报告统计响应状态码: ${response.statusCode}');
      print('📥 报告统计响应体: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));

        if (responseData['ok'] == true) {
          // 处理不同的响应格式
          Map<String, dynamic> statistics = {};

          if (responseData.containsKey('data')) {
            statistics = responseData['data'];
          } else if (responseData.containsKey('statistics')) {
            statistics = responseData['statistics'];
          } else {
            // 如果没有嵌套结构，直接使用根级别的字段
            statistics = responseData;
          }

          print('📈 解析后的统计信息: $statistics');
          return statistics;
        } else {
          throw Exception('服务器返回错误: ${responseData['message']}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else if (response.statusCode == 404) {
        print('⚠️ 统计接口返回404，使用本地计算');
        return {};
      } else {
        throw Exception('获取报告统计失败，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 获取报告统计失败: $e');
      // 如果统计接口失败，返回空map，让前端使用本地计算
      return {};
    }
  }

  // 根据文件扩展名获取 MIME 类型
  static String? _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }


  // 获取地理位置服务
  static Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final String apiKey = 'DOVBZ-7FU3Z-5DIXJ-7J3VL-WV7JV-LHBED';

      print('🌐 调用腾讯位置服务API...');
      print('📌 坐标: $latitude, $longitude');

      final response = await http.get(
        Uri.parse('https://apis.map.qq.com/ws/geocoder/v1/?'
            'key=$apiKey'
            '&location=$latitude,$longitude'
            '&output=json'
            '&poi=0'),
      ).timeout(Duration(seconds: 10));

      print('📡 腾讯API响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 腾讯API原始响应: $data');

        if (data['status'] == 0) {
          final result = data['result'];
          if (result != null) {
            final recommendAddress = result['formatted_addresses']?['recommend'];
            if (recommendAddress != null && recommendAddress.isNotEmpty) {
              print('✅ 获取到推荐地址: $recommendAddress');
              return recommendAddress;
            }

            final addressComponent = result['address_component'];
            if (addressComponent != null) {
              final builtAddress = _buildAddressFromComponent(addressComponent);
              if (builtAddress.isNotEmpty) {
                print('✅ 使用地址组件构建地址: $builtAddress');
                return builtAddress;
              }
            }
          }
          return '地址解析成功';
        } else {
          final errorCode = data['status'] ?? '未知';
          final errorMessage = data['message'] ?? '未知错误';
          print('❌ 腾讯API错误: $errorCode - $errorMessage');
          return _getSmartMockAddress(latitude, longitude);
        }
      } else {
        print('❌ HTTP错误: ${response.statusCode}');
        return _getSmartMockAddress(latitude, longitude);
      }

    } on TimeoutException {
      print('⏰ 腾讯API请求超时');
      return _getSmartMockAddress(latitude, longitude);
    } catch (e) {
      print('💥 获取地址异常: $e');
      return _getSmartMockAddress(latitude, longitude);
    }
  }

  // 从地址组件构建完整地址
  static String _buildAddressFromComponent(Map<String, dynamic> addressComponent) {
    final nation = addressComponent['nation'] ?? '';
    final province = addressComponent['province'] ?? '';
    final city = addressComponent['city'] ?? '';
    final district = addressComponent['district'] ?? '';
    final street = addressComponent['street'] ?? '';
    final streetNumber = addressComponent['street_number'] ?? '';

    String address = '';
    if (province.isNotEmpty) address += province;
    if (city.isNotEmpty && city != province) address += city;
    if (district.isNotEmpty) address += district;
    if (street.isNotEmpty) address += street;
    if (streetNumber.isNotEmpty) address += streetNumber;

    return address.isNotEmpty ? address : '未知地址';
  }

  // 智能降级方案
  static String _getSmartMockAddress(double latitude, double longitude) {
    print('🔄 使用智能模拟地址');

    if (latitude >= 39.8 && latitude <= 40.1 && longitude >= 116.2 && longitude <= 116.5) {
      final beijingAddresses = [
        '北京市朝阳区望京街道',
        '北京市海淀区中关村大街',
        '北京市东城区王府井大街',
        '北京市西城区金融街',
        '北京市丰台区科技园区',
      ];
      final index = (DateTime.now().millisecondsSinceEpoch ~/ 1000) % beijingAddresses.length;
      return beijingAddresses[index];
    }

    return '位置 ${latitude.toStringAsFixed(4)}°N, ${longitude.toStringAsFixed(4)}°E';
  }
}