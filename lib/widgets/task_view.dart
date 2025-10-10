import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'task_detail_view.dart';
import 'enums.dart' hide TaskStatus;
import '../models/task.dart';
import '../services/task_service.dart';

class CalendarView extends StatefulWidget {
  @override
  _CalendarViewState createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView>
    with SingleTickerProviderStateMixin {
  String _viewMode = 'month';
  DateTime _currentDate = DateTime.now();
  late TabController _tabController;
  UserRole _currentUserRole = UserRole.teamLeader;
  String _currentUserId = '张三';
  Map<String, dynamic>? _currentTask;
  String _taskFilterMode = 'my';
  String _taskSearchTerm = '';

  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDay =
        DateTime(_currentDate.year, _currentDate.month, _currentDate.day);
    _loadTasks();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _events = [];

  void _loadTasks() {
    final now = DateTime.now();

    _events = [
      {
        'id': '1',
        'date': now.add(Duration(days: 2)),
        'title': '完成Q4季度报告',
        'time': '09:00',
        'color': Color(0xFFFF6B9D),
        'emoji': '📊',
        'type': 'report',
        'status': TaskStatus.inProgress,
        'progress': 0.6,
        'owner': '张三',
        'assignedTo': '张三',
        'collaborators': ['李四', '王五'],
        'log': '2025-09-10: 任务分配\n2025-09-15: 进行中',
        'description': '完成第四季度的详细业务报告，包括销售数据分析和市场趋势预测',
        'subtasks': [],
        'checkIns': [],
        'requiresLocationCheckIn': true,
        'requiresPhotoCheckIn': true,
      },
      {
        'id': '2',
        'date': now.add(Duration(days: 5)),
        'title': '会议室设备检查',
        'time': '14:00',
        'color': Color(0xFF4ECDC4),
        'emoji': '🛠️',
        'type': 'maintenance',
        'status': TaskStatus.assigned,
        'progress': 0.0,
        'owner': '李四',
        'assignedTo': '李四',
        'collaborators': ['王五'],
        'log': '2025-09-15: 任务分配',
        'description': '组织一次团队建设活动以提高凝聚力',
        'subtasks': [],
        'checkIns': [],
        'requiresLocationCheckIn': false,
        'requiresPhotoCheckIn': false,
      },
    ];
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
                    'week', '周视图', Icons.calendar_view_week, Color(0xFFFF9F51)),
                _buildViewModeButton('month', '月视图', Icons.calendar_view_month,
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

  Widget _buildViewModeButton(
      String mode, String label, IconData icon, Color color) {
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

    // --- 动态计算所需行数（周数） ---
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    // firstWeekday: 1=Mon, ..., 7=Sun. (Dart standard)
    // firstWeekdayOffset: Calendar starts on Sun (index 0). Sun=0, Mon=1, ..., Sat=6.
    final int firstWeekdayOffset = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;

    // 计算本月总天数
    final daysInMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;

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
                      return Expanded(child: _buildCalendarCellFixed(cellIndex));
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
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // 新的逻辑：任务在今天到截止日期间都显示
    final dailyEvents = _events.where((event) {
      if (event['status'] == TaskStatus.completed) return false;

      final eventDateOnly =
          DateTime(event['date'].year, event['date'].month, event['date'].day);

      // 1. 检查任务截止日是否在今天或未来
      final isEventDueTodayOrFuture =
          eventDateOnly.isAfter(todayOnly.subtract(Duration(days: 1)));
      if (!isEventDueTodayOrFuture) return false;

      // 2. 检查当前日历单元格日期是否在 [今天, 任务截止日] 区间内
      final isCellDateTodayOrFuture =
          dateOnly.isAfter(todayOnly.subtract(Duration(days: 1)));
      final isCellDateOnOrBeforeDueDate =
          dateOnly.isBefore(eventDateOnly.add(Duration(days: 1)));

      return isCellDateTodayOrFuture && isCellDateOnOrBeforeDueDate;
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

  Widget _buildSelectedDayTasks() {
    final allEvents = _events;
    // 过滤：只显示任务截止日是 _selectedDay 的任务
    final selectedDayEvents = allEvents
        .where((event) => _isSameDate(event['date'], _selectedDay))
        .toList();

    return Column(
      // 移除 Container 保持简洁
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            '${_selectedDay.month}月${_selectedDay.day}日 任务 (${selectedDayEvents.length}个)',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333)),
          ),
        ),
        selectedDayEvents.isEmpty
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
                itemCount: selectedDayEvents.length,
                itemBuilder: (context, index) {
                  final event = selectedDayEvents[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentTask = event;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetailView(
                            task: event,
                            userRole: _currentUserRole,
                            currentUserId: _currentUserId,
                            onTaskUpdated: (updatedTask) {
                              setState(() {
                                final index = _events.indexWhere(
                                    (e) => e['id'] == updatedTask['id']);
                                if (index != -1) {
                                  _events[index] = updatedTask;
                                }
                                _currentTask = updatedTask;
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
                          Text(event['emoji'], style: TextStyle(fontSize: 20)),
                          SizedBox(width: 12),
                          Expanded(child: Text(event['title'])),
                          _buildStatusChip(event['status']),
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

  Widget _buildDayView() {
    final today = DateTime.now();
    final todayEvents =
        _events.where((event) => _isSameDate(event['date'], today)).toList();

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
          if (todayEvents.isEmpty)
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
            ...todayEvents.map((event) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentDate = event['date'];
                      _tabController.animateTo(1);
                    });
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
                                  gradient: LinearGradient(
                                    colors: [
                                      event['color'],
                                      event['color'].withOpacity(0.7)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: event['color'].withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    event['emoji'],
                                    style: TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event['title'],
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
                                          event['time'] ?? '未设置时间',
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
                              _buildStatusChip(event['status']),
                            ],
                          ),
                          SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: event['progress'],
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              event['status'] == TaskStatus.completed
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '进度: ${(event['progress'] * 100).toInt()}%',
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

  Widget _buildWeekView() {
    final startOfWeek =
        _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
    final weekDays =
        List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: weekDays.map((day) {
          final dayEvents =
              _events.where((e) => _isSameDate(e['date'], day)).toList();
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
                if (dayEvents.isEmpty)
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
                  ...dayEvents.map((event) => GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentDate = event['date'];
                            _tabController.animateTo(1);
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Text(event['emoji'],
                                  style: TextStyle(fontSize: 20)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event['title'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    Text(
                                      '${event['time'] ?? '未设置时间'} · 进度: ${(event['progress'] * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatusChip(event['status']),
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
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w500),
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
    const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
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
    List<Map<String, dynamic>> filteredTasks;
    if (_taskFilterMode == 'my') {
      filteredTasks =
          _events.where((e) => e['assignedTo'] == _currentUserId).toList();
    } else {
      filteredTasks = _events;
    }

    if (_taskSearchTerm.isNotEmpty) {
      final searchTerm = _taskSearchTerm.toLowerCase();
      filteredTasks = filteredTasks.where((task) {
        final title = task['title']?.toLowerCase() ?? '';
        final description = task['description']?.toLowerCase() ?? '';
        return title.contains(searchTerm) || description.contains(searchTerm);
      }).toList();
    }

    filteredTasks.sort((a, b) => a['date'].compareTo(b['date']));

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
          child: filteredTasks.isEmpty
              ? Center(
                  child:
                      Text('暂无任务', style: TextStyle(color: Color(0xFF666666))))
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final event = filteredTasks[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentTask = event;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskDetailView(
                              task: event,
                              userRole: _currentUserRole,
                              currentUserId: _currentUserId,
                              onTaskUpdated: (updatedTask) {
                                setState(() {
                                  final index = _events.indexWhere(
                                      (e) => e['id'] == updatedTask['id']);
                                  if (index != -1) {
                                    _events[index] = updatedTask;
                                  }
                                  _currentTask = updatedTask;
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
                                color: event['color'],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                  child: Text(event['emoji'],
                                      style: TextStyle(fontSize: 20))),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event['title'],
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${event['date'].month}月${event['date'].day}日 · ${event['time']} · 进度: ${(event['progress'] * 100).toInt()}%',
                                    style: TextStyle(
                                        fontSize: 12, color: Color(0xFF666666)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _handleCheckIn() async {
    showDialog(
      context: context,
      builder: (context) {
        File? capturedImage;
        Position? currentPosition;
        String? locationAddress;
        final noteController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double maxHeight = MediaQuery.of(context).size.height * 0.7;

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
                            SizedBox(height: 8),
                            if (currentPosition != null)
                              Text(
                                locationAddress ??
                                    '${currentPosition!.latitude.toStringAsFixed(4)}, ${currentPosition!.longitude.toStringAsFixed(4)}',
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
                          ],
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
                          setState(() {
                            _currentTask!['checkIns'].add({
                              'userId': _currentUserId,
                              'timestamp': DateTime.now(),
                              'photo': capturedImage!.path,
                              'location': locationAddress ??
                                  '${currentPosition!.latitude}, ${currentPosition!.longitude}',
                              'note': noteController.text.isNotEmpty
                                  ? noteController.text
                                  : '任务打卡'
                            });
                            final eventIndex = _events.indexWhere(
                                (e) => e['id'] == _currentTask!['id']);
                            if (eventIndex != -1) {
                              _events[eventIndex] = _currentTask!;
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('打卡成功')),
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
