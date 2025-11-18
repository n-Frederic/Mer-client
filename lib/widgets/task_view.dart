import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../models/task_list_response.dart';
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
  Map<String, dynamic>? _currentTask;
  String _currentFilter = 'my'; // 统一使用 _currentFilter
  String _taskSearchTerm = '';

  // 分页相关状态
  List<Task> _allTasks = []; // 存储所有加载的任务
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(_currentDate.year, _currentDate.month, _currentDate.day);

    // 初始化角色加载
    _roleFuture = _fetchRoleById(3);

    _tabController = TabController(length: 2, vsync: this);

    // 初始化时加载第一页任务
    _loadTasks(reset: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 加载任务数据
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

      if (_currentFilter == 'my') {
        response = await TaskService.fetchPersonalTasks(
          page: _currentPage,
          pageSize: 20, // 每页加载更多任务
        );
      } else {
        response = await TaskService.fetchScopedTasks(
          page: _currentPage,
          pageSize: 20,
        );
      }

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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('加载任务失败: $e');
      // 可以添加错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载任务失败: $e')),
        );
      }
    }
  }

  // 刷新数据
  Future<void> _refreshTasks() async {
    await _loadTasks(reset: true);
  }

  // 加载更多数据
  void _loadMore() {
    if (_hasMore && !_isLoading) {
      _loadTasks(reset: false);
    }
  }

  Future<Role> _fetchRoleById(int roleId) async {
    await Future.delayed(Duration(milliseconds: 500));

    final fetchedRole = Role(
      roleId: roleId,
      name: 'Team Leader',
      description: '负责团队管理和审批',
    );

    if (mounted) {
      setState(() {
        _currentUserRole = fetchedRole;
      });
    }
    return fetchedRole;
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
                _buildViewModeButton('day', '日视图', Icons.today, Color(0xFFFF6B9D)),
                _buildViewModeButton('week', '周视图', Icons.calendar_view_week, Color(0xFFFF9F51)),
                _buildViewModeButton('month', '月视图', Icons.calendar_view_month, Color(0xFF4ECDC4)),
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

  Widget _buildViewModeButton(String mode, String label, IconData icon, Color color) {
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
              _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
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
              _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
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
          .map((day) => Expanded(
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
    if (_selectedDay.year != _currentDate.year || _selectedDay.month != _currentDate.month) {
      _selectedDay = DateTime(_currentDate.year, _currentDate.month, 1);
    }

    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final int firstWeekdayOffset = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    final daysInMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;
    final totalCells = firstWeekdayOffset + daysInMonth;
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
          _buildSelectedDayTasks(),
        ],
      ),
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
    final dateOnly = DateTime(date.year, date.month, date.day);

    // 使用 _allTasks 而不是 _cachedTasks
    final List<Task> dailyEvents = _allTasks.where((task) {
      // 跳过已完成的任务
      if (task.status == TaskStatus.completed) return false;

      // 如果任务有开始时间和截止时间，检查当前日期是否在任务周期内
      if (task.startAt != null && task.dueAt != null) {
        final taskStartDate = DateTime(task.startAt!.year, task.startAt!.month, task.startAt!.day);
        final taskDueDate = DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);

        // 检查当前日期是否在 [开始日期, 截止日期] 范围内（包含开始和结束日期）
        return (dateOnly.isAfter(taskStartDate.subtract(Duration(days: 1))) &&
            dateOnly.isBefore(taskDueDate.add(Duration(days: 1))));
      }

      // 如果只有截止时间，显示从今天到截止日的所有日期
      if (task.dueAt != null) {
        final taskDueDate = DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);
        final todayOnly = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

        // 检查当前日期是否在 [今天, 截止日期] 范围内
        final isDateTodayOrFuture = dateOnly.isAfter(todayOnly.subtract(Duration(days: 1)));
        final isDateOnOrBeforeDueDate = dateOnly.isBefore(taskDueDate.add(Duration(days: 1)));

        return isDateTodayOrFuture && isDateOnOrBeforeDueDate;
      }

      // 如果只有开始时间，显示从开始日期到未来的所有日期
      if (task.startAt != null) {
        final taskStartDate = DateTime(task.startAt!.year, task.startAt!.month, task.startAt!.day);

        // 检查当前日期是否在 [开始日期, 未来] 范围内
        return dateOnly.isAfter(taskStartDate.subtract(Duration(days: 1)));
      }

      return false;
    }).toList();

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
          gradient: isToday ? LinearGradient(colors: [Color(0xFFFF8C42), Color(0xFFFF6B9D)]) : null,
          color: isToday ? null : (eventCount > 0 ? Color(0xFFFFE66D).withOpacity(0.3) : null),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isToday ? [
            BoxShadow(
              color: Color(0xFFFF8C42).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ] : null,
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

  Widget _buildSelectedDayTasks() {
    // 使用 _allTasks 而不是 _cachedTasks
    final selectedDayTasks = _allTasks.where((task) {
      if (task.status == TaskStatus.completed) return false;

      final selectedDayOnly = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

      if (task.startAt != null && task.dueAt != null) {
        final taskStartDate = DateTime(task.startAt!.year, task.startAt!.month, task.startAt!.day);
        final taskDueDate = DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);

        return (selectedDayOnly.isAfter(taskStartDate.subtract(Duration(days: 1))) &&
            selectedDayOnly.isBefore(taskDueDate.add(Duration(days: 1))));
      }

      if (task.dueAt != null) {
        final taskDueDate = DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);
        final todayOnly = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

        final isDateTodayOrFuture = selectedDayOnly.isAfter(todayOnly.subtract(Duration(days: 1)));
        final isDateOnOrBeforeDueDate = selectedDayOnly.isBefore(taskDueDate.add(Duration(days: 1)));

        return isDateTodayOrFuture && isDateOnOrBeforeDueDate;
      }

      if (task.startAt != null) {
        final taskStartDate = DateTime(task.startAt!.year, task.startAt!.month, task.startAt!.day);
        return selectedDayOnly.isAfter(taskStartDate.subtract(Duration(days: 1)));
      }

      return false;
    }).toList();

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
            ? Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Text('当天没有任务', style: TextStyle(color: Color(0xFF999999))),
            ))
            : ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: selectedDayTasks.length,
          itemBuilder: (context, index) {
            final task = selectedDayTasks[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskDetailView(
                      taskId: task.taskId,
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
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  children: [
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

  // 日视图 - 显示当天任务
  Widget _buildDayView() {
    final today = DateTime.now();

    // 使用 _allTasks 而不是 _cachedTasks
    final todayTasks = _allTasks.where((task) {
      if (task.status == TaskStatus.completed) return false;

      final todayOnly = DateTime(today.year, today.month, today.day);

      if (task.startAt != null && task.dueAt != null) {
        final taskStartDate = DateTime(task.startAt!.year, task.startAt!.month, task.startAt!.day);
        final taskDueDate = DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);

        return (todayOnly.isAfter(taskStartDate.subtract(Duration(days: 1))) &&
            todayOnly.isBefore(taskDueDate.add(Duration(days: 1))));
      }

      if (task.dueAt != null) {
        final taskDueDate = DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);

        final isDateTodayOrFuture = todayOnly.isAfter(DateTime.now().subtract(Duration(days: 1)));
        final isDateOnOrBeforeDueDate = todayOnly.isBefore(taskDueDate.add(Duration(days: 1)));

        return isDateTodayOrFuture && isDateOnOrBeforeDueDate;
      }

      return false;
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 日期头
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
                SizedBox(height: 8),
                Text(
                  '今日任务: ${todayTasks.length}个',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // 任务列表
          if (todayTasks.isEmpty)
            _buildEmptyState('今天没有任务', '享受轻松的一天吧！')
          else
            ...todayTasks.map((task) => _buildTaskCard(task)),
        ],
      ),
    );
  }

  // 周视图 - 显示一周任务
  Widget _buildWeekView() {
    final startOfWeek = _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 周标题
          Container(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_getMonthName(startOfWeek.month)}${startOfWeek.day}日',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text('至', style: TextStyle(color: Color(0xFF666666))),
                Text(
                  '${_getMonthName(weekDays.last.month)}${weekDays.last.day}日',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          // 每日任务
          ...weekDays.map((day) {
            // 使用 _allTasks 而不是 _cachedTasks
            final dayTasks = _allTasks.where((task) {
              if (task.status == TaskStatus.completed) return false;

              final dayOnly = DateTime(day.year, day.month, day.day);

              if (task.startAt != null && task.dueAt != null) {
                final taskStartDate = DateTime(task.startAt!.year, task.startAt!.month, task.startAt!.day);
                final taskDueDate = DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);

                return (dayOnly.isAfter(taskStartDate.subtract(Duration(days: 1))) &&
                    dayOnly.isBefore(taskDueDate.add(Duration(days: 1))));
              }

              if (task.dueAt != null) {
                final taskDueDate = DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);
                final todayOnly = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

                final isDateTodayOrFuture = dayOnly.isAfter(todayOnly.subtract(Duration(days: 1)));
                final isDateOnOrBeforeDueDate = dayOnly.isBefore(taskDueDate.add(Duration(days: 1)));

                return isDateTodayOrFuture && isDateOnOrBeforeDueDate;
              }

              return false;
            }).toList();

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
                    Row(
                      children: [
                        Text(
                          '${day.month}月${day.day}日 ${_getWeekdayName(day.weekday)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isToday ? Color(0xFFFF6B9D) : Color(0xFF333333),
                          ),
                        ),
                        SizedBox(width: 8),
                        if (isToday)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF6B9D),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '今天',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        Spacer(),
                        Text(
                          '${dayTasks.length}个任务',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (dayTasks.isEmpty)
                      _buildEmptyDayState()
                    else
                      ...dayTasks.take(3).map((task) => _buildWeekTaskItem(task)),
                    if (dayTasks.length > 3)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          '还有${dayTasks.length - 3}个任务...',
                          style: TextStyle(color: Color(0xFF999999), fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // 周视图任务项
  Widget _buildWeekTaskItem(Task task) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailView(
              taskId: task.taskId,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getStatusColor(task.status),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    task.dueAt != null
                        ? '${task.dueAt!.hour.toString().padLeft(2, '0')}:${task.dueAt!.minute.toString().padLeft(2, '0')}'
                        : '未设置时间',
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
    );
  }

  // 日视图任务卡片
  Widget _buildTaskCard(Task task) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailView(
              taskId: task.taskId,
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
                      color: _getStatusColor(task.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        _getTaskIcon(task.status),
                        color: _getStatusColor(task.status),
                        size: 28,
                      ),
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
                            Icon(Icons.access_time, size: 16, color: Color(0xFF666666)),
                            SizedBox(width: 4),
                            Text(
                              task.dueAt != null
                                  ? '截止 ${task.dueAt!.hour.toString().padLeft(2, '0')}:${task.dueAt!.minute.toString().padLeft(2, '0')}'
                                  : '未设置时间',
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
              if (task.description.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    task.description,
                    style: TextStyle(color: Color(0xFF666666), fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              LinearProgressIndicator(
                value: _getTaskProgress(task.status),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(task.status)),
              ),
              SizedBox(height: 4),
              Text(
                '进度: ${(_getTaskProgress(task.status) * 100).toInt()}%',
                style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 空状态组件
  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
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
            child: Center(child: Text('🌟', style: TextStyle(fontSize: 40))),
          ),
          SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildEmptyDayState() {
    return Container(
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
            child: Center(child: Text('🌟', style: TextStyle(fontSize: 12))),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('暂无任务', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                Text('当天无安排', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 辅助方法
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

  double _getTaskProgress(TaskStatus status) {
    switch (status) {
      case TaskStatus.published: return 0.3;
      case TaskStatus.reported: return 0.6;
      case TaskStatus.completed: return 1.0;
      case TaskStatus.closed: return 1.0;
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

  String _getMonthName(int month) {
    const months = ['', '一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月'];
    return months[month];
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    return weekdays[weekday % 7];
  }

  // 修改筛选按钮方法
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
          boxShadow: isSelected ? [
            BoxShadow(
              color: Color(0xFFFF8C42).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ] : null,
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          child: RefreshIndicator(
            onRefresh: _refreshTasks,
            child: _buildTaskList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList() {
    // 过滤和搜索逻辑
    List<Task> filteredTasks = _allTasks.where((task) {
      if (_taskSearchTerm.isEmpty) return true;

      final searchTerm = _taskSearchTerm.toLowerCase();
      return task.title.toLowerCase().contains(searchTerm) ||
          (task.description?.toLowerCase().contains(searchTerm) ?? false);
    }).toList();

    // 排序逻辑
    filteredTasks.sort((a, b) => a.dueAt?.compareTo(b.dueAt ?? DateTime(9999)) ?? -1);

    if (filteredTasks.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('暂无任务', style: TextStyle(color: Color(0xFF666666))),
            if (_taskSearchTerm.isNotEmpty)
              TextButton(
                onPressed: _refreshTasks,
                child: Text('清空搜索'),
              ),
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
      itemCount: filteredTasks.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 加载更多指示器
        if (index == filteredTasks.length) {
          return _buildLoadMoreIndicator();
        }

        final task = filteredTasks[index];
        return _buildTaskItem(task);
      },
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
            builder: (context) => TaskDetailView(
              taskId: task.taskId,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusColor(task.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(_getTaskIcon(task.status), color: _getStatusColor(task.status), size: 20),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
}