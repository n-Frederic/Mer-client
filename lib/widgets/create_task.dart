import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/task_service.dart';
import '../services/auth_service.dart';

class CreateTaskScreen extends StatefulWidget {
  @override
  _CreateTaskScreenState createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _taskContentController = TextEditingController();
  final _tagController = TextEditingController();

  DateTime? _selectedDeadline;
  String _taskType = 'self'; // 'self' or 'employee'
  List<int> _selectedEmployeeIds = [];

  String? _selectedDepartment;
  String? _selectedTeam;
  List<String> _selectedTags = [];

  bool _isLoading = false;
  bool _isCreating = false;

  List<Map<String, dynamic>> _employees = [];
  List<String> _departments = [];
  final _searchController = TextEditingController();

  // 添加缺失的方法
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
    _fetchAssignees();
  }

  /// 获取员工数据
  Future<void> _fetchAssignees() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getSavedToken();
      if (token == null) {
        _showError('用户未登录，请重新登录');
        return;
      }

      print('🔑 使用Token: ${token.substring(0, 20)}...');

      final url = Uri.parse('http://127.0.0.1:8080/api/tasks/assignees');
      print('🌐 请求员工列表URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 获取员工响应状态码: ${response.statusCode}');
      print('📡 获取员工响应体: ${utf8.decode(response.bodyBytes)}');

      List<Map<String, dynamic>> employeeList = [];

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('list')) {
          employeeList = List<Map<String, dynamic>>.from(data['list']);
        }
      }

      // 如果后端返回空数据，使用临时测试数据
      if (employeeList.isEmpty) {
        print('⚠️ 后端返回空员工列表，使用临时测试数据');
        employeeList = [
          {
            'id': 3,
            'name': '张明',
            'department': '技术部',
            'team': 'React前端组',
            'email': 'zhangming@example.com'
          },
          {
            'id': 4,
            'name': '李华',
            'department': '技术部',
            'team': 'Vue前端组',
            'email': 'lihua@example.com'
          },
          {
            'id': 5,
            'name': '王强',
            'department': '技术部',
            'team': 'Java后端组',
            'email': 'wangqiang@example.com'
          },
          {
            'id': 6,
            'name': '刘芳',
            'department': '技术部',
            'team': 'Python后端组',
            'email': 'liufang@example.com'
          }
        ];
      }

      setState(() {
        _employees = employeeList;
        _departments = _employees
            .map((e) => e['department']?.toString() ?? '未分配部门')
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList();
        _departments.sort();
      });

      print('✅ 成功加载 ${_employees.length} 名员工，${_departments.length} 个部门');

    } catch (e) {
      _showError('网络请求出错：$e');
      print('错误详情: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: Color(0xFFFF8C42)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: Color(0xFFFFF8E1),
  );

  // 添加缺失的构建方法
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

  Widget _buildTaskTypeSelector() => Container(
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
          title: Text('分配给员工'),
          value: 'employee',
          groupValue: _taskType,
          activeColor: Color(0xFFFF8C42),
          onChanged: (v) => setState(() => _taskType = v!),
        ),
      ],
    ),
  );

  Widget _buildEmployeeSelector() {
    final List<String> teams = _employees
        .where((e) => _selectedDepartment == null || e['department'] == _selectedDepartment)
        .map((e) => e['team']?.toString() ?? '未分配团队')
        .toSet()
        .toList();

    final filteredEmployees = _employees.where((e) {
      final matchDept = _selectedDepartment == null || e['department'] == _selectedDepartment;
      final matchTeam = _selectedTeam == null || e['team'] == _selectedTeam;
      final matchSearch = e['name']
          .toString()
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
      return matchDept && matchTeam && matchSearch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedDepartment,
              decoration: InputDecoration(
                labelText: '部门',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text('全部部门')),
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
                labelText: '团队',
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
              final employee = _employees.firstWhere((e) => e['id'] == id);
              return Chip(
                label: Text(employee['name'] ?? ''),
                deleteIcon: Icon(Icons.close, size: 16),
                onDeleted: () => setState(() => _selectedEmployeeIds.remove(id)),
              );
            }).toList(),
          ),
          SizedBox(height: 16),
        ],

        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            itemCount: filteredEmployees.length,
            itemBuilder: (_, i) {
              final e = filteredEmployees[i];
              final isSelected = _selectedEmployeeIds.contains(e['id']);

              return CheckboxListTile(
                title: Text(e['name'] ?? '未知姓名'),
                subtitle: Text('${e['department'] ?? '未分配部门'} - ${e['team'] ?? '未分配团队'}'),
                value: isSelected,
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedEmployeeIds.add(e['id']);
                    } else {
                      _selectedEmployeeIds.remove(e['id']);
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

    setState(() => _isCreating = true);

    try {
      // 获取当前用户ID
      final userId = await AuthService.getSavedUserId();
      print('🔍 创建任务时获取的用户ID: $userId');

      if (userId == null) {
        _showError('无法获取用户信息，请重新登录');
        return;
      }

      // 准备assigneeIds
      final List<int> assigneeIds = _taskType == 'self'
          ? [userId]  // 给自己创建任务
          : _selectedEmployeeIds; // 分配给选中的员工

      print('🎯 任务分配信息:');
      print('  任务类型: $_taskType');
      print('  分配员工IDs: $assigneeIds');
      print('  当前用户ID: $userId');

      // 调用TaskService创建任务
      final response = await TaskService.createTask(
        userId: userId,
        title: _taskNameController.text.trim(),
        description: _taskContentController.text.trim(),
        dueAt: _selectedDeadline!,
        tags: _selectedTags,
        assigneeIds: assigneeIds,
        priority: "Medium",
      );

      print('📥 创建任务响应: $response');

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