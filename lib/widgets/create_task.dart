import 'package:flutter/material.dart';

class CreateTaskScreen extends StatefulWidget {
  @override
  _CreateTaskScreenState createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _taskContentController = TextEditingController();
  final _tagController = TextEditingController(); // 新增：用于输入标签

  DateTime? _selectedDeadline;
  String _taskType = 'self'; // 'self' or 'employee'
  String? _selectedEmployeeId; // Changed to hold the employee's ID

  // Add new state variables for the dropdowns
  String? _selectedDepartment;
  String? _selectedTeam;
  List<String> _selectedTags = ['Q4', '紧急']; // 新增：模拟已选标签

  // Mock data for employees with hierarchy
  final List<Map<String, String>> _employees = [
    {'id': '1', 'name': '张三', 'department': '开发部', 'team': '前端团队'},
    {'id': '2', 'name': '李四', 'department': '设计部', 'team': 'UI设计'},
    {'id': '3', 'name': '王五', 'department': '产品部', 'team': '产品规划'},
    {'id': '4', 'name': '赵六', 'department': '开发部', 'team': '后端团队'},
  ];

  final List<String> _departments = ['开发部', '设计部', '产品部', '测试部'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '新建任务',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFFFF8C42),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFE66D),
                Color(0xFFFF8C42),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
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

              if (_taskType == 'employee') ...[
                _buildEmployeeSelector(),
                SizedBox(height: 32),
              ] else
                SizedBox(height: 32),

              _buildTagSelector(), // 新增：标签选择器
              SizedBox(height: 32),

              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildTaskNameField() {
    return TextFormField(
      controller: _taskNameController,
      decoration: InputDecoration(
        labelText: '任务名称',
        hintText: '请输入任务名称',
        prefixIcon: Icon(Icons.task_alt, color: Color(0xFFFF8C42)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFFF8C42), width: 2),
        ),
        filled: true,
        fillColor: Color(0xFFFFF8E1),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入任务名称';
        }
        return null;
      },
    );
  }

  Widget _buildTaskContentField() {
    return TextFormField(
      controller: _taskContentController,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: '任务内容',
        hintText: '请详细描述任务内容和要求',
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: 60),
          child: Icon(Icons.description, color: Color(0xFFFF8C42)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFFF8C42), width: 2),
        ),
        filled: true,
        fillColor: Color(0xFFFFF8E1),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入任务内容';
        }
        return null;
      },
    );
  }

  Widget _buildDeadlineField() {
    return InkWell(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '截止时间',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _selectedDeadline != null
                        ? '${_selectedDeadline!.year}-${_selectedDeadline!.month.toString().padLeft(2, '0')}-${_selectedDeadline!.day.toString().padLeft(2, '0')} ${_selectedDeadline!.hour.toString().padLeft(2, '0')}:${_selectedDeadline!.minute.toString().padLeft(2, '0')}'
                        : '请选择截止时间',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDeadline != null ? Color(0xFF333333) : Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  Widget _buildTagSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('标签'),
        SizedBox(height: 16),
        TextFormField(
          controller: _tagController,
          decoration: InputDecoration(
            labelText: '添加标签',
            hintText: '输入标签后按回车键或点击右侧图标添加',
            prefixIcon: Icon(Icons.label, color: Color(0xFF4ECDC4)),
            suffixIcon: IconButton(
              icon: Icon(Icons.add, color: Color(0xFF4ECDC4)),
              onPressed: () {
                if (_tagController.text.trim().isNotEmpty) {
                  setState(() {
                    _selectedTags.add(_tagController.text.trim());
                    _tagController.clear();
                  });
                }
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
            ),
            filled: true,
            fillColor: Color(0xFFFFF8E1),
          ),
          onFieldSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              setState(() {
                _selectedTags.add(value.trim());
                _tagController.clear();
              });
            }
          },
        ),
        SizedBox(height: 12),
        if (_selectedTags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTags.map((tag) => Chip(
              label: Text(tag),
              backgroundColor: Color(0xFF4ECDC4).withOpacity(0.1),
              labelStyle: TextStyle(color: Color(0xFF4ECDC4), fontWeight: FontWeight.w600),
              deleteIcon: Icon(Icons.close, size: 18, color: Color(0xFF4ECDC4)),
              onDeleted: () {
                setState(() {
                  _selectedTags.remove(tag);
                });
              },
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildTaskTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          RadioListTile<String>(
            title: Row(
              children: [
                Icon(Icons.person, color: Color(0xFFFF8C42), size: 20),
                SizedBox(width: 8),
                Text('给自己创建任务'),
              ],
            ),
            value: 'self',
            groupValue: _taskType,
            activeColor: Color(0xFFFF8C42),
            onChanged: (value) {
              setState(() {
                _taskType = value!;
                _selectedEmployeeId = null;
              });
            },
          ),
          Divider(height: 1, color: Color(0xFFE0E0E0)),
          RadioListTile<String>(
            title: Row(
              children: [
                Icon(Icons.group, color: Color(0xFFFF8C42), size: 20),
                SizedBox(width: 8),
                Text('分配给员工'),
              ],
            ),
            value: 'employee',
            groupValue: _taskType,
            activeColor: Color(0xFFFF8C42),
            onChanged: (value) {
              setState(() {
                _taskType = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  // Refactored to use cascading dropdowns
  Widget _buildEmployeeSelector() {
    final List<String> teams = _employees
        .where((e) => e['department'] == _selectedDepartment)
        .map((e) => e['team']!)
        .toSet()
        .toList();

    final List<Map<String, String>> members = _employees
        .where((e) => e['department'] == _selectedDepartment && e['team'] == _selectedTeam)
        .toList();

    // 根据下拉框筛选结果和搜索关键词，最终确定显示的成员列表
    final List<Map<String, String>> filteredMembers =
    (members.isEmpty && (_selectedDepartment == null && _selectedTeam == null))
        ? _employees
        : members;

    // 假设您在 _CreateTaskScreenState 中有一个用于搜索的控制器
    final _searchController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 部门、团队、人员和搜索框放在同一行
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: '部门',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                value: _selectedDepartment,
                items: _departments.map((String department) {
                  return DropdownMenuItem<String>(
                    value: department,
                    child: Text(department),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDepartment = newValue;
                    _selectedTeam = null;
                    _selectedEmployeeId = null;
                  });
                },
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: '团队',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                value: _selectedTeam,
                items: teams.map((String team) {
                  return DropdownMenuItem<String>(
                    value: team,
                    child: Text(team),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTeam = newValue;
                    _selectedEmployeeId = null;
                  });
                },
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: '员工',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                value: _selectedEmployeeId,
                items: filteredMembers.map((Map<String, String> employee) {
                  return DropdownMenuItem<String>(
                    value: employee['id'],
                    child: Text(employee['name']!),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedEmployeeId = newValue;
                  });
                },
                validator: (value) {
                  if (_taskType == 'employee' && value == null) {
                    return '请选择要分配的员工';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        // 搜索框放在另一行，因为一行放不下
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: '搜索员工',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
          ),
          onChanged: (value) {
            // 在这里处理搜索逻辑，但目前的代码中列表是静态的，所以需要手动处理
            // 如果需要实时搜索，需要将列表包装在一个 StatefulBuilder 中
          },
        ),
        SizedBox(height: 16),
        // 显示所有员工的滚动列表
        Container(
          height: 200, // 给定一个固定的高度
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            itemCount: _employees.length, // 这里显示所有员工，不进行筛选
            itemBuilder: (context, index) {
              final employee = _employees[index];
              return RadioListTile<String>(
                title: Text(employee['name']!),
                subtitle: Text('${employee['department']!} - ${employee['team']!}'),
                value: employee['id']!,
                groupValue: _selectedEmployeeId,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedEmployeeId = newValue;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _createTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFF8C42),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          '创建任务',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDeadline() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFFF8C42),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: 18, minute: 0),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Color(0xFFFF8C42),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDeadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _createTask() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDeadline == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('请选择截止时间'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      if (_taskType == 'employee' && _selectedEmployeeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('请选择要分配的员工'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      String assigneeInfo = _taskType == 'self'
          ? '自己'
          : _employees.firstWhere((e) => e['id'] == _selectedEmployeeId)['name']!;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('任务创建成功'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('任务名称: ${_taskNameController.text}'),
              SizedBox(height: 8),
              Text('分配给: $assigneeInfo'),
              SizedBox(height: 8),
              Text('截止时间: ${_selectedDeadline!.year}-${_selectedDeadline!.month.toString().padLeft(2, '0')}-${_selectedDeadline!.day.toString().padLeft(2, '0')} ${_selectedDeadline!.hour.toString().padLeft(2, '0')}:${_selectedDeadline!.minute.toString().padLeft(2, '0')}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('确定', style: TextStyle(color: Color(0xFFFF8C42))),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskContentController.dispose();
    _tagController.dispose();
    super.dispose();
  }
}