import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/task_list_response.dart';
import '../services/task_service.dart';
import 'task_detail_view.dart';

class CalendarGraphTab extends StatefulWidget {
  @override
  _CalendarGraphTabState createState() => _CalendarGraphTabState();
}

class _CalendarGraphTabState extends State<CalendarGraphTab> {
  // --- 视图状态 ---
  String _viewMode = 'month'; // 'month', 'week', 'day'
  DateTime _currentDate = DateTime.now(); // 当前聚焦的月份/日期
  DateTime _selectedDay = DateTime.now(); // 用户点击选中的日期

  // --- 数据状态 ---
  List<Task> _tasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 初始化选中的日期为今天（去除时间部分）
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);

    // 加载数据
    _loadAllTasksForCalendar();
  }

  // --- 数据加载逻辑 ---
  // 注意：理想情况下，后端应提供按 StartDate 和 EndDate 查询的接口
  // 目前暂时复用列表接口，一次性加载较大数量，确保日历有数据点
  Future<void> _loadAllTasksForCalendar() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 暂时加载前 100 条“我的任务”用于填充日历
      // TODO: 替换为 TaskService.fetchCalendarTasks(start, end)
      TaskListResponse response = await TaskService.fetchPersonalTasks(
        page: 1,
        pageSize: 100,
      );

      if (mounted) {
        setState(() {
          _tasks = response.tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('日历数据加载失败: $e');
      }
    }
  }

  // --- 核心 UI 构建 ---
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
      child: Column(
        children: [
          // 1. 视图切换器 (日/周/月)
          _buildViewSwitcher(),

          SizedBox(height: 12),

          // 2. 动态内容区域
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildCurrentView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitcher() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildViewModeButton('day', '日视图', Icons.today, Color(0xFFFF6B9D)),
          _buildViewModeButton('week', '周视图', Icons.calendar_view_week, Color(0xFFFF9F51)),
          _buildViewModeButton('month', '月视图', Icons.calendar_view_month, Color(0xFF4ECDC4)),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(String mode, String label, IconData icon, Color color) {
    bool isSelected = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _viewMode = mode;
            // 切换回日视图时，确保聚焦到选中的那天
            if (mode == 'day') {
              _currentDate = _selectedDay;
            }
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.all(2),
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? LinearGradient(colors: [color, color.withOpacity(0.7)]) : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_viewMode) {
      case 'day':
        return KeyedSubtree(key: ValueKey('day_view'), child: _buildDayView());
      case 'week':
        return KeyedSubtree(key: ValueKey('week_view'), child: _buildWeekView());
      case 'month':
      default:
        return KeyedSubtree(key: ValueKey('month_view'), child: _buildMonthView());
    }
  }

  // --- 月视图逻辑 ---
  Widget _buildMonthView() {
    // 确保选中的月份与当前翻页的月份同步逻辑(可选)
    // 这里保持原逻辑：_currentDate 仅控制翻页显示

    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final int firstWeekdayOffset = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    final daysInMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;
    final totalCells = firstWeekdayOffset + daysInMonth;
    final requiredWeeks = (totalCells / 7).ceil();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 月份翻页头
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: _buildMonthHeader(),
          ),
          SizedBox(height: 20),

          // 日历网格
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                _buildWeekdaysHeader(),
                SizedBox(height: 8),
                ...List.generate(requiredWeeks, (weekIndex) {
                  return Row(
                    children: List.generate(7, (dayIndex) {
                      final cellIndex = weekIndex * 7 + dayIndex;
                      return Expanded(child: _buildCalendarCellFixed(cellIndex));
                    }),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 16),

          // 选中日期的任务列表
          _buildSelectedDayTasksList(),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: Color(0xFFFF8C42)),
          onPressed: () => setState(() => _currentDate = DateTime(_currentDate.year, _currentDate.month - 1)),
        ),
        Column(
          children: [
            Text('${_currentDate.year}年', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
            Text(_getMonthName(_currentDate.month), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          ],
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: Color(0xFFFF8C42)),
          onPressed: () => setState(() => _currentDate = DateTime(_currentDate.year, _currentDate.month + 1)),
        ),
      ],
    );
  }

  Widget _buildWeekdaysHeader() {
    return Row(
      children: ['日', '一', '二', '三', '四', '五', '六']
          .map((day) => Expanded(
        child: Center(
          child: Text(day, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF666666))),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarCellFixed(int index) {
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final firstWeekday = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    final dayNumber = index - firstWeekday + 1;
    final daysInMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;

    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return Container(height: 50);
    }

    final date = DateTime(_currentDate.year, _currentDate.month, dayNumber);

    // 过滤当天的任务
    final dailyTasks = _filterTasksForDate(date);
    final eventCount = dailyTasks.length;

    final isToday = _isSameDate(date, DateTime.now());
    final isSelected = _isSameDate(date, _selectedDay);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = date;
        });
      },
      child: Container(
        height: 48,
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: isToday ? LinearGradient(colors: [Color(0xFFFF8C42), Color(0xFFFF6B9D)]) : null,
          color: isToday ? null : (eventCount > 0 ? Color(0xFFFFE66D).withOpacity(0.3) : null),
          borderRadius: BorderRadius.circular(12),
          border: isSelected && !isToday ? Border.all(color: Color(0xFFFF8C42), width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                color: isToday ? Colors.white : Color(0xFF333333),
              ),
            ),
            if (eventCount > 0)
              Text(
                '$eventCount个',
                style: TextStyle(
                  fontSize: 10,
                  color: isToday ? Colors.white : Color(0xFFFF8C42),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- 周视图逻辑 ---
  Widget _buildWeekView() {
    final startOfWeek = _currentDate.subtract(Duration(days: _currentDate.weekday == 7 ? 0 : _currentDate.weekday));
    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 周头
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_getMonthName(startOfWeek.month)}${startOfWeek.day}日', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('至', style: TextStyle(color: Color(0xFF666666))),
                Text('${_getMonthName(weekDays.last.month)}${weekDays.last.day}日', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(height: 16),
          // 每天列表
          ...weekDays.map((day) => _buildWeekDayItem(day)).toList(),
        ],
      ),
    );
  }

  Widget _buildWeekDayItem(DateTime day) {
    final dayTasks = _filterTasksForDate(day);
    final isToday = _isSameDate(day, DateTime.now());
    final isSelected = _isSameDate(day, _selectedDay);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = day;
          _viewMode = 'day'; // 点击切换到日视图
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Color(0xFFFF8C42), width: 2) : null,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${day.month}月${day.day}日 ${_getWeekdayName(day.weekday)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isToday ? Color(0xFFFF6B9D) : Color(0xFF333333))),
                SizedBox(width: 8),
                if (isToday) Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Color(0xFFFF6B9D), borderRadius: BorderRadius.circular(10)), child: Text('今天', style: TextStyle(color: Colors.white, fontSize: 12))),
                Spacer(),
                Text('${dayTasks.length}个任务', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
              ],
            ),
            SizedBox(height: 12),
            if (dayTasks.isEmpty)
              Text('暂无任务', style: TextStyle(color: Color(0xFF999999)))
            else
              ...dayTasks.take(3).map((task) => _buildSimpleTaskRow(task)),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTaskRow(Task task) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(color: Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: _getStatusColor(task.status), shape: BoxShape.circle)),
          SizedBox(width: 8),
          Expanded(child: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  // --- 日视图逻辑 ---
  Widget _buildDayView() {
    // 这里的 _currentDate 在日视图下应该跟随 _selectedDay
    final targetDate = _selectedDay;
    final dayTasks = _filterTasksForDate(targetDate);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 巨大的日期卡片
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFFF8C42), Color(0xFFFF6B9D)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Color(0xFFFF8C42).withOpacity(0.3), blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: Column(
              children: [
                Text('${targetDate.day}', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w300, color: Colors.white, height: 1.0)),
                Text('${_getMonthName(targetDate.month)} ${targetDate.year}', style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.9))),
                SizedBox(height: 8),
                Text(_getWeekdayName(targetDate.weekday), style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                SizedBox(height: 8),
                Text('今日任务: ${dayTasks.length}个', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          SizedBox(height: 24),
          if (dayTasks.isEmpty)
            _buildEmptyState('今天没有任务', '享受轻松的一天吧！')
          else
            ...dayTasks.map((task) => _buildTaskCard(task)),
        ],
      ),
    );
  }

  // --- 底部选中的任务列表 (月视图下显示) ---
  Widget _buildSelectedDayTasksList() {
    final selectedDayTasks = _filterTasksForDate(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            '${_selectedDay.month}月${_selectedDay.day}日 任务 (${selectedDayTasks.length}个)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          ),
        ),
        selectedDayTasks.isEmpty
            ? Center(child: Padding(padding: const EdgeInsets.only(top: 20.0), child: Text('当天没有任务', style: TextStyle(color: Color(0xFF999999)))))
            : ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: selectedDayTasks.length,
          itemBuilder: (context, index) {
            return _buildTaskCard(selectedDayTasks[index]); // 复用卡片样式
          },
        ),
      ],
    );
  }

  // --- 通用任务卡片 ---
  Widget _buildTaskCard(Task task) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailView(taskId: task.taskId)));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12, left: 16, right: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            Icon(_getTaskIcon(task.status), color: _getStatusColor(task.status)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (task.dueAt != null)
                    Text('${task.dueAt!.hour}:${task.dueAt!.minute}', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            _buildStatusChip(task.status),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String sub) {
    return Center(child: Column(children: [Text(title, style: TextStyle(fontSize: 18)), Text(sub, style: TextStyle(color: Colors.grey))]));
  }

  // --- 核心辅助逻辑 ---

  // 筛选某天的任务 (复用原本的复杂逻辑)
  List<Task> _filterTasksForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);

    return _tasks.where((task) {
      if (task.status == TaskStatus.completed) return false;

      if (task.startAt != null && task.dueAt != null) {
        final start = DateTime(task.startAt!.year, task.startAt!.month, task.startAt!.day);
        final end = DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);
        return (dateOnly.isAfter(start.subtract(Duration(days: 1))) && dateOnly.isBefore(end.add(Duration(days: 1))));
      }

      if (task.dueAt != null) {
        final end = DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);
        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        return dateOnly.isAfter(today.subtract(Duration(days: 1))) && dateOnly.isBefore(end.add(Duration(days: 1)));
      }

      if (task.startAt != null) {
        final start = DateTime(task.startAt!.year, task.startAt!.month, task.startAt!.day);
        return dateOnly.isAfter(start.subtract(Duration(days: 1)));
      }

      return false;
    }).toList();
  }

  bool _isSameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

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
    // 简化版 Chip
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toString().split('.').last, style: TextStyle(color: _getStatusColor(status), fontSize: 10)),
    );
  }

  String _getMonthName(int month) => ['','一月','二月','三月','四月','五月','六月','七月','八月','九月','十月','十一月','十二月'][month];

  String _getWeekdayName(int weekday) => ['','星期一','星期二','星期三','星期四','星期五','星期六','星期日'][weekday];
}