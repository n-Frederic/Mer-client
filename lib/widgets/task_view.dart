import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'task_detail_view.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../models/user.dart';
import '../models/role.dart';

class CalendarView extends StatefulWidget {
  @override
  _CalendarViewState createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView>
    with SingleTickerProviderStateMixin {
  String _viewMode = 'month';
  DateTime _currentDate = DateTime.now();
  late TabController _tabController;
  late Future<Role> _roleFuture;
  late Role _currentUserRole;
  String _currentUserId = '1';
  Map<String, dynamic>? _currentTask;
  String _taskFilterMode = 'my';
  String _taskSearchTerm = '';
  late Future<List<Task>> _tasksFuture;
  List<Task> _cachedTasks = [];
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDay =
        DateTime(_currentDate.year, _currentDate.month, _currentDate.day);

    // 初始化任务加载
    _tasksFuture = _fetchTasksByMode(_taskFilterMode, _currentUserId);

    // 初始化角色加载
    // ⚠️ 假设当前用户的 Role ID 是 3。实际应用中应从登录响应中获取。
    _roleFuture = _fetchRoleById(3);

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Task_view.dart 内，新增 _fetchRoleById 函数 (模拟 API 调用)

  // ⚠️ 占位函数：实际应用中需要调用 User/Role Service
  Future<Role> _fetchRoleById(int roleId) async {
    // TODO: 实现 RoleService.fetchRole(roleId)
    await Future.delayed(Duration(milliseconds: 500)); // 模拟网络延迟

    // 假设返回一个 Role 对象
    final fetchedRole = Role(
      roleId: roleId,
      name: 'Team Leader', // 假设从 API 获取的名称
      description: '负责团队管理和审批',
    );

    // 加载完成后，更新状态变量
    if (mounted) {
      _currentUserRole = fetchedRole;
    }
    return fetchedRole;
  }

  Future<List<Task>> _fetchTasksByMode(String mode, String userId) async {
    try {
      // 逻辑简化：总是调用获取个人任务的 API，因为列表只展示个人任务。
      // 如果 mode 是 'all'，则表示展示我相关的全部任务（包括我创建的、分配给我的等）。
      final response = await TaskService.fetchPersonalTasks(
        userId: userId,
        // 可以在这里根据 mode 传递不同的状态参数，例如：
        status: mode == 'my' ? 'InProgress' : null,
      );

      // 缓存数据
      if (mounted) {
        setState(() {
          _cachedTasks = response.tasks;
        });
      }
      return response.tasks;
    } catch (e) {
      // 打印错误信息
      print('Error fetching tasks: $e');
      rethrow;
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8E1),
              Color(0xFFFFE66D).withAlpha(120),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCalendarView(),
                    _buildTaskListView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Color(0xFFFF8C42),
              unselectedLabelColor: Color(0xFF999999),
              indicatorColor: Color(0xFFFF8C42),
              tabs: [
                Tab(text: '日历视图'),
                Tab(text: '任务列表'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
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
          Container(
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
                _buildViewModeButton(
                    'day', '日视图', Icons.today, Color(0xFFFF6B9D)),
                _buildViewModeButton(
                    'week', '周视图', Icons.calendar_view_week,
                    Color(0xFFFF9F51)),
                _buildViewModeButton(
                    'month', '月视图', Icons.calendar_view_month,
                    Color(0xFF4ECDC4)),
              ],
            ),
          ),
          SizedBox(height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: _buildCurrentView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(String mode, String label, IconData icon,
      Color color) {
    bool isSelected = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _viewMode = mode;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.all(2),
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [color, color.withOpacity(0.7)])
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ]
                : null,
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
        return KeyedSubtree(
          key: ValueKey('day_view'),
          child: _buildDayView(),
        );
      case 'week':
        return KeyedSubtree(
          key: ValueKey('week_view'),
          child: _buildWeekView(),
        );
      case 'month':
        return KeyedSubtree(
          key: ValueKey('month_view_fixed'),
          child: _buildMonthView(),
        );
      default:
        return _buildMonthView();
    }
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _currentDate =
                  DateTime(_currentDate.year, _currentDate.month - 1);
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFFF8C42).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.chevron_left, color: Color(0xFFFF8C42)),
          ),
        ),
        Column(
          children: [
            Text(
              '${_currentDate.year}年',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
            Text(
              '${_getMonthName(_currentDate.month)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _currentDate =
                  DateTime(_currentDate.year, _currentDate.month + 1);
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFFF8C42).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.chevron_right, color: Color(0xFFFF8C42)),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdaysHeader() {
    return Row(
      children: ['日', '一', '二', '三', '四', '五', '六']
          .map((day) =>
          Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF666666),
                ),
              ),
            ),
          ))
          .toList(),
    );
  }

  Widget _buildMonthView() {
    if (_selectedDay.year != _currentDate.year ||
        _selectedDay.month != _currentDate.month) {
      _selectedDay = DateTime(_currentDate.year, _currentDate.month, 1);
    }

    // --- 动态计算所需行数（周数） ---
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    // firstWeekday: 1=Mon, ..., 7=Sun. (Dart standard)
    // firstWeekdayOffset: Calendar starts on Sun (index 0). Sun=0, Mon=1, ..., Sat=6.
    final int firstWeekdayOffset =
    firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;

    // 计算本月总天数
    final daysInMonth =
        DateTime(_currentDate.year, _currentDate.month + 1, 0).day;

    // 总共需要的单元格数量 (前面的空白 + 月份天数)
    final totalCells = firstWeekdayOffset + daysInMonth;

    // 计算所需的周数 (向上取整)
    final requiredWeeks = (totalCells / 7).ceil();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: _buildMonthHeader(),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildWeekdaysHeader(),
                SizedBox(height: 8),
                // 使用 requiredWeeks 替换硬编码的 6
                ...List.generate(requiredWeeks, (weekIndex) {
                  return Row(
                    children: List.generate(7, (dayIndex) {
                      final cellIndex = weekIndex * 7 + dayIndex;
                      return Expanded(
                          child: _buildCalendarCellFixed(cellIndex));
                    }),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 16),
          // 日历下方的任务卡片区域
          _buildSelectedDayTasks(),
        ],
      ),
    );
  }

  // Task_view.dart 内，替换整个 _buildCalendarCellFixed 方法

  Widget _buildCalendarCellFixed(int index) {
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final firstWeekday =
    firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    final dayNumber = index - firstWeekday + 1;
    final daysInMonth =
        DateTime(_currentDate.year, _currentDate.month + 1, 0).day;

    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return Container(height: 50);
    }

    final date = DateTime(_currentDate.year, _currentDate.month, dayNumber);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly =
    DateTime(DateTime
        .now()
        .year, DateTime
        .now()
        .month, DateTime
        .now()
        .day);

    // 逻辑修复：使用缓存的强类型任务列表 _cachedTasks
    final List<Task> dailyEvents = _cachedTasks.where((task) {
      // 任务截止日必须存在
      if (task.dueAt == null) return false;
      // 已完成的任务不显示在日历上
      if (task.status == TaskStatus.completed) return false;

      final eventDueDateOnly =
      DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);

      // 1. 检查任务截止日是否在今天或未来
      final isEventDueTodayOrFuture =
      eventDueDateOnly.isAfter(todayOnly.subtract(Duration(days: 1)));
      if (!isEventDueTodayOrFuture) return false;

      // 2. 检查当前日历单元格日期是否在 [今天, 任务截止日] 区间内
      final isCellDateTodayOrFuture =
      dateOnly.isAfter(todayOnly.subtract(Duration(days: 1)));
      final isCellDateOnOrBeforeDueDate =
      dateOnly.isBefore(eventDueDateOnly.add(Duration(days: 1)));

      return isCellDateTodayOrFuture && isCellDateOnOrBeforeDueDate;
    }).toList(); // <--- 这里使用了 _cachedTasks

    final eventCount = dailyEvents.length;
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
          gradient: isToday
              ? LinearGradient(colors: [Color(0xFFFF8C42), Color(0xFFFF6B9D)])
              : null,
          color: isToday
              ? null
              : (eventCount > 0 ? Color(0xFFFFE66D).withOpacity(0.3) : null),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isToday
              ? [
            BoxShadow(
              color: Color(0xFFFF8C42).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ]
              : null,
          border: isSelected && !isToday
              ? Border.all(color: Color(0xFFFF8C42), width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                isToday || isSelected ? FontWeight.bold : FontWeight.normal,
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

  // Task_view.dart 内，替换整个 _buildSelectedDayTasks 方法

  Widget _buildSelectedDayTasks() {
    // 逻辑修复：使用缓存的强类型任务列表 _cachedTasks
    final allTasks = _cachedTasks;

    // 过滤：只显示任务截止日是 _selectedDay 的任务 (使用强类型 Task 对象)
    final selectedDayTasks = allTasks
        .where((task) =>
    task.dueAt != null && _isSameDate(task.dueAt!, _selectedDay))
        .toList();

    return Column(
      // 移除 Container 保持简洁
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            '${_selectedDay.month}月${_selectedDay
                .day}日 任务 (${selectedDayTasks.length}个)',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333)),
          ),
        ),
        selectedDayTasks.isEmpty
            ? Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child:
              Text('当天没有任务', style: TextStyle(color: Color(0xFF999999))),
            ))
            : ListView.builder(
          shrinkWrap: true,
          // 关键：使用 shrinkWrap 以适应 SingleChildScrollView
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: selectedDayTasks.length,
          itemBuilder: (context, index) {
            final task = selectedDayTasks[index];
            return GestureDetector(
              onTap: () {
                // 直接传递强类型 Task 对象
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TaskDetailView(
                          task: task,
                          userRole: _currentUserRole, // 【修改】使用新的角色标识符
                          currentUserId: _currentUserId,
                          onTaskUpdated: (updatedTask) {
                            // 任务更新后，重新加载数据，刷新列表和日历
                            setState(() {
                              _tasksFuture = _fetchTasksByMode(
                                  _taskFilterMode, _currentUserId);
                            });
                          },
                        ),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4)
                  ],
                ),
                child: Row(
                  children: [
                    // ⚠️ 占位符
                    Text('📝', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 12),
                    Expanded(child: Text(task.title)),
                    _buildStatusChip(task.status),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // (以下为其他视图和辅助方法，保持不变)

  // Task_view.dart 内，替换整个 _buildDayView 方法

  Widget _buildDayView() {
    final today = DateTime.now();

    // 逻辑修复：使用缓存的强类型任务列表 _cachedTasks
    final todayTasks =
    _cachedTasks.where((task) =>
    task.dueAt != null && _isSameDate(task.dueAt!, today)).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF8C42), Color(0xFFFF6B9D)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFF8C42).withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${today.day}',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                Text(
                  '${_getMonthName(today.month)} ${today.year}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _getWeekdayName(today.weekday),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          if (todayTasks.isEmpty)
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Color(0xFFFFF8E1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('🌟', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '今天没有任务',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '享受轻松的一天吧！',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            )
          else
            ...todayTasks.map((task) =>
                GestureDetector(
                  onTap: () {
                    // 导航到任务详情页
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TaskDetailView(
                              task: task,
                              userRole: _currentUserRole, // 【修改】使用新的角色标识符
                              currentUserId: _currentUserId,
                              onTaskUpdated: (updatedTask) {
                                // 任务更新后，重新加载数据
                                setState(() {
                                  _tasksFuture = _fetchTasksByMode(
                                      _taskFilterMode, _currentUserId);
                                });
                              },
                            ),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  // ⚠️ 占位符
                                  color: Colors.blueAccent.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  // ⚠️ 占位符
                                  child: Text(
                                      '📝', style: TextStyle(fontSize: 28)),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            size: 16, color: Color(0xFF666666)),
                                        SizedBox(width: 4),
                                        Text(
                                          // 使用截止日期的时间部分
                                          task.dueAt != null ? '截止 ${task
                                              .dueAt!.hour}:${task.dueAt!
                                              .minute}' : '未设置时间',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF666666),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatusChip(task.status),
                            ],
                          ),
                          SizedBox(height: 12),
                          // ⚠️ 占位符
                          LinearProgressIndicator(
                            value: 0.0,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              task.status == TaskStatus.completed
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '进度: 0%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  // Task_view.dart 内，替换整个 _buildWeekView 方法

  Widget _buildWeekView() {
    final startOfWeek =
    _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
    final weekDays =
    List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: weekDays.map((day) {
          // 逻辑修复：使用缓存的强类型任务列表 _cachedTasks
          final dayTasks =
          _cachedTasks.where((task) =>
          task.dueAt != null && _isSameDate(task.dueAt!, day)).toList();
          final isToday = _isSameDate(day, DateTime.now());

          return Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${day.month}月${day.day}日 ${_getWeekdayName(day.weekday)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Color(0xFFFF6B9D) : Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 8),
                if (dayTasks.isEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Color(0xFFFFF8E1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                              child:
                              Text('🌟', style: TextStyle(fontSize: 12))),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '暂无任务',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              Text(
                                '当天无安排',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...dayTasks.map((task) =>
                      GestureDetector(
                        onTap: () {
                          // 导航到任务详情页
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TaskDetailView(
                                    task: task,
                                    userRole: _currentUserRole,
                                    currentUserId: _currentUserId,
                                    onTaskUpdated: (updatedTask) {
                                      // 任务更新后，重新加载数据
                                      setState(() {
                                        _tasksFuture = _fetchTasksByMode(
                                            _taskFilterMode, _currentUserId);
                                      });
                                    },
                                  ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              // ⚠️ 占位符
                              Text('📝', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    Text(
                                      // ⚠️ 占位符
                                      '${task.dueAt != null
                                          ? '截止 ${task.dueAt!.hour}:${task
                                          .dueAt!.minute}'
                                          : '未设置时间'} · 进度: 0%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatusChip(task.status),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    Color color;
    String text;

    switch (status) {
      case TaskStatus.published:
        color = Color(0xFF999999);
        text = '已发布';
        break;
      case TaskStatus.assigned:
        color = Color(0xFFFF8C42);
        text = '已分配';
        break;
      case TaskStatus.inProgress:
        color = Colors.blue;
        text = '进行中';
        break;
      case TaskStatus.reported:
        color = Colors.purple;
        text = '已汇报';
        break;
      case TaskStatus.completed:
        color = Colors.green;
        text = '已完成';
        break;
      case TaskStatus.closed:
        color = Colors.black45;
        text = '已关闭';
        break;
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
        style:
        TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '',
      '一月',
      '二月',
      '三月',
      '四月',
      '五月',
      '六月',
      '七月',
      '八月',
      '九月',
      '十月',
      '十一月',
      '十二月'
    ];
    return months[month];
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      '星期日',
      '星期一',
      '星期二',
      '星期三',
      '星期四',
      '星期五',
      '星期六'
    ];
    return weekdays[weekday % 7];
  }

  Widget _buildFilterButton(String mode, String label) {
    final isSelected = _taskFilterMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _taskFilterMode = mode;
        });
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

  Widget _buildTaskListView() {
    return Column(
      children: [
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
                      borderSide: BorderSide.none,
                    ),
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
        Expanded(
          // 使用 FutureBuilder 接入 API 数据，监听任务 Future
          child: FutureBuilder<List<Task>>(
            future: _tasksFuture,
            builder: (context, snapshot) {
              // --- 状态处理：加载中 ---
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              // --- 状态处理：错误 ---
              if (snapshot.hasError) {
                return Center(
                    child: Text('加载任务失败: ${snapshot.error}',
                        style: TextStyle(color: Colors.red)));
              }

              // --- 数据渲染 ---
              if (snapshot.hasData) {
                List<Task> allTasks = snapshot.data!;
                List<Task> tasksToRender = allTasks; // 默认为 API 返回的全部

                // 1. 根据筛选模式进行前端过滤
                if (_taskFilterMode == 'my') {
                  // 'my' 模式：只显示当前用户创建的任务 (CreatorId 筛选)
                  tasksToRender = allTasks.where((task) => task.creatorId == _currentUserId).toList();
                }

                // 2. 应用搜索过滤
                if (_taskSearchTerm.isNotEmpty) {
                  final searchTerm = _taskSearchTerm.toLowerCase();
                  tasksToRender = tasksToRender.where((task) {
                    return task.title.toLowerCase().contains(searchTerm) ||
                        task.description.toLowerCase().contains(searchTerm);
                  }).toList();
                }

                // 3. 排序 (例如按截止日期)
                tasksToRender.sort((a, b) =>
                a.dueAt?.compareTo(b.dueAt ?? DateTime(9999)) ?? -1);

                // 任务列表为空
                if (tasksToRender.isEmpty) {
                  return Center(
                      child: Text('暂无任务',
                          style: TextStyle(color: Color(0xFF666666))));
                }

                // 渲染列表
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: tasksToRender.length, // 使用筛选后的列表
                  itemBuilder: (context, index) {
                    final task = tasksToRender[index]; // 使用筛选后的列表
                    return GestureDetector(
                      onTap: () {
                        // 🚀 最终状态：直接传递强类型 Task 对象
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TaskDetailView(
                                  task: task,
                                  userRole: _currentUserRole,
                                  currentUserId: _currentUserId,
                                  onTaskUpdated: (updatedTask) {
                                    // 重新刷新列表
                                    setState(() {
                                      _tasksFuture = _fetchTasksByMode(
                                          _taskFilterMode, _currentUserId);
                                    });
                                  },
                                ),
                          ),
                        );
                      },
                      child: Container(
                        margin:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.5), // 占位符颜色
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                  child: Text('📝',
                                      style: TextStyle(fontSize: 20))), // 占位符 Emoji
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    // 格式化日期，如果 dueAt 为空则显示 '未设置截止日期'
                                    task.dueAt != null
                                        ? '截止: ${task.dueAt!.month}月${task.dueAt!.day}日'
                                        : '截止: 未设置',
                                    style: TextStyle(
                                        fontSize: 12, color: Color(0xFF666666)),
                                  ),
                                ],
                              ),
                            ),
                            // 任务状态芯片
                            _buildStatusChip(task.status),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              return Container(); // 默认返回空容器
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleCheckIn() async {
    // ⚠️ 注意：此函数在 Task_view.dart 中，因此它只能触发刷新，无法直接获取正在打卡的 Task 对象。
    // 真正的逻辑应该在 TaskDetailView 中。这里我们只修复错误并设置刷新机制。

    showDialog(
      context: context,
      builder: (context) {
        File? capturedImage;
        Position? currentPosition;
        String? locationAddress;
        final noteController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double maxHeight = MediaQuery
                .of(context)
                .size
                .height * 0.7;

            return AlertDialog(
              title: Text('任务打卡'),
              content: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.camera_alt,
                                    color: capturedImage != null
                                        ? Colors.green
                                        : Colors.grey),
                                SizedBox(width: 8),
                                Text('1. 拍照 *',
                                    style:
                                    TextStyle(fontWeight: FontWeight.w500)),
                                Spacer(),
                                if (capturedImage != null)
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                              ],
                            ),
                            SizedBox(height: 8),
                            if (capturedImage != null)
                              Image.file(capturedImage!, height: 100)
                            else
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final ImagePicker picker = ImagePicker();
                                  final XFile? photo = await picker.pickImage(
                                      source: ImageSource.camera);
                                  if (photo != null) {
                                    setDialogState(() {
                                      capturedImage = File(photo.path);
                                    });
                                  }
                                },
                                icon: Icon(Icons.camera_alt),
                                label: Text('拍照'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFF8C42),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: currentPosition != null
                                        ? Colors.green
                                        : Colors.grey),
                                SizedBox(width: 8),
                                Text('2. 获取位置 *',
                                    style:
                                    TextStyle(fontWeight: FontWeight.w500)),
                                Spacer(),
                                if (currentPosition != null)
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      if (currentPosition != null)
                        Text(
                          locationAddress ??
                              '${currentPosition!.latitude.toStringAsFixed(
                                  4)}, ${currentPosition!.longitude
                                  .toStringAsFixed(4)}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              LocationPermission permission =
                              await Geolocator.checkPermission();
                              if (permission ==
                                  LocationPermission.denied) {
                                permission =
                                await Geolocator.requestPermission();
                              }
                              if (permission ==
                                  LocationPermission.whileInUse ||
                                  permission ==
                                      LocationPermission.always) {
                                Position position =
                                await Geolocator.getCurrentPosition();
                                setDialogState(() {
                                  currentPosition = position;
                                  locationAddress = '北京市朝阳区';
                                });
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(content: Text('请授予位置权限')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('定位失败: $e')),
                              );
                            }
                          },
                          icon: Icon(Icons.location_on),
                          label: Text('获取位置'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF8C42),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      SizedBox(height: 16),
                      TextField(
                        controller: noteController,
                        decoration: InputDecoration(
                          labelText: '备注',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            actions: [
            TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
            ),
            ElevatedButton(
            onPressed: (capturedImage != null && currentPosition != null)
            ? () {
            Navigator.pop(context);

            // ❌ 原有：_currentTask 和 _events 的本地修改逻辑已移除
            // ✅ 新增：触发任务列表刷新，模拟 API 数据更新
            setState(() {
            _tasksFuture = _fetchTasksByMode(_taskFilterMode, _currentUserId);
            });

            // TODO: 未来，这里应该调用 TaskService.createCheckIn(...) API
            // 使用 collected data: capturedImage, currentPosition, noteController.text

            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('打卡成功，列表已刷新')),
            );
            }
                : null,
            child: Text('完成打卡'),
            style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF8C42),
            foregroundColor: Colors.white,
            ),
            ),
            ],
            );
            },
        );
      },
    );
  }
}
