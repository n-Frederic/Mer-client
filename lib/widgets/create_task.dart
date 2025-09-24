import 'package:flutter/material.dart';

class CreateTaskScreen extends StatefulWidget {
  @override
  _CreateTaskScreenState createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _taskContentController = TextEditingController();

  DateTime? _selectedDeadline;
  String _taskType = 'self'; // 'self' or 'employee'
  String? _selectedEmployee;

  // 模拟员工数据
  final List<Map<String, String>> _employees = [
    {'id': '1', 'name': '张三', 'department': '开发部'},
    {'id': '2', 'name': '李四', 'department': '设计部'},
    {'id': '3', 'name': '王五', 'department': '产品部'},
    {'id': '4', 'name': '赵六', 'department': '测试部'},
  ];

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
                _selectedEmployee = null;
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

  Widget _buildEmployeeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.assignment_ind, color: Color(0xFFFF8C42)),
                SizedBox(width: 8),
                Text(
                  '选择员工',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Color(0xFFE0E0E0)),
          ..._employees.map((employee) => RadioListTile<String>(
            title: Text(employee['name']!),
            subtitle: Text(employee['department']!),
            value: employee['id']!,
            groupValue: _selectedEmployee,
            activeColor: Color(0xFFFF8C42),
            onChanged: (value) {
              setState(() {
                _selectedEmployee = value;
              });
            },
          )).toList(),
        ],
      ),
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

      if (_taskType == 'employee' && _selectedEmployee == null) {
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

      // 这里可以添加实际的任务创建逻辑
      String assigneeInfo = _taskType == 'self'
          ? '自己'
          : _employees.firstWhere((e) => e['id'] == _selectedEmployee)['name']!;

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
    super.dispose();
  }
}
