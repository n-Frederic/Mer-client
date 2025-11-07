// lib/widgets/eisenhower_matrix.dart

import 'package:flutter/material.dart';
import '../services/eisenhower_matrix_service.dart';
import '../models/eisenhower_matrix_model.dart';

class EisenhowerMatrix extends StatefulWidget {
  @override
  _EisenhowerMatrixState createState() => _EisenhowerMatrixState();
}

class _EisenhowerMatrixState extends State<EisenhowerMatrix> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _cardAnimations;

  final EisenhowerMatrixService _service = EisenhowerMatrixService();
  final int _userId = 1; // 实际应用中应从登录信息获取

  EisenhowerMatrixData _data = EisenhowerMatrixData.empty();
  bool _isExpanded = false; // 控制广告内容展开/收起

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAllData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardAnimations = List.generate(4, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.2, 1.0, curve: Curves.easeOutBack),
        ),
      );
    });
  }

  // 加载所有数据
  Future<void> _loadAllData() async {
    _updateData(isLoading: true);

    try {
      final results = await Future.wait([
        _service.getCompanyImportantTasks(),
        _service.getCompanyAssignedTasks(priority: '高'),
        _loadPersonalTasksWithFallback(),
        _service.getPersonalLogs(),
      ]);

      _updateData(
        companyImportantTasks: results[0],
        companyAssignedTasks: results[1],
        personalImportantTasks: results[2],
        personalLogs: results[3],
        isLoading: false,
      );

      _animationController.forward();
    } catch (e) {
      _updateData(isLoading: false);
      _showErrorSnackBar("数据加载失败: $e");
    }
  }

  // 加载个人任务，如果没有则创建默认任务
  Future<List<String>> _loadPersonalTasksWithFallback() async {
    try {
      final tasks = await _service.getPersonalTasks(_userId);
      if (tasks.isEmpty) {
        final defaultTasks = [
          "阅读30分钟技术书籍",
          "整理代码仓库",
          "撰写开发日志"
        ];
        return await _service.createPersonalTasks(_userId, defaultTasks);
      }
      return tasks;
    } catch (e) {
      print('Error in personal tasks fallback: $e');
      return []; // 返回空列表，UI会显示"暂无数据"
    }
  }

  // 更新个人任务
  Future<void> _updatePersonalTasks(List<String> newTasks) async {
    try {
      final updatedTasks = await _service.updatePersonalTasks(_userId, newTasks);
      _updateData(personalImportantTasks: updatedTasks);
      _showSuccessSnackBar('个人重要事项已更新');
    } catch (e) {
      _showErrorSnackBar('更新失败: $e');
    }
  }

  // 刷新数据
  Future<void> _refreshData() async {
    _updateData(isLoading: true);
    await _loadAllData();
    _showSuccessSnackBar("数据已刷新");
  }

  // 更新数据辅助方法
  void _updateData({
    List<String>? companyImportantTasks,
    List<String>? companyAssignedTasks,
    List<String>? personalImportantTasks,
    List<String>? personalLogs,
    bool? isLoading,
  }) {
    setState(() {
      _data = _data.copyWith(
        companyImportantTasks: companyImportantTasks,
        companyAssignedTasks: companyAssignedTasks,
        personalImportantTasks: personalImportantTasks,
        personalLogs: personalLogs,
        isLoading: isLoading,
      );
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 广告卡片 - 限制高度
            Container(
              height: 200, // 固定高度
              child: Row(
                children: [
                  IconButton(
                    onPressed: _refreshData,
                    icon: _data.isLoading
                        ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Icon(Icons.refresh),
                    tooltip: '刷新数据',
                  ),
                  Expanded(child: _buildAdCard()),
                ],
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: _data.isLoading
                  ? Center(child: CircularProgressIndicator())
                  : GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.7,
                children: [
                  _buildQuadrantCard(
                    title: "公司重要事项",
                    emoji: "🏢",
                    color: Color(0xFFFF6B9D),
                    items: _data.companyImportantTasks,
                    isReadOnly: true,
                    animation: _cardAnimations[0],
                    onTap: () => _showTaskDetails("公司重要事项", _data.companyImportantTasks),
                  ),
                  _buildQuadrantCard(
                    title: "公司派发任务",
                    emoji: "📋",
                    color: Color(0xFF4ECDC4),
                    items: _data.companyAssignedTasks,
                    isReadOnly: true,
                    animation: _cardAnimations[1],
                    onTap: () => _showTaskDetails("公司派发任务", _data.companyAssignedTasks),
                  ),
                  _buildQuadrantCard(
                    title: "个人重要事项",
                    emoji: "⭐",
                    color: Color(0xFF88D8B0),
                    items: _data.personalImportantTasks,
                    isReadOnly: false,
                    animation: _cardAnimations[2],
                    onTap: _editPersonalTasks,
                  ),
                  _buildQuadrantCard(
                    title: "个人日志",
                    emoji: "📝",
                    color: Color(0xFFFFCC80),
                    items: _data.personalLogs,
                    isReadOnly: true,
                    animation: _cardAnimations[3],
                    onTap: () => _showTaskDetails("个人日志", _data.personalLogs),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== Ad Card ======
  Widget _buildAdCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和展开/收起按钮
            Row(
              children: [
                Text(
                  "🚀 WELCOME TO MER!",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),

            // 广告内容
            Expanded(
              child: _isExpanded
                  ? _buildScrollableAdContent()
                  : _buildAdSummary(),
            ),
          ],
        ),
      ),
    );
  }

  // 可滚动的完整广告内容
  Widget _buildScrollableAdContent() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: _buildFullAdContent(),
    );
  }

  // 广告摘要视图
  Widget _buildAdSummary() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "还在为「人间理想」和「诗和远方」感到羞愧吗？别担心——在我们公司，我们直接跳过幻想，拥抱美好生活！",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          Text(
            "→",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // 完整广告内容
  Widget _buildFullAdContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🐮🐴 关于我们
        _buildAdSection(
          "🐮🐴 About us：",
          [
            "成立20天，累计为员工发放过3次「感动中国好员工」手写奖状",
            "独家开创「24小时云端待机工作法」（注：半夜收到老板语音别慌，只是测测你睡了没）",
            "本月最新福利：把公司WiFi密码改为「ILOVEWORK!」",
          ],
        ),

        SizedBox(height: 8),

        // 🎯 我们需要这样的你
        _buildAdSection(
          "🎯 我们需要这样的你：",
          [
            "熟练掌握「用一杯咖啡熬过16小时」的生存技能",
            "能把「我马上改」说出108种不同语气",
            "对「加班」二字有超越常人的哲学理解",
            "无需休息，随时上机",
          ],
        ),

        SizedBox(height: 8),

        // 💼 你将获得
        _buildAdSection(
          "💼 你将获得：",
          [
            "zxc组长周末的贴心问候（随时随地，随叫随到）",
            "无限量供应的工作热情（及yf611无限电量供应）",
            "亲眼见证凌晨四点bjtu的机会（全年约365次的机会，先到先得）",
            "苏老师亲授《专业课程实训》大师课",
          ],
        ),

        SizedBox(height: 8),

        // 👑 特别惊喜
        _buildAdSection(
          "👑 特别惊喜：",
          [
            "年度优秀员工将获得——A++++++完美成绩！",
          ],
        ),

        SizedBox(height: 8),

        // 💌 应聘须知
        _buildAdSection(
          "💌 应聘须知：",
          [
            "请把简历送往 2625791372@qq.com",
            "（收到自动回复「你的肝还好吗？」即表示投递成功）",
          ],
        ),

        SizedBox(height: 8),

        // 🌚 最后温馨提示
        _buildAdSection(
          "🌚 最后温馨提示：",
          [
            "如果看完这则广告你居然笑了——",
            "恭喜！你已经具备在MER公司笑对风云的珍贵品质",
          ],
        ),

        SizedBox(height: 8),

        Text(
          "（注：本广告最终解释权归本公司所有，以及，我们真的在招人——毕竟上个月又猝走了两个）",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // 广告部分组件
  Widget _buildAdSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        ...items.map((item) => Padding(
          padding: EdgeInsets.only(bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "• ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  // ====== Quadrant Card ======
  Widget _buildQuadrantCard({
    required String title,
    required String emoji,
    required Color color,
    required List<String> items,
    required bool isReadOnly,
    required Animation<double> animation,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ScaleTransition(
        scale: animation,
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji, style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color.withOpacity(0.8),
                        ),
                      ),
                    ),
                    Icon(
                      isReadOnly ? Icons.visibility : Icons.edit,
                      size: 16,
                      color: color.withOpacity(0.6),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                    child: Text(
                      "暂无数据",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                      : ListView.builder(
                    itemCount: items.length > 4 ? 4 : items.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              margin: EdgeInsets.only(top: 6, right: 8),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                items[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (items.length > 4)
                  Center(
                    child: Text(
                      "查看全部 ${items.length} 项",
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ====== Show Details Dialog ======
  void _showTaskDetails(String title, List<String> items) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                radius: 12,
              ),
              title: Text(items[index]),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }

  // ====== Edit Personal Tasks ======
  void _editPersonalTasks() {
    showDialog(
      context: context,
      builder: (context) => PersonalTasksEditor(
        tasks: List.from(_data.personalImportantTasks),
        onSave: (newTasks) async {
          await _updatePersonalTasks(newTasks);
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _service.dispose();
    super.dispose();
  }
}

// ====== PersonalTasksEditor ======
class PersonalTasksEditor extends StatefulWidget {
  final List<String> tasks;
  final Function(List<String>) onSave;

  const PersonalTasksEditor({
    Key? key,
    required this.tasks,
    required this.onSave,
  }) : super(key: key);

  @override
  _PersonalTasksEditorState createState() => _PersonalTasksEditorState();
}

class _PersonalTasksEditorState extends State<PersonalTasksEditor> {
  late List<TextEditingController> _controllers;
  final TextEditingController _newTaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controllers = widget.tasks.map((task) => TextEditingController(text: task)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.star, color: Color(0xFF88D8B0)),
          SizedBox(width: 8),
          Text('编辑个人重要事项'),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._controllers.asMap().entries.map((entry) {
                int index = entry.key;
                TextEditingController controller = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: '事项 ${index + 1}',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _controllers.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTaskController,
                      decoration: InputDecoration(
                        labelText: '添加新事项',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.green),
                    onPressed: () {
                      if (_newTaskController.text.trim().isNotEmpty) {
                        setState(() {
                          _controllers.add(TextEditingController(text: _newTaskController.text.trim()));
                          _newTaskController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final newTasks = _controllers
                .map((controller) => controller.text.trim())
                .where((task) => task.isNotEmpty)
                .toList();

            widget.onSave(newTasks);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF88D8B0),
          ),
          child: Text('保存'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _newTaskController.dispose();
    super.dispose();
  }
}