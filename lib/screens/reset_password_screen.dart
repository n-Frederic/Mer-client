import 'dart:async'; // 【新增】用于倒计时
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email; // 接收从登录页传来的邮箱

  const ResetPasswordScreen({Key? key, required this.email}) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // 【新增】三个控制器
  late TextEditingController _emailController;
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isLoading = false; // "确认重置" 按钮的加载状态
  bool _isSendingCode = false; // "发送验证码" 按钮的加载状态

  // 【新增】倒计时器
  Timer? _timer;
  int _countdown = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email); // 自动填充邮箱

    // 【复用】动画
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _animationController.forward();
  }

  // 【新增】封装的 SnackBar 提示
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // 【新增】发送验证码的逻辑 (API A)
  void _sendVerificationCode() async {
    // 验证邮箱是否有效
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar("请输入有效的邮箱地址", isError: true);
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    // 调用 API
    final result = await AuthService.sendVerificationCode(email);
    _showSnackBar(result['message'], isError: !result['ok']);

    if (result['ok']) {
      // 开始倒计时
      setState(() {
        _countdown = 60;
      });
      _timer?.cancel(); // 取消上一个计时器
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_countdown > 0) {
          setState(() {
            _countdown--;
          });
        } else {
          timer.cancel();
          setState(() {
            _isSendingCode = false; // 倒计时结束，允许重发
          });
        }
      });
    } else {
      setState(() {
        _isSendingCode = false;
      });
    }
  }

  // 【新增】重置密码的逻辑 (API B)
  void _resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // 验证失败
    }

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.resetPassword(
      email: _emailController.text.trim(),
      code: _codeController.text.trim(),
      newPassword: _newPasswordController.text.trim(),
    );

    _showSnackBar(result['message'], isError: !result['ok']);

    setState(() {
      _isLoading = false;
    });

    // 如果成功，返回登录页
    if (result['ok']) {
      if (!mounted) return;
      Navigator.pop(context); // 关闭此页面
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- 【⬇️ 新增：AppBar ⬇️】 ---
      appBar: AppBar(
        // 使 AppBar 透明
        backgroundColor: Colors.transparent,
        elevation: 0,
        // 添加返回按钮（它会自动处理 Navigator.pop）
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // --- 【⬆️ 新增结束 ⬆️】 ---

      // --- 【新增：让 body 延伸到 AppBar 后面】 ---
      extendBodyBehindAppBar: true,

      body: Container(
        // 【复用】保持完全相同的渐变背景
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE66D),
              Color(0xFFFF8C42),
              Color(0xFFFF6B9D),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 【复用】Logo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8),),]),
                        child: Center(child: Text('🔑', style: TextStyle(fontSize: 60))),
                      ),
                      SizedBox(height: 32),

                      // 【复用】标题
                      Text('重置密码', style: TextStyle(fontFamily: 'DancingScript', fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4,)])),
                      SizedBox(height: 8),
                      Text('请验证您的邮箱以重置密码', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
                      SizedBox(height: 48),

                      // 【复用】卡片
                      Card(
                        elevation: 16,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // --- 【⬇️ 3个新字段 ⬇️】 ---
                                TextFormField(
                                  controller: _emailController, // 自动填充
                                  decoration: InputDecoration(
                                    labelText: '邮箱',
                                    prefixIcon: Icon(Icons.email, color: Color(0xFFFF8C42)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Color(0xFFFF8C42))),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Color(0xFFFF8C42), width: 2)),
                                    filled: true,
                                    fillColor: Color(0xFFFFF8E1),
                                  ),
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return '请输入邮箱';
                                    }
                                    if (!value!.contains('@')) {
                                      return '请输入有效的邮箱';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 20),

                                // 【验证码 + 发送按钮】
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _codeController,
                                        decoration: InputDecoration(
                                          labelText: '验证码',
                                          prefixIcon: Icon(Icons.shield, color: Color(0xFFFF8C42)),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Color(0xFFFF8C42))),
                                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Color(0xFFFF8C42), width: 2)),
                                          filled: true,
                                          fillColor: Color(0xFFFFF8E1),
                                        ),
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return '请输入验证码';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    // 【发送验证码按钮】
                                    SizedBox(
                                      height: 58, // 匹配输入框高度
                                      child: ElevatedButton(
                                        onPressed: (_isSendingCode || _countdown > 0) ? null : _sendVerificationCode,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFFFF8C42).withOpacity(0.1),
                                          foregroundColor: Color(0xFFFF8C42),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          elevation: 0,
                                        ),
                                        child: _isSendingCode
                                            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                            : Text(_countdown > 0 ? '$_countdown s' : '发送'),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),

                                TextFormField(
                                  controller: _newPasswordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: '新密码',
                                    prefixIcon: Icon(Icons.lock_reset, color: Color(0xFFFF8C42)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Color(0xFFFF8C42))),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Color(0xFFFF8C42), width: 2)),
                                    filled: true,
                                    fillColor: Color(0xFFFFF8E1),
                                  ),
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return '请输入新密码';
                                    }
                                    if (value!.length < 6) {
                                      return '密码至少需要6位';
                                    }
                                    return null;
                                  },
                                ),
                                // --- 【⬆️ 新字段结束 ⬆️】 ---
                                SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _resetPassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFFF8C42),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 8,
                                    ),
                                    child: _isLoading
                                        ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                        : Text(
                                      '确认重置',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose(); // 销毁
    _codeController.dispose();
    _newPasswordController.dispose();
    _timer?.cancel(); // 销毁计时器
    super.dispose();
  }
}