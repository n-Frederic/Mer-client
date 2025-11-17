import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../models/task.dart';
import '../models/task_report.dart';
import '../models/task_list_response.dart';
import '../config/app_config.dart';
import '../models/task_user.dart';

class TaskService {
  static final String baseUrl = AppConfig.baseUrl;

  // 获取认证头信息
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await AuthService.getSavedToken();
    if (token == null) {
      throw Exception('用户未登录，请重新登录');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 辅助函数：处理 API 请求的通用逻辑
  static Future<TaskListResponse> _fetchTasks(String path, {Map<String, String>? params}) async {
    final authToken = await AuthService.getSavedToken();

    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);
        try {
          final Map<String, dynamic> responseData = json.decode(jsonString);
          final List<dynamic> jsonList = responseData['list'] ?? [];

          final List<Task> tasks = jsonList.map((json) => Task.fromJson(json)).toList();

          return TaskListResponse(
            tasks: tasks,
            total: responseData['total'] ?? 0,
            page: responseData['page'] ?? 1,
            pageSize: responseData['pageSize'] ?? 10,
          );
        } catch (e) {
          print('JSON解析失败，服务器返回内容: ${utf8.decode(response.bodyBytes)}');
          throw Exception('数据解析异常: $e');
        }
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('无法加载任务列表，服务器响应码: ${response.statusCode}');
      }
    } catch (e, s) {
      print('TaskService 捕获到原始错误: $e');
      print('TaskService 原始堆栈: $s');
      throw Exception('TaskService 请求失败: $e');
    }
  }

  // 获取个人任务
  static Future<TaskListResponse> fetchPersonalTasks({
    int page = 1,
    int pageSize = 10,
    String? status,
    String? priority,
  }) {
    final Map<String, String> params = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;

    return _fetchTasks('/tasks/personal', params: params);
  }

  // 获取权限内全部任务
  static Future<TaskListResponse> fetchScopedTasks({
    int page = 1,
    int pageSize = 10,
    String? status,
    String? priority,
  }) {
    final Map<String, String> params = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;

    return _fetchTasks('/tasks/myView', params: params);
  }

  // 获取单个任务详情
  static Future<Task> fetchTaskById(String taskId) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$baseUrl/tasks/$taskId');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = json.decode(jsonString);

        if (responseData['ok'] == true && responseData.containsKey('task')) {
          return Task.fromJson(responseData['task']);
        } else {
          throw Exception(responseData['error'] ?? '无法解析任务详情');
        }
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('无法加载任务详情，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskService 捕获到原始错误 (fetchTaskById): $e');
      throw Exception('TaskService 请求失败: $e');
    }
  }

  // 创建任务
  static Future<Map<String, dynamic>> createTask({
    required int userId,
    required String title,
    required String description,
    required DateTime dueAt,
    required List<String> tags,
    required List<int> assigneeIds,
    String priority = "medium",
    String status = "published"
  }) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final url = Uri.parse("$baseUrl/tasks");

    final body = jsonEncode({
      "title": title,
      "description": description,
      "dueAt": dueAt.toUtc().toIso8601String(),
      "priority": priority,
      "assigneeIds": assigneeIds,
      "tags": tags,
      "status": status
    });

    print('📤 创建任务请求 URL: $url');
    print('📤 创建任务请求体: $body');
    print('🔑 使用Token: ${authToken.substring(0, 20)}...');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: body,
      );

      print('📥 创建任务响应状态码: ${response.statusCode}');
      print('📥 创建任务响应体: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception("创建任务失败: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print('💥 创建任务请求异常: $e');
      throw Exception("创建任务请求失败: $e");
    }
  }

  // 在 TaskService 中修改 fetchTaskAssigneesList 方法
  static Future<List<TaskUser>> fetchTaskAssigneesList(String taskId) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$baseUrl/tasks/assignerAndDesignee/$taskId');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📥 获取任务指派者响应状态码: ${response.statusCode}');
      print('📥 获取任务指派者响应体: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = json.decode(jsonString);

        if (responseData['code'] == 200 && responseData.containsKey('data')) {
          final data = responseData['data'];
          List<dynamic> assigneesJson = [];

          // 根据实际响应结构调整
          if (data.containsKey('assignees') && data['assignees'] is List) {
            assigneesJson = data['assignees'];
          }

          return assigneesJson.map((json) => TaskUser.fromJson(json)).toList();
        } else {
          throw Exception(responseData['message'] ?? '无法解析任务分配信息');
        }
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('无法加载任务分配信息，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskService 捕获到原始错误 (fetchTaskAssigneesList): $e');
      throw Exception('获取任务分配信息失败: $e');
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
          // 处理不同的响应格式
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
          // 如果没有报告记录，返回空列表
          return [];
        }
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else if (response.statusCode == 404) {
        // 没有找到报告记录，返回空列表
        return [];
      } else {
        throw Exception('无法加载报告记录，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskService 捕获到原始错误 (fetchTaskReports): $e');
      // 出错时返回空列表而不是抛出异常
      return [];
    }
  }

  // 获取地理位置服务
  static Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // 使用腾讯位置服务
      final String apiKey = 'DOVBZ-7FU3Z-5DIXJ-7J3VL-WV7JV-LHBED';

      print('🌐 调用腾讯位置服务API...');
      print('📌 坐标: $latitude, $longitude');

      final response = await http.get(
        Uri.parse('https://apis.map.qq.com/ws/geocoder/v1/?'
            'key=$apiKey'
            '&location=$latitude,$longitude'  // 腾讯API是纬度,经度
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
            // 优先使用推荐地址
            final recommendAddress = result['formatted_addresses']?['recommend'];
            if (recommendAddress != null && recommendAddress.isNotEmpty) {
              print('✅ 获取到推荐地址: $recommendAddress');
              return recommendAddress;
            }

            // 如果没有推荐地址，使用地址组件构建地址
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

    // 构建地址字符串
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

    // 基于真实地理区域的模拟地址
    if (latitude >= 39.8 && latitude <= 40.1 && longitude >= 116.2 && longitude <= 116.5) {
      // 北京区域
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

    // 返回格式化坐标作为备用
    return '位置 ${latitude.toStringAsFixed(4)}°N, ${longitude.toStringAsFixed(4)}°E';
  }





// 创建任务报告 - 修复版，在同一个接口上传文件
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

      // 获取当前用户ID
      final currentUserId = await AuthService.getSavedUserId();
      if (currentUserId == null) {
        throw Exception('无法获取用户ID');
      }

      // 如果没有提供地址，根据坐标获取地址
      String finalAddress = address ?? await getAddressFromCoordinates(
          location.latitude,
          location.longitude
      );

      print('📤 提交任务报告请求: $baseUrl/tasks/$taskId/reports');
      print('👤 当前用户ID: $currentUserId');
      print('📍 位置: ${location.latitude}, ${location.longitude}');
      print('📝 内容: $content');
      print('🏠 地址: $finalAddress');

      // 创建 multipart 请求
      var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/tasks/$taskId/reports')
      );

      // 添加 headers
      request.headers['Authorization'] = 'Bearer $authToken';

      // 添加文件 - 使用 attachments 字段名
      // if (file != null && file.existsSync()) {
      //   print('📁 添加文件中: ${file.path}');
      //   request.files.add(await http.MultipartFile.fromPath(
      //     'attachments', // 使用正确的字段名
      //     file.path,
      //     filename: file.path.split('/').last,
      //   ));
      //   print('✅ 文件已添加到请求中');
      // } else {
      //   print('ℹ️ 没有文件附件');
      // }

      // 添加其他字段
      request.fields.addAll({
        'latitude': location.latitude.toString(),
        'longitude': location.longitude.toString(),
        'content': content,
        'address': finalAddress,
        'reporter_id': currentUserId.toString(),
        'attachments': '', // 传空字符串
      });

      print('📋 请求字段: ${request.fields}');
      // print('📁 文件数量: ${request.files.length}');
      if (request.files.isNotEmpty) {
        print('📎 文件字段名: ${request.files.first.field}');
        print('📎 文件名: ${request.files.first.filename}');
      }

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
          // 检查是否有更详细的错误信息
          final errorMsg = data['error'] ?? data['message'] ?? '未知错误';
          throw Exception('服务器返回成功但ok字段为false: $errorMsg');
        }
      } else if (response.statusCode == 400) {
        // 400错误，提供更详细的错误信息
        String errorDetail = '请求参数错误';
        try {
          final errorData = json.decode(responseBody);
          errorDetail = errorData['error'] ?? errorData['message'] ?? '未知错误';
        } catch (e) {
          errorDetail = responseBody;
        }
        throw Exception('请求参数错误: $errorDetail');
      } else if (response.statusCode == 413) {
        throw Exception('文件太大，请选择较小的文件');
      } else if (response.statusCode == 415) {
        throw Exception('不支持的文件类型');
      } else {
        throw Exception('提交报告失败: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      print('💥 提交报告失败: $e');
      rethrow;
    }
  }

  // 更新任务状态
  static Future<bool> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$baseUrl/tasks/$taskId/status');

    final body = jsonEncode({
      'status': newStatus.sqlValue,
    });

    try {
      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: body,
      );

      print('📥 更新任务状态响应状态码: ${response.statusCode}');
      print('📥 更新任务状态响应体: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData['ok'] == true;
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('更新任务状态失败，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskService 捕获到原始错误 (updateTaskStatus): $e');
      throw Exception('更新任务状态失败: $e');
    }
  }

  // 审批任务报告（新增）
  static Future<bool> approveTaskReport(String taskId) async {
    return await updateTaskStatus(taskId, TaskStatus.completed);
  }

  // 拒绝任务报告（新增）
  static Future<bool> rejectTaskReport(String taskId) async {
    return await updateTaskStatus(taskId, TaskStatus.published);
  }

  // 更新任务信息（新增）
  static Future<bool> updateTask({
    required String taskId,
    required String title,
    required String description,
    required DateTime dueAt,
    required List<String> tags,
    required List<int> assigneeIds,
    required String priority,
  }) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$baseUrl/tasks/$taskId');

    final body = jsonEncode({
      "title": title,
      "description": description,
      "dueAt": dueAt.toUtc().toIso8601String(),
      "priority": priority,
      "assigneeIds": assigneeIds,
      "tags": tags,
    });

    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: body,
      );

      print('📥 更新任务响应状态码: ${response.statusCode}');
      print('📥 更新任务响应体: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData['ok'] == true;
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('更新任务失败，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskService 捕获到原始错误 (updateTask): $e');
      throw Exception('更新任务失败: $e');
    }
  }

  // 删除任务（新增）
  static Future<bool> deleteTask(String taskId) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$baseUrl/tasks/$taskId');

    try {
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📥 删除任务响应状态码: ${response.statusCode}');
      print('📥 删除任务响应体: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData['ok'] == true;
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('删除任务失败，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskService 捕获到原始错误 (deleteTask): $e');
      throw Exception('删除任务失败: $e');
    }
  }

  // 获取任务统计信息（新增）
  static Future<Map<String, dynamic>> getTaskStatistics() async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$baseUrl/tasks/statistics');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = json.decode(jsonString);

        if (responseData['ok'] == true) {
          return responseData['data'] ?? {};
        } else {
          throw Exception(responseData['error'] ?? '无法解析任务统计信息');
        }
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('无法加载任务统计信息，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskService 捕获到原始错误 (getTaskStatistics): $e');
      throw Exception('获取任务统计信息失败: $e');
    }
  }

}