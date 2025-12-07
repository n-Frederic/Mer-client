import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';

class PersonalInfoScreen extends StatefulWidget {
  @override
  _PersonalInfoScreenState createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;

  String _selectedGender = '未选择';
  DateTime? _selectedBirthDate;
  bool _isLoading = true;
  String _errorMessage = '';

  // 存储从后端获取的完整用户信息
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _loadUserDataFromBackend();
  }

  // 从后端加载用户数据
  Future<void> _loadUserDataFromBackend() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final responseData = await ProfileService.getUserProfile();
      final userData = responseData['user'] ?? {};

      setState(() {
        _userData = userData;
        _nameController.text = userData['name'] ?? '小兔子';
        _emailController.text = userData['email'] ?? 'bunny@pandora.com';
        _phoneController.text = userData['phone'] ?? '13800138000';
        _bioController.text = userData['bio'] ?? '高效工作者 ✨';

        // 处理性别：将后端的英文格式转换为中文显示
        final gender = userData['gender'];
        if (gender == 'M') {
          _selectedGender = '男';
        } else if (gender == 'W') {
          _selectedGender = '女';
        } else {
          _selectedGender = '未选择';
        }

        // 处理出生日期 - 适配后端格式
        if (userData['birth_date'] != null) {
          try {
            // 处理可能的 LocalDateTime 格式
            String birthDateStr = userData['birth_date'].toString();
            if (birthDateStr.contains('T')) {
              _selectedBirthDate = DateTime.tryParse(birthDateStr);
            } else {
              // 如果是纯日期格式，添加时间部分
              _selectedBirthDate = DateTime.tryParse('${birthDateStr}T00:00:00');
            }
          } catch (e) {
            print('Error parsing birth date: $e');
          }
        }

        _isLoading = false;
      });

      // 同时保存到本地缓存
      await _saveToLocalStorage();

    } catch (e) {
      setState(() {
        _errorMessage = '加载用户信息失败: $e';
        _isLoading = false;
      });
      // 如果后端加载失败，尝试从本地缓存加载
      await _loadFromLocalStorage();
    }
  }

  // 从本地存储加载数据（备用）
  Future<void> _loadFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '小兔子';
      _emailController.text = prefs.getString('user_email') ?? 'bunny@pandora.com';
      _phoneController.text = prefs.getString('user_phone') ?? '13800138000';
      _bioController.text = prefs.getString('user_bio') ?? '高效工作者 ✨';
      _selectedGender = prefs.getString('user_gender') ?? '未选择';

      final birthDateStr = prefs.getString('user_birth');
      if (birthDateStr != null && birthDateStr.isNotEmpty) {
        _selectedBirthDate = DateTime.tryParse(birthDateStr);
      }
    });
  }

  // 保存到本地存储
  Future<void> _saveToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text);
    await prefs.setString('user_email', _emailController.text);
    await prefs.setString('user_phone', _phoneController.text);
    await prefs.setString('user_bio', _bioController.text);
    await prefs.setString('user_gender', _selectedGender);
    if (_selectedBirthDate != null) {
      await prefs.setString('user_birth', _selectedBirthDate!.toIso8601String());
    }
  }

  // 将中文性别转换为后端需要的格式
  String _convertGenderToBackendFormat(String gender) {
    switch (gender) {
      case '男':
        return 'M';
      case '女':
        return 'W';
      case '其他':
        return 'O';
      default:
        return '';
    }
  }

  // 格式化日期为后端需要的 LocalDateTime 格式
  String _formatDateForBackend(DateTime? date) {
    if (date == null) return '';
    // 后端期望 LocalDateTime 格式：YYYY-MM-DD
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('个人信息'),
        backgroundColor: Color(0xFFFF8C42),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(

        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFFFF8C42)))
            : _errorMessage.isNotEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserDataFromBackend,
                child: Text('重试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF8C42),
                ),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              _buildReadOnlyField('姓名', _nameController),
              SizedBox(height: 16),
              _buildReadOnlyField('邮箱', _emailController),
              SizedBox(height: 16),

              // 电话字段
              _buildEditField('电话', _phoneController),
              SizedBox(height: 16),

              _buildGenderSelector(),
              SizedBox(height: 16),

              _buildBirthDatePicker(),
              SizedBox(height: 16),

              // 个人简介字段
              _buildEditField('个人简介', _bioController, maxLines: 3),
              SizedBox(height: 32),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveUserData,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Color(0xFFFF8C42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    '保存修改',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity, // 【新增】确保填满宽度
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            controller.text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '性别',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: DropdownButton<String>(
            value: _selectedGender,
            isExpanded: true,
            underline: SizedBox(),
            padding: EdgeInsets.symmetric(horizontal: 16),
            items: ['未选择', '男', '女', '其他']
                .map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            })
                .toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedGender = newValue;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBirthDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '出生日期',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedBirthDate ?? DateTime.now(),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Color(0xFFFF8C42),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _selectedBirthDate = picked;
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedBirthDate != null
                      ? '${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}'
                      : '请选择出生日期',
                  style: TextStyle(
                    fontSize: 14,
                    color: _selectedBirthDate != null
                        ? Color(0xFF333333)
                        : Colors.grey[500],
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: Color(0xFFFF8C42),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveUserData() async {
    // 1. 前端校验 (保持之前加的)
    if (_selectedGender == '未选择' || _selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('请填写完整信息'), backgroundColor: Colors.red));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 2. 格式化日期 (关键修复：只取 YYYY-MM-DD)
      String formattedDate = '${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}';

      // 3. 构建请求数据
      final profileData = {
        'phone': _phoneController.text,
        'bio': _bioController.text,
        'gender': _convertGenderToBackendFormat(_selectedGender),
        'birth_date': formattedDate,
        'role_id': int.tryParse(_userData['role_id'].toString()) ?? 1,
        'name': _nameController.text,
        'email': _emailController.text,
      };

      print('准备发送的数据: $profileData');

      final success = await ProfileService.updateUserProfile(profileData);

      if (success) {
        await _loadUserDataFromBackend();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ 个人信息已保存'), backgroundColor: Color(0xFF4ECDC4)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ 保存失败: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}