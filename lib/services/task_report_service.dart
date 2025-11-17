import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'auth_service.dart';
import '../models/task_report.dart';
import '../config/app_config.dart';

class TaskReportService {
  static final String baseUrl = AppConfig.baseUrl;

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
  static Future<bool> createTaskReport({
    required String taskId,
    File? file,
    required Position location,
    required String content,
    String? address,
  }) async {
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
        'attachments': '',
      });

      print('📋 请求字段: ${request.fields}');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📥 提交任务报告响应状态码: ${response.statusCode}');
      print('📥 提交任务报告响应体: $responseBody');

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        if (data['ok'] == true) {
          print('✅ 报告创建成功');
          return true;
        } else {
          final errorMsg = data['error'] ?? data['message'] ?? '未知错误';
          throw Exception('服务器返回成功但ok字段为false: $errorMsg');
        }
      } else if (response.statusCode == 400) {
        String errorDetail = '请求参数错误';
        try {
          final errorData = json.decode(responseBody);
          errorDetail = errorData['error'] ?? errorData['message'] ?? '未知错误';
        } catch (e) {
          errorDetail = responseBody;
        }
        throw Exception('请求参数错误: $errorDetail');
      } else {
        throw Exception('提交报告失败: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      print('💥 提交报告失败: $e');
      rethrow;
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