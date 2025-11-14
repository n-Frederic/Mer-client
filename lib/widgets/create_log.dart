import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/log_service.dart';

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
  bool _isSubmitting = false;

  List<String> _selectedTaskIds = [];
  late Future<List<Task>> _tasksFuture;
  List<Task> _cachedAvailableTasks = [];

  // 定义统一的渐变色
  final LinearGradient _appBarGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFE66D), // 较浅的橙色
      Color(0xFFFF8C42), // 较深的橙色
    ],
  );

  // 定义统一的强调色（来自渐变中的深色）
  final Color _accentColor = const Color(0xFFFF8C42);

  @override
  void initState() {
    super.initState();
    // 【新增】在 initState 中调用 API
    _tasksFuture = _fetchAndCacheTasks();
  }

  Future<List<Task>> _fetchAndCacheTasks() async {
    try {
      // 1. 【修正】调用 fetchScopedTasks (即 /api/tasks/myView)
      final response = await TaskService.fetchScopedTasks(
        pageSize: 100, // 获取足够多的任务
      );

      // 2. 缓存结果
      if (mounted) {
        setState(() {
          _cachedAvailableTasks = response.tasks;
        });
      }
      return response.tasks;

    } catch (e) {
      print('加载相关任务失败: $e');
      // 如果失败，返回一个空列表
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

  void _submitLog() async {
    // 1. 检查表单验证
    if (!_formKey.currentState!.validate()) {
      return; // 验证失败，停止
    }

    // 2. 检查是否正在提交
    if (_isSubmitting) {
      return; // 防止重复点击
    }

    // 3. 进入加载状态
    setState(() {
      _isSubmitting = true;
    });

    try {
      // 4. 调用 API
      final newLogId = await LogService.createLog(
        todaySummary: _todaySummaryController.text.trim(),
        tomorrowPlan: _tomorrowPlanController.text.trim(),
        helpNeeded: _helpNeededController.text.trim(),
        taskId: _selectedTaskIds, // 使用真实的 ID 列表
      );

      // 5. 处理成功
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('日志 (ID: $newLogId) 创建成功！'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // 成功后关闭页面

    } catch (e) {
      // 6. 处理失败
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('日志创建失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // 7. 结束加载状态
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
                    // 使用统一的渐变色
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
                  borderSide: BorderSide(color: _accentColor, width: 2), // 使用统一强调色
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
                // ... (标题 "相关任务" 部分保持不变)
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
                  // 【修改】使用 _selectedTaskIds
                  '已选择 ${_selectedTaskIds.length} 个',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 【修改】使用 FutureBuilder 来包装下拉框
            FutureBuilder<List<Task>>(
              future: _tasksFuture, // <-- 监听
              builder: (context, snapshot) {
                // 1. 加载中
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
                        SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)
                        ),
                        SizedBox(width: 12),
                        Text('正在加载任务列表...', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                // 2. 加载失败
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

                // 3. 成功 (使用 _cachedAvailableTasks)
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
                      // 【修改】遍历 _cachedAvailableTasks
                      items: _cachedAvailableTasks.map((task) {
                        return DropdownMenuItem<String>(
                          // ⚠️ value 设为 task.taskId，因为 Dropdown 的 value 不能重复
                          value: task.taskId,
                          child: StatefulBuilder(
                            builder: (context, setState) {
                              // 【修改】检查 _selectedTaskIds
                              final isSelected = _selectedTaskIds.contains(task.taskId);
                              return CheckboxListTile(
                                // 【修改】显示 task.title
                                title: Text(task.title, style: TextStyle(fontSize: 14)),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      // 【修改】存储 task.taskId
                                      if (!_selectedTaskIds.contains(task.taskId)) {
                                        _selectedTaskIds.add(task.taskId);
                                      }
                                    } else {
                                      _selectedTaskIds.remove(task.taskId);
                                    }
                                  });
                                  // 触发外部 State 的刷新
                                  this.setState(() {});
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

            // 【修改】显示已选任务的 Chips
            if (_selectedTaskIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                // 遍历 ID 列表
                children: _selectedTaskIds.map((taskId) {
                  // 从缓存中找到 Task 对象以获取标题
                  final task = _cachedAvailableTasks.firstWhere(
                        (t) => t.taskId == taskId,
                    orElse: () => Task.fromJson({ // 创建一个临时的 Task 以防万一
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
                          task.title, // 显示任务标题
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
                              _selectedTaskIds.remove(taskId); // 按 ID 移除
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
          '创建日志',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        // 移除 backgroundColor
        elevation: 0,
        flexibleSpace: Container( // 添加 flexibleSpace 来实现渐变
          decoration: BoxDecoration(
            gradient: _appBarGradient,
          ),
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
              const SizedBox(height: 24), // 调整间距，因为移除了预览卡片
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitLog,
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