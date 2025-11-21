import 'package:flutter/material.dart';
import '../screens/reset_password_screen.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'profile_child_screen/personal_info_screen.dart';
import 'profile_child_screen/notifications_screen.dart';
import 'profile_child_screen/theme_settings_screen.dart';
import 'profile_child_screen/language_settings_screen.dart';
import 'profile_child_screen/help_center_screen.dart';
import 'profile_child_screen/about_app_screen.dart';

class ProfileView extends StatefulWidget {
  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Future<Map<String, dynamic>> _profileFuture;
  String? _currentUserEmail;
  bool _isSendingCode = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
    _profileFuture = ProfileService.getUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF8E1),
            Color(0xFFFFE66D).withOpacity(0.3),
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // 用户信息卡片
            FutureBuilder<Map<String, dynamic>>(
              future: _profileFuture, // (这在 initState 中设置)
              builder: (context, snapshot) {

                // 1. 设置默认占位符
                String name = '加载中...';
                String subtitle = '...';
                String email = '';
                String phone = '';

                if (snapshot.hasData) {
                  // 2. 加载成功: 解析数据
                  final userData = snapshot.data?['user'] as Map<String, dynamic>?;

                  name = userData?['name']?.toString() ?? '未知姓名';
                  subtitle = userData?['team']?.toString() ?? '潘多拉成员';
                  email = userData?['email']?.toString() ?? '';
                  phone = userData?['phone']?.toString() ?? '';

                  if (_currentUserEmail == null && email.isNotEmpty) {
                    _currentUserEmail = email;
                  }

                } else if (snapshot.hasError) {
                  // 3. 加载失败
                  name = '加载失败';
                  subtitle = '请检查网络连接';
                }

                return Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF8C42), Color(0xFFFF6B9D)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // (头像已按你要求移除)

                      // 姓名
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12),
                      if (email.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.email_outlined, color: Colors.white70, size: 16),
                              SizedBox(width: 6),
                              Text(
                                email,
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      if (phone.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone_android, color: Colors.white70, size: 16),
                              SizedBox(width: 6),
                              Text(
                                phone,
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // 功能菜单
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildMenuItem(
                    Icons.person,
                    '个人信息',
                    '查看和编辑个人资料',
                    Color(0xFF4ECDC4),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PersonalInfoScreen()),
                    ),
                  ),
                  _buildMenuItem(
                    Icons.lock_reset, // (锁图标)
                    '修改密码',
                    '重置您的登录密码',
                    Colors.orangeAccent,
                    // 点击时调用 _changePassword (如果正在发送，则不响应)
                    onTap: _isSendingCode ? null : _changePassword,
                  ),
                  _buildMenuItem(
                    Icons.notifications,
                    '消息通知',
                    '通知设置和消息管理',
                    Color(0xFFFFE66D),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotificationsScreen()),
                    ),
                  ),
                  _buildMenuItem(
                    Icons.palette,
                    '主题设置',
                    '个性化界面设置',
                    Color(0xFF88D8B0),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ThemeSettingsScreen()),
                    ),
                  ),
                  _buildMenuItem(
                    Icons.language,
                    '语言设置',
                    '选择应用语言',
                    Color(0xFFB8A9FF),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LanguageSettingsScreen()),
                    ),
                  ),
                  _buildMenuItem(
                    Icons.help,
                    '帮助中心',
                    '使用帮助和常见问题',
                    Color(0xFFFFB3BA),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => HelpCenterScreen()),
                    ),
                  ),
                  _buildMenuItem(
                    Icons.info,
                    '关于应用',
                    '版本信息和更新日志',
                    Color(0xFFA8E6CF),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AboutAppScreen()),
                    ),
                  ),
                ],
              ),
            ),

            // 退出登录按钮
            Container(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 32),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showLogoutDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      '退出登录',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changePassword() {
    if (_currentUserEmail == null || _currentUserEmail!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('数据加载中，请稍后再试'), backgroundColor: Colors.orange),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResetPasswordScreen(email: _currentUserEmail!),
      ),
    );
  }

  Widget _buildMenuItem(
      IconData icon,
      String title,
      String subtitle,
      Color color, {
        VoidCallback? onTap,
      }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Color(0xFF999999)),
        onTap: onTap ??
                () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title 功能开发中...'),
                  backgroundColor: color,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
      ),
    );
  }

  Widget _buildAchievementItem(String emoji, String title, String description) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 32)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333))),
                Text(description,
                    style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('确认退出'),
        content: Text('您确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('退出', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
