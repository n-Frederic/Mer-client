import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';

class CreateTaskScreen extends StatefulWidget {
  @override
  _CreateTaskScreenState createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _taskContentController = TextEditingController();
  final _tagController = TextEditingController();

  static final String baseUrl = AppConfig.baseUrl;

  DateTime? _selectedDeadline;
  String _taskType = 'self'; // 'self' or 'employee'
  List<int> _selectedEmployeeIds = [];

  String? _selectedDepartment;
  String? _selectedTeam;
  List<String> _selectedTags = [];
  String _selectedPriority = 'Medium';

  bool _isLoading = false;
  bool _isCreating = false;

  List<Map<String, dynamic>> _employees = [];
  List<String> _departments = [];
  final _searchController = TextEditingController();

  int? _currentUserRoleId;
  String? _currentUserRoleName;

  final List<String> _priorityOptions = ['Low', 'Medium', 'High', 'Urgent'];

  // 角色级别映射
  final Map<int, String> _roleHierarchy = {
    1: 'CEO',
    2: 'Manager',
    3: 'Team Leader',
    4: 'Member',
    5: 'Admin'
  };

  // 角色权限级别（数字越小权限越高）
  final Map<int, int> _roleLevels = {
    1: 1, // CEO - 最高级别
    2: 2, // Manager
    3: 3, // Team Leader
    4: 4, // Member - 最低级别
    5: 2, // Admin - 等同于Manager级别
  };

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchUserRoleAndAssignees();
  }


  /// 获取用户角色和员工数据
  Future<void> _fetchUserRoleAndAssignees() async {
    setState(() => _isLoading = true);

    try {
      final token = await AuthService.getSavedToken();
      if (token == null) {
        _showError('用户未登录，请重新登录');
        return;
      }

      // 1️⃣ 获取当前用户信息
      final profileUrl = Uri.parse('$baseUrl/user/profile');
      print('👤 请求用户信息URL: $profileUrl');

      final profileResponse = await http.get(
        profileUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 获取用户信息响应状态码: ${profileResponse.statusCode}');

      if (profileResponse.statusCode != 200) {
        _showError('获取用户信息失败: ${profileResponse.statusCode}');
        return;
      }

      final profileData = jsonDecode(utf8.decode(profileResponse.bodyBytes));
      print('📡 用户信息响应数据: $profileData');

      // 根据您的接口返回结构调整字段访问
      if (profileData['ok'] == true && profileData['user'] != null) {
        final userData = profileData['user'];
        _currentUserRoleId = userData['role_id'];
        _currentUserRoleName = _roleHierarchy[_currentUserRoleId] ?? '未知角色';

        print('🎯 当前用户角色ID: $_currentUserRoleId, 角色名称: $_currentUserRoleName');
      } else {
        _showError('无法解析用户信息');
        return;
      }

      if (_currentUserRoleId == null) {
        _showError('无法获取当前用户角色，请检查登录状态');
        return;
      }

      // 2️⃣ 获取员工列表
      final assigneesUrl = Uri.parse('$baseUrl/tasks/assignees');
      print('🌐 请求员工列表URL: $assigneesUrl');

      final assigneesResponse = await http.get(
        assigneesUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 获取员工响应状态码: ${assigneesResponse.statusCode}');

      List<Map<String, dynamic>> employeeList = [];

      if (assigneesResponse.statusCode == 200) {
        final data = jsonDecode(utf8.decode(assigneesResponse.bodyBytes));
        print('📡 员工列表响应数据: $data');

        // === 修复：直接使用原始数据结构，不要转换 ===
        if (data is Map && data.containsKey('data') && data['data'] is Map) {
          final dataMap = data['data'];
          if (dataMap.containsKey('list')) {
            employeeList = List<Map<String, dynamic>>.from(dataMap['list']);

            print('👥 员工原始列表长度: ${employeeList.length}');

            // 调试：打印原始员工数据
            for (var employee in employeeList) {
              final roleId = employee['role']?['role_id'];
              final name = employee['name'];
              print('🔍 原始员工数据: $name - 角色ID: $roleId');
            }

            // 直接使用原始数据，不需要转换
            // 原始数据结构已经是正确的：
            // {
            //   'user_id': 16,
            //   'name': 'Liu Fang',
            //   'role': {'role_id': 4, 'name': 'Member'},
            //   'team': {'team_id': 1, 'name': 'Platform'}
            // }
          } else {
            print('⚠️ 员工接口返回格式异常: 未找到 list 字段');
          }
        } else {
          print('⚠️ 员工接口返回格式异常: 未找到 data 字段');
        }
      } else {
        print('❌ 获取员工列表失败: ${assigneesResponse.statusCode}');
        print('响应体: ${utf8.decode(assigneesResponse.bodyBytes)}');
      }

      // 过滤可分配的员工
      final filteredEmployees = employeeList.where((employee) {
        final employeeRoleId = employee['role']?['role_id']; // 使用正确的字段名
        final canAssign = _canAssignToUser(employeeRoleId);

        print('${canAssign ? "✅ 可分配" : "🚫 无权分配"} -> ${employee['name']} (角色ID: $employeeRoleId)');

        return canAssign;
      }).toList();

      setState(() {
        _employees = filteredEmployees;
        // 提取部门列表
        _departments = _employees
            .map((e) => e['team']?['name']?.toString() ?? '未分配团队')
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList();
        _departments.sort();
      });

      print('✅ 成功加载 ${_employees.length} 名可分配员工，${_departments.length} 个部门');

    } catch (e, stack) {
      _showError('网络请求出错：$e');
      print('💥 详细错误: $e\n$stack');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 检查当前用户是否可以分配给目标用户
  bool _canAssignToUser(int? targetRoleId) {

    if (targetRoleId == null) {
      print('⚠️ 目标角色ID为null');
      return false;
    }

    print('🔍 权限检查: 当前用户角色ID=$_currentUserRoleId, 目标角色ID=$targetRoleId');

    // 管理员可以分配给任何人
    if (_currentUserRoleId == 1) return true;

    // 经理可以分配给经理、团队领导和成员
    if (_currentUserRoleId == 2) {
      return targetRoleId == 2 || targetRoleId == 3 || targetRoleId == 4;
    }

    // 团队领导只能分配给成员
    if (_currentUserRoleId == 3) {
      return targetRoleId == 4;
    }

    return false;
  }

  /// 检查是否可以选择分配给员工
  bool _canAssignToEmployees() {
    return _currentUserRoleId == 1 || _currentUserRoleId == 2 || _currentUserRoleId == 3;
  }

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: TextStyle(
        fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
  );

  Widget _buildTaskNameField() => TextFormField(
    controller: _taskNameController,
    decoration: _inputDecoration('任务名称', Icons.task_alt),
    validator: (v) => v == null || v.isEmpty ? '请输入任务名称' : null,
  );

  Widget _buildTaskContentField() => TextFormField(
    controller: _taskContentController,
    maxLines: 4,
    decoration: _inputDecoration('任务内容', Icons.description),
    validator: (v) => v == null || v.isEmpty ? '请输入任务内容' : null,
  );

  Widget _buildPrioritySelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle('任务优先级'),
      SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE0E0E0)),
        ),
        child: DropdownButtonFormField<String>(
          value: _selectedPriority,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.flag, color: _getPriorityColor(_selectedPriority)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          items: _priorityOptions.map((priority) {
            return DropdownMenuItem(
              value: priority,
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: _getPriorityColor(priority),
                    size: 12,
                  ),
                  SizedBox(width: 8),
                  Text(priority),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedPriority = value!;
            });
          },
        ),
      ),
    ],
  );

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.blue;
      case 'High':
        return Colors.orange;
      case 'Urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: Color(0xFFFF8C42)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: Color(0xFFFFF8E1),
  );

  Widget _buildDeadlineField() => InkWell(
    onTap: _selectDeadline,
    child: Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Color(0xFFFF8C42)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedDeadline != null
                  ? '${_selectedDeadline!.year}-${_selectedDeadline!.month.toString().padLeft(2, '0')}-${_selectedDeadline!.day.toString().padLeft(2, '0')} ${_selectedDeadline!.hour.toString().padLeft(2, '0')}:${_selectedDeadline!.minute.toString().padLeft(2, '0')}'
                  : '请选择截止时间',
              style: TextStyle(
                  fontSize: 16,
                  color: _selectedDeadline != null
                      ? Color(0xFF333333)
                      : Color(0xFF999999)),
            ),
          ),
          Icon(Icons.chevron_right, color: Color(0xFF999999)),
        ],
      ),
    ),
  );

  Widget _buildTaskTypeSelector() {
    final canAssign = _canAssignToEmployees();

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          RadioListTile<String>(
            title: Text('给自己创建任务'),
            value: 'self',
            groupValue: _taskType,
            activeColor: Color(0xFFFF8C42),
            onChanged: (v) => setState(() {
              _taskType = v!;
              _selectedEmployeeIds.clear();
            }),
          ),
          Divider(height: 1, color: Color(0xFFE0E0E0)),
          RadioListTile<String>(
            title: !canAssign
                ? Row(
              children: [
                Text('分配给员工'),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '无权限',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            )
                : Text('分配给员工'),
            value: 'employee',
            groupValue: _taskType,
            activeColor: canAssign ? Color(0xFFFF8C42) : Colors.grey,
            onChanged: canAssign ? (v) => setState(() => _taskType = v!) : null,
          ),
          if (!canAssign) ...[
            Divider(height: 1, color: Color(0xFFE0E0E0)),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '您的权限级别（$_currentUserRoleName）只能创建自己的任务',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmployeeSelector() {
    if (!_canAssignToEmployees()) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            '您的权限级别无法分配任务给其他员工',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    // 获取团队列表（基于选择的部门）
    final List<String> teams = _employees
        .where((e) => _selectedDepartment == null ||
        (e['team']?['name']?.toString() ?? '未分配团队') == _selectedDepartment)
        .map((e) => e['team']?['name']?.toString() ?? '未分配团队')
        .toSet()
        .toList();

    // 筛选员工
    final filteredEmployees = _employees.where((e) {
      final matchDept = _selectedDepartment == null ||
          (e['team']?['name']?.toString() ?? '未分配团队') == _selectedDepartment;
      final matchTeam = _selectedTeam == null ||
          (e['team']?['name']?.toString() ?? '未分配团队') == _selectedTeam;
      final matchSearch = e['name']
          .toString()
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
      return matchDept && matchTeam && matchSearch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 显示当前用户权限信息
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '您的权限: $_currentUserRoleName - 可分配给同级或下级员工',
                  style: TextStyle(color: Colors.blue[800], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // 部门、团队选择器
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedDepartment,
              decoration: InputDecoration(
                labelText: '部门/团队',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text('全部部门/团队')),
                ..._departments
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
              ],
              onChanged: (v) => setState(() {
                _selectedDepartment = v;
                _selectedTeam = null;
              }),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedTeam,
              decoration: InputDecoration(
                labelText: '团队筛选',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text('全部团队')),
                ...teams.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              ],
              onChanged: (v) => setState(() => _selectedTeam = v),
            ),
          ),
        ]),
        SizedBox(height: 16),

        // 搜索框
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: '搜索员工',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 16),

        // 显示已选员工
        if (_selectedEmployeeIds.isNotEmpty) ...[
          Text('已选择 ${_selectedEmployeeIds.length} 名员工:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _selectedEmployeeIds.map((id) {
              final employee = _employees.firstWhere((e) => e['user_id'] == id);
              return Chip(
                label: Text(employee['name'] ?? ''),
                deleteIcon: Icon(Icons.close, size: 16),
                onDeleted: () => setState(() => _selectedEmployeeIds.remove(id)),
              );
            }).toList(),
          ),
          SizedBox(height: 16),
        ],

        // 员工列表
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: filteredEmployees.isEmpty
              ? Center(child: Text('没有可分配的员工'))
              : ListView.builder(
            itemCount: filteredEmployees.length,
            itemBuilder: (_, i) {
              final e = filteredEmployees[i];
              final isSelected = _selectedEmployeeIds.contains(e['user_id']);
              final employeeRoleName = e['role']?['name'] ?? '未知角色';
              final employeeRoleId = e['role']?['role_id'];
              final teamName = e['team']?['name'] ?? '未分配团队';

              return CheckboxListTile(
                title: Text(e['name'] ?? '未知姓名'),
                subtitle: Text('$teamName - $employeeRoleName'),
                value: isSelected,
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedEmployeeIds.add(e['user_id']);
                    } else {
                      _selectedEmployeeIds.remove(e['user_id']);
                    }
                  });
                },
                secondary: CircleAvatar(
                  backgroundColor: Color(0xFFFF8C42),
                  child: Text(
                    (e['name'] ?? '?').substring(0, 1),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTagSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle('标签'),
      SizedBox(height: 16),
      TextFormField(
        controller: _tagController,
        decoration: InputDecoration(
          labelText: '添加标签',
          prefixIcon: Icon(Icons.label, color: Color(0xFF4ECDC4)),
          suffixIcon: IconButton(
            icon: Icon(Icons.add, color: Color(0xFF4ECDC4)),
            onPressed: _addTag,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Color(0xFFFFF8E1),
        ),
        onFieldSubmitted: (_) => _addTag(),
      ),
      SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _selectedTags
            .map((tag) => Chip(
          label: Text(tag),
          backgroundColor: Color(0xFF4ECDC4).withOpacity(0.1),
          labelStyle:
          TextStyle(color: Color(0xFF4ECDC4), fontWeight: FontWeight.w600),
          deleteIcon: Icon(Icons.close, size: 18, color: Color(0xFF4ECDC4)),
          onDeleted: () => setState(() => _selectedTags.remove(tag)),
        ))
            .toList(),
      ),
    ],
  );

  void _addTag() {
    if (_tagController.text.trim().isNotEmpty) {
      setState(() {
        _selectedTags.add(_tagController.text.trim());
        _tagController.clear();
      });
    }
  }

  Widget _buildCreateButton() => SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      onPressed: _isCreating ? null : _createTask,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFFF8C42),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: _isCreating
          ? SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      )
          : Text('创建任务', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ),
  );

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: 18, minute: 0),
      );
      if (time != null) {
        setState(() {
          _selectedDeadline = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeadline == null) {
      _showError('请选择截止时间');
      return;
    }
    if (_taskType == 'employee' && _selectedEmployeeIds.isEmpty) {
      _showError('请选择要分配的员工');
      return;
    }

    // 权限验证 - 修复字段名问题
    if (_taskType == 'employee') {
      for (final employeeId in _selectedEmployeeIds) {
        final employee = _employees.firstWhere((e) => e['user_id'] == employeeId);
        final employeeRoleId = employee['role']?['role_id'];  // 修正字段名
        if (!_canAssignToUser(employeeRoleId)) {
          _showError('您无权分配给员工: ${employee['name']}');
          return;
        }
      }
    }

    setState(() => _isCreating = true);

    try {
      final userId = await AuthService.getSavedUserId();
      if (userId == null) {
        _showError('无法获取用户信息，请重新登录');
        return;
      }

      final List<int> assigneeIds = _taskType == 'self'
          ? [userId]
          : _selectedEmployeeIds;

      final response = await TaskService.createTask(
        userId: userId,
        title: _taskNameController.text.trim(),
        description: _taskContentController.text.trim(),
        dueAt: _selectedDeadline!,
        tags: _selectedTags,
        assigneeIds: assigneeIds,
        priority: _selectedPriority,
      );

      if (response['ok'] == true) {
        _showSuccess('任务创建成功！');
        await Future.delayed(Duration(milliseconds: 1500));
        Navigator.pop(context, true);
      } else {
        _showError(response['error'] ?? '创建任务失败');
      }
    } catch (e) {
      print('💥 创建任务异常: $e');
      _showError('创建任务失败: $e');
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('新建任务',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: Color(0xFFFF8C42),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFE66D), Color(0xFFFF8C42)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFFF8C42)))
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('基本信息'),
              SizedBox(height: 16),
              _buildTaskNameField(),
              SizedBox(height: 20),
              _buildTaskContentField(),
              SizedBox(height: 20),
              _buildPrioritySelector(),
              SizedBox(height: 20),
              _buildDeadlineField(),
              SizedBox(height: 32),
              _buildSectionTitle('任务分配'),
              SizedBox(height: 16),
              _buildTaskTypeSelector(),
              SizedBox(height: 20),
              if (_taskType == 'employee') _buildEmployeeSelector(),
              SizedBox(height: 32),
              _buildTagSelector(),
              SizedBox(height: 32),
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskContentController.dispose();
    _tagController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}