import 'package:flutter/material.dart';

class EisenhowerMatrix extends StatefulWidget {
  @override
  _EisenhowerMatrixState createState() => _EisenhowerMatrixState();
}

class _EisenhowerMatrixState extends State<EisenhowerMatrix> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _cardAnimations;
  String _personalNote = "今天要专注完成重要任务，保持高效工作状态！ 💪";
  bool _isEditingNote = false;
  final TextEditingController _noteController = TextEditingController();

  // 模拟的静态数据
  List<String> _companyImportantTasks = [
    "优化项目架构",
    "完成季度汇报",
    "客户方案设计",
    "团队例会准备"
  ];

  List<String> _companyAssignedTasks = [
    "完成UI重构任务",
    "撰写项目文档",
    "测试接口联调",
  ];

  List<String> _personalImportantTasks = [
    "阅读30分钟技术书籍",
    "整理代码仓库",
    "撰写开发日志"
  ];

  List<String> _personalLogs = [
    "今日进展良好，完成主要任务",
    "尝试了新UI动画方案",
    "优化了接口响应速度"
  ];

  bool _isLoading = false; // 不再从接口加载

  @override
  void initState() {
    super.initState();
    _noteController.text = _personalNote;
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

    _animationController.forward(); // 直接播放动画
  }

  Future<void> _refreshData() async {
    // 模拟刷新动作
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("数据已刷新（静态示例）")),
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
            Row(
              children: [
                IconButton(
                  onPressed: _refreshData,
                  icon: Icon(Icons.refresh),
                  tooltip: '刷新数据',
                ),
                Expanded(child: _buildPersonalNoteCard()),
              ],
            ),
            SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.7,
                children: [
                  _buildQuadrantCard(
                    title: "公司10大重要事项",
                    emoji: "🏢",
                    color: Color(0xFFFF6B9D),
                    items: _companyImportantTasks,
                    isReadOnly: true,
                    animation: _cardAnimations[0],
                    onTap: () => _showTaskDetails("公司重要事项", _companyImportantTasks),
                  ),
                  _buildQuadrantCard(
                    title: "公司10大派发任务",
                    emoji: "📋",
                    color: Color(0xFF4ECDC4),
                    items: _companyAssignedTasks,
                    isReadOnly: true,
                    animation: _cardAnimations[1],
                    onTap: () => _showTaskDetails("公司派发任务", _companyAssignedTasks),
                  ),
                  _buildQuadrantCard(
                    title: "个人10大重要事项",
                    emoji: "⭐",
                    color: Color(0xFF88D8B0),
                    items: _personalImportantTasks,
                    isReadOnly: false,
                    animation: _cardAnimations[2],
                    onTap: _editPersonalTasks,
                  ),
                  _buildQuadrantCard(
                    title: "个人日志",
                    emoji: "📝",
                    color: Color(0xFFFFCC80),
                    items: _personalLogs,
                    isReadOnly: true,
                    animation: _cardAnimations[3],
                    onTap: () => _showTaskDetails("个人日志", _personalLogs),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== Personal Note Card ======
  Widget _buildPersonalNoteCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE66D), Color(0xFFFF8C42)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "📝 个人备注",
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
                      _isEditingNote = !_isEditingNote;
                      if (!_isEditingNote) {
                        _personalNote = _noteController.text;
                      }
                    });
                  },
                  icon: Icon(
                    _isEditingNote ? Icons.check : Icons.edit,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            _isEditingNote
                ? TextField(
              controller: _noteController,
              maxLines: 2,
              style: TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "添加个人备注...",
                hintStyle: TextStyle(color: Colors.white70),
              ),
            )
                : Text(
              _personalNote,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
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
        tasks: List.from(_personalImportantTasks),
        onSave: (newTasks) async {
          setState(() {
            _personalImportantTasks = newTasks;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('个人重要事项已更新（本地示例）')),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _noteController.dispose();
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
