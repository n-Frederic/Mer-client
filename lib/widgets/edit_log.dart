import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/log_service.dart';
import '../models/log.dart';
import 'edit_log.dart';

class EditLogScreen extends StatefulWidget {
  // 【新增】接收要编辑的日志
  final Log logToEdit;

  const EditLogScreen({Key? key, required this.logToEdit}) : super(key: key);

  @override
  State<EditLogScreen> createState() => _EditLogScreenState();
}

class _EditLogScreenState extends State<EditLogScreen> {
  final _formKey = GlobalKey<FormState>();

  // 【修改】使用 TextEditingController 来预填充
  late TextEditingController _todaySummaryController;
  late TextEditingController _tomorrowPlanController;
  late TextEditingController _helpNeededController;

  bool _isSubmitting = false;

  // 【修改】预填充已选中的任务
  late List<String> _selectedTaskIds;

  late Future<List<Task>> _tasksFuture;
  List<Task> _cachedAvailableTasks = [];

  // (复用 create_log_screen 的样式)
  final LinearGradient _appBarGradient = const LinearGradient(
    colors: [Color(0xFFFFE66D), Color(0xFFFF8C42)],
  );
  final Color _accentColor = const Color(0xFFFF8C42);

  @override
  void initState() {
    super.initState();

    // --- 【⬇️ 关键修改 ⬇️】 ---
    // 1. 预填充文本字段
    _todaySummaryController = TextEditingController(text: widget.logToEdit.todaySummary);
    _tomorrowPlanController = TextEditingController(text: widget.logToEdit.tomorrowPlan);
    _helpNeededController = TextEditingController(text: widget.logToEdit.helpNeeded);

    // 2. 预填充已选任务
    // (我们假设 logToEdit.taskIds 包含 ['1', '3'] 这样的 ID 列表)
    _selectedTaskIds = List<String>.from(widget.logToEdit.taskIds);
    // --- 【⬆️ 修改结束 ⬆️】 ---

    // 3. (保持不变) 加载所有可用任务
    _tasksFuture = _fetchAndCacheTasks();

  }

  Future<List<Task>> _fetchAndCacheTasks() async {
    try {
      // (假设 TaskService 和 Task/TaskResponse 模型存在)
      final response = await TaskService.fetchScopedTasks(pageSize: 100);
      if (mounted) {
        setState(() {
          _cachedAvailableTasks = response.tasks;
        });
      }
      return response.tasks;
    } catch (e) {
      print('加载相关任务失败: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _todaySummaryController.dispose();
    _tomorrowPlanController.dispose();
    _helpNeededController.dispose();
    super.dispose();
  }

  // 【修改】调用 updateLog 而不是 createLog
  void _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // --- 【⬇️ 关键修改 ⬇️】 ---
      // 4. 调用 updateLog API
      final bool success = await LogService.updateLog(
        widget.logToEdit.logId, // (传入 Log ID)
        todaySummary: _todaySummaryController.text.trim(),
        tomorrowPlan: _tomorrowPlanController.text.trim(),
        helpNeeded: _helpNeededController.text.trim(),
        taskId: _selectedTaskIds, // (使用 'taskId' 键名)
      );
      // --- 【⬆️ 修改结束 ⬆️】 ---

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('日志 (ID: ${widget.logToEdit.logId}) 更新成功！'),
            backgroundColor: Colors.green,
          ),
        );
        // 【修改】返回 true 告知详情页需要刷新
        Navigator.pop(context, true);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('日志更新失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ( _buildSectionCard 保持不变, 复用 create_log_screen 的 UI )
  // (TODO: 确保你有一个 create_log_screen.dart 或类似的 Widget 可复用)
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
                    gradient: _appBarGradient,
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
                  borderSide: BorderSide(color: _accentColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (title == '今日总结' && (value == null || value.trim().isEmpty)) {
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

  // ( _buildTaskSelectionCard 保持不变, 复用 create_log_screen 的 UI )
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
                    gradient: _appBarGradient,
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
                  '已选择 ${_selectedTaskIds.length} 个',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            FutureBuilder<List<Task>>(
              future: _tasksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('正在加载任务列表...', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.red[50],
                    ),
                    child: Text('加载任务失败: ${snapshot.error}', style: TextStyle(color: Colors.red[700])),
                  );
                }

                // (这里假设 _cachedAvailableTasks 已经被 _fetchAndCacheTasks 填充)
                return Container(
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
                      items: _cachedAvailableTasks.map((task) {
                        return DropdownMenuItem<String>(
                          value: task.taskId,
                          child: StatefulBuilder(
                            builder: (context, setState) {
                              final isSelected = _selectedTaskIds.contains(task.taskId);
                              return CheckboxListTile(
                                title: Text(task.title, style: TextStyle(fontSize: 14)),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  // (使用 this.setState 来刷新外部 UI)
                                  this.setState(() {
                                    if (value == true) {
                                      if (!_selectedTaskIds.contains(task.taskId)) {
                                        _selectedTaskIds.add(task.taskId);
                                      }
                                    } else {
                                      _selectedTaskIds.remove(task.taskId);
                                    }
                                  });
                                },
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: _accentColor,
                              );
                            },
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        // 逻辑已在 CheckboxListTile 中处理
                      },
                    ),
                  ),
                );
              },
            ),

            if (_selectedTaskIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedTaskIds.map((taskId) {
                  final task = _cachedAvailableTasks.firstWhere(
                        (t) => t.taskId == taskId,
                    orElse: () => Task.fromJson({ // 创建一个临时的 Task
                      'taskId': taskId,
                      'title': 'ID: $taskId',
                      'creator': {'userId': '0', 'name': '?', 'email': '?'},
                    }),
                  );

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: _appBarGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.title,
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
                              _selectedTaskIds.remove(taskId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '编辑日志', // 【修改】标题
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: _appBarGradient),
        ),
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
                controller: _todaySummaryController, // (已预填充)
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: '明日计划',
                hint: '规划明天要完成的主要任务和目标...',
                controller: _tomorrowPlanController, // (已预填充)
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: '需要的协调与帮助',
                hint: '描述需要同事协助或上级支持的事项...',
                controller: _helpNeededController, // (已预填充)
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTaskSelectionCard(), // (已预填充)
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitUpdate, // 【修改】
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                      : const Text(
                    '确认更新', // 【修改】
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