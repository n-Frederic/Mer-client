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

    _animationController.forward();
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
            // 个人备注区域
            _buildPersonalNoteCard(),
            SizedBox(height: 12),

            // 四象限矩阵
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.7, // 调整宽高比，拉长卡片
                children: [
                  _buildQuadrantCard(
                    title: "公司10大重要事项",
                    emoji: "🏢",
                    color: Color(0xFFFF6B9D),
                    items: [
                      "Q4季度业绩目标达成",
                      "新产品发布准备",
                      "客户满意度提升项目",
                      "团队建设活动",
                      "技术架构升级",
                    ],
                    isReadOnly: true,
                    animation: _cardAnimations[0],
                  ),
                  _buildQuadrantCard(
                    title: "公司10大派发任务",
                    emoji: "📋",
                    color: Color(0xFF4ECDC4),
                    items: [
                      "完成Q4季度报告",
                      "参与新员工培训",
                      "客户服务流程优化",
                      "年度总结材料准备",
                      "市场推广活动支持",
                    ],
                    isReadOnly: true,
                    animation: _cardAnimations[1],
                  ),
                  _buildQuadrantCard(
                    title: "个人10大重要事项",
                    emoji: "⭐",
                    color: Color(0xFF88D8B0),
                    items: [
                      "完成项目里程碑",
                      "学习新技术栈",
                      "制定职业规划",
                      "改善工作流程",
                      "加强团队沟通",
                    ],
                    isReadOnly: false,
                    animation: _cardAnimations[2],
                  ),
                  _buildQuadrantCard(
                    title: "个人日志",
                    emoji: "📝",
                    color: Color(0xFFFFCC80),
                    items: [
                      "项目进展顺利 😊",
                      "学习新知识 🔥",
                      "团队协作 😐",
                      "客户沟通 😊",
                    ],
                    isReadOnly: false,
                    animation: _cardAnimations[3],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildQuadrantCard({
    required String title,
    required String emoji,
    required Color color,
    required List<String> items,
    required bool isReadOnly,
    required Animation<double> animation,
  }) {
    return ScaleTransition(
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
                        fontSize: 14, // 字体稍大，适配拉长卡片
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
                child: ListView.builder(
                  itemCount: items.length > 4 ? 4 : items.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8), // 增加间距
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
                                fontSize: 12, // 字体稍大，适配拉长卡片
                                color: Colors.grey[700],
                                height: 1.4, // 增加行高
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
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}