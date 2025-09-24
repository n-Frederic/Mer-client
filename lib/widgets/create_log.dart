import 'package:flutter/material.dart';

class CreateLogScreen extends StatefulWidget {
  const CreateLogScreen({Key? key}) : super(key: key);
  @override
  State<CreateLogScreen> createState() => _CreateLogScreenState();
}

class _CreateLogScreenState extends State<CreateLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _todaySummaryController = TextEditingController();
  final _tomorrowPlanController = TextEditingController();
  final _helpNeededController = TextEditingController();

  List<String> _selectedTasks = [];
  final List<String> _availableTasks = [
    '完成用户界面设计',
    '数据库优化',
    'API接口开发',
    '测试用例编写',
    '项目文档整理',
    '代码审查',
    '性能优化',
    '安全检查'
  ];

  @override
  void dispose() {
    _todaySummaryController.dispose();
    _tomorrowPlanController.dispose();
    _helpNeededController.dispose();
    super.dispose();
  }

  void _submitLog() {
    if (_formKey.currentState!.validate()) {
      // 处理日志提交逻辑
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('日志创建成功！'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildSectionCard({
    required String title,
    required String hint,
    required TextEditingController controller,
    int maxLines = 4,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请填写$title';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskSelectionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '相关任务',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const Spacer(),
                Text(
                  '已选择 ${_selectedTasks.length} 个',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('选择相关任务'),
                  ),
                  isExpanded: true,
                  items: _availableTasks.map((task) {
                    return DropdownMenuItem<String>(
                      value: task,
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          final isSelected = _selectedTasks.contains(task);
                          return CheckboxListTile(
                            title: Text(task),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  if (!_selectedTasks.contains(task)) {
                                    _selectedTasks.add(task);
                                  }
                                } else {
                                  _selectedTasks.remove(task);
                                }
                              });
                              this.setState(() {});
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: const Color(0xFFFF6B35),
                          );
                        },
                      ),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    // 处理在 DropdownMenuItem 中
                  },
                ),
              ),
            ),
            if (_selectedTasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedTasks.map((task) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTasks.remove(task);
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final todayText = _todaySummaryController.text.trim();
    final tomorrowText = _tomorrowPlanController.text.trim();
    final helpText = _helpNeededController.text.trim();

    final completedSections = [
      if (todayText.isNotEmpty) '今日总结',
      if (tomorrowText.isNotEmpty) '明日计划',
      if (helpText.isNotEmpty) '协调帮助',
      if (_selectedTasks.isNotEmpty) '相关任务',
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '日志预览',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: completedSections.length == 4 ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${completedSections.length}/4 完成',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: completedSections.length == 4 ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (completedSections.isNotEmpty) ...[
              ...completedSections.map((section) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    Text(
                      section,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              )),
            ] else ...[
              Text(
                '开始填写日志内容...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '创建日志',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSectionCard(
                title: '今日总结',
                hint: '总结今天完成的主要工作和成果...',
                controller: _todaySummaryController,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: '明日计划',
                hint: '规划明天要完成的主要任务和目标...',
                controller: _tomorrowPlanController,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: '需要的协调与帮助',
                hint: '描述需要同事协助或上级支持的事项...',
                controller: _helpNeededController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTaskSelectionCard(),
              const SizedBox(height: 16),
              _buildPreviewCard(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    '创建日志',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
