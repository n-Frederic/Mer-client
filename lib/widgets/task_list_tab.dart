import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/task_list_response.dart';
import '../services/task_service.dart';
import 'task_detail_view.dart'; // 请确认这个路径是否正确

class TaskListTab extends StatefulWidget {
  @override
  _TaskListTabState createState() => _TaskListTabState();
}

class _TaskListTabState extends State<TaskListTab> {
  // --- 状态数据 ---
  List<Task> _allTasks = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  String _currentFilter = 'my'; // 'my' 或 'all'
  String _taskSearchTerm = '';

  @override
  void initState() {
    super.initState();
    // 初始化直接加载第一页
    _loadTasks(reset: true);
  }

  // --- 核心逻辑：加载数据 ---
  Future<void> _loadTasks({bool reset = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        _currentPage = 1;
        _allTasks.clear();
        _hasMore = true;
      }
    });

    try {
      TaskListResponse response;
      // 根据筛选器调用不同的 API
      if (_currentFilter == 'my') {
        response = await TaskService.fetchPersonalTasks(
          page: _currentPage,
          pageSize: 20,
        );
      } else {
        response = await TaskService.fetchScopedTasks(
          page: _currentPage,
          pageSize: 20,
        );
      }

      if (mounted) {
        setState(() {
          if (reset) {
            _allTasks = response.tasks;
          } else {
            _allTasks.addAll(response.tasks);
          }
          _hasMore = response.hasMore;
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载任务失败: $e')),
        );
      }
    }
  }

  Future<void> _refreshTasks() async {
    await _loadTasks(reset: true);
  }

  void _loadMore() {
    if (_hasMore && !_isLoading) {
      _loadTasks(reset: false);
    }
  }

  // --- UI 构建 ---
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部操作栏：筛选 + 搜索
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              _buildFilterButton('my', '我的任务'),
              SizedBox(width: 8),
              _buildFilterButton('all', '全部任务'),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '搜索任务...',
                    prefixIcon: Icon(Icons.search, color: Color(0xFF999999)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _taskSearchTerm = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        // 列表区域
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshTasks,
            child: _buildTaskList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList() {
    // 前端二次搜索过滤
    List<Task> filteredTasks = _allTasks.where((task) {
      if (_taskSearchTerm.isEmpty) return true;
      final searchTerm = _taskSearchTerm.toLowerCase();
      return task.title.toLowerCase().contains(searchTerm) ||
          (task.description?.toLowerCase().contains(searchTerm) ?? false);
    }).toList();

    // 排序：按截止时间
    filteredTasks.sort((a, b) =>
    a.dueAt?.compareTo(b.dueAt ?? DateTime(9999)) ?? -1);

    // 空状态处理
    if (filteredTasks.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('暂无任务', style: TextStyle(color: Color(0xFF666666))),
            if (_taskSearchTerm.isNotEmpty)
              TextButton(
                  onPressed: () {
                    setState(() {
                      _taskSearchTerm = '';
                    });
                    _refreshTasks();
                  },
                  child: Text('清空搜索')),
            SizedBox(height: 10),
            TextButton(
              onPressed: _refreshTasks,
              child: Text('重新加载'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: filteredTasks.length + 1, // +1 给加载更多指示器
      itemBuilder: (context, index) {
        if (index == filteredTasks.length) {
          return _buildLoadMoreIndicator();
        }
        return _buildTaskItem(filteredTasks[index]);
      },
    );
  }

  Widget _buildFilterButton(String mode, String label) {
    final isSelected = _currentFilter == mode;
    return GestureDetector(
      onTap: () {
        if (_currentFilter != mode) {
          setState(() {
            _currentFilter = mode;
          });
          _loadTasks(reset: true);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFFF8C42) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Color(0xFFFF8C42).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Color(0xFFFF8C42),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : _hasMore
            ? TextButton(
          onPressed: _loadMore,
          child: Text('加载更多'),
        )
            : Text(
          '没有更多任务了',
          style: TextStyle(color: Color(0xFF999999)),
        ),
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailView(taskId: task.taskId),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            // 状态图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusColor(task.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(_getTaskIcon(task.status),
                    color: _getStatusColor(task.status), size: 20),
              ),
            ),
            SizedBox(width: 12),
            // 标题和时间
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title,
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    task.dueAt != null
                        ? '截止: ${task.dueAt!.month}月${task.dueAt!.day}日'
                        : '截止: 未设置',
                    style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            _buildStatusChip(task.status),
          ],
        ),
      ),
    );
  }

  // --- 辅助方法 (样式) ---
  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.published: return Color(0xFF999999);
      case TaskStatus.reported: return Colors.purple;
      case TaskStatus.completed: return Colors.green;
      case TaskStatus.closed: return Colors.black45;
    }
  }

  IconData _getTaskIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.published: return Icons.publish;
      case TaskStatus.reported: return Icons.report;
      case TaskStatus.completed: return Icons.check_circle;
      case TaskStatus.closed: return Icons.lock;
    }
  }

  Widget _buildStatusChip(TaskStatus status) {
    Color color = _getStatusColor(status);
    String text;
    switch (status) {
      case TaskStatus.published: text = '已发布'; break;
      case TaskStatus.reported: text = '已提交'; break;
      case TaskStatus.completed: text = '已完成'; break;
      case TaskStatus.closed: text = '已关闭'; break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}