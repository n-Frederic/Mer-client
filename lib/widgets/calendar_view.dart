import 'package:flutter/material.dart';

enum TaskStatus { pending, inProgress, completed }

class CalendarView extends StatefulWidget {
  @override
  _CalendarViewState createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView>
    with SingleTickerProviderStateMixin {
  String _viewMode = 'month'; // 当前视图模式
  DateTime _currentDate = DateTime.now(); // 当前日期
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _tabController = TabController(length: 2, vsync: this); // 正确初始化TabController
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 任务数据
  List<Map<String, dynamic>> _events = [];

  Map<String, dynamic> _currentTask = {
    'color': Colors.blue,
    'emoji': '📌',
    'title': '默认任务',
    'date': DateTime.now(),
    'time': null,
  };

  void _loadTasks() {
    _events = [
      {
        'date': DateTime.now().add(Duration(days: 3)),
        'title': '完成Q4季度报告',
        'time': '09:00',
        'color': Color(0xFFFF6B9D),
        'emoji': '📊',
        'type': 'report',
        'status': TaskStatus.inProgress,
        'progress': 0.6,
        'owner': '张三',
        'collaborators': ['李四', '王五'],
        'log': '2025-09-10: 任务分配\n2025-09-15: 进行中',
      },
      {
        'date': DateTime.now().add(Duration(days: 7)),
        'title': '新员工培训计划',
        'time': '14:00',
        'color': Color(0xFF4ECDC4),
        'emoji': '📚',
        'type': 'training',
        'status': TaskStatus.pending,
        'progress': 0.2,
        'owner': '赵六',
        'collaborators': ['孙七'],
        'log': '2025-09-12: 计划制定',
      },
      {
        'date': DateTime.now().subtract(Duration(days: 1)),
        'title': '客户服务流程优化',
        'time': '16:00',
        'color': Color(0xFFFFE66D),
        'emoji': '🤝',
        'type': 'client',
        'status': TaskStatus.completed,
        'progress': 1.0,
        'owner': '钱八',
        'collaborators': ['周九', '吴十'],
        'log': '2025-09-14: 优化完成',
      },
      {
        'date': DateTime.now().add(Duration(days: 1)),
        'title': '项目会议',
        'time': '09:00',
        'color': Color(0xFFFF6B9D),
        'emoji': '💼',
        'type': 'meeting',
        'status': TaskStatus.inProgress,
        'progress': 0.4,
        'owner': '李四',
        'collaborators': ['张三'],
        'log': '2025-09-16: 会议安排',
      },
      {
        'date': DateTime.now().add(Duration(days: 5)),
        'title': '团队建设',
        'time': '15:00',
        'color': Color(0xFFB8A9FF),
        'emoji': '🎉',
        'type': 'team',
        'status': TaskStatus.pending,
        'progress': 0.0,
        'owner': '孙七',
        'collaborators': ['赵六'],
        'log': '2025-09-17: 计划中',
      },
      {
        'date': DateTime.now().add(Duration(days: 10)),
        'title': '代码评审',
        'time': '11:00',
        'color': Color(0xFFFFB3BA),
        'emoji': '👨‍💻',
        'type': 'review',
        'status': TaskStatus.inProgress,
        'progress': 0.8,
        'owner': '周九',
        'collaborators': ['钱八'],
        'log': '2025-09-15: 评审开始',
      },
    ];
  }

  // 日期比较工具方法
  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // 判断日期是否在当前周内
  bool _isInCurrentWeek(DateTime date) {
    final startOfWeek = _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    return date.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(Duration(days: 1)));
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
            Color(0xFFFFE66D).withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Column(
        children: [
          // 新增的模块切换TabBar
          Container(
            margin: EdgeInsets.all(16),
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
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFFE66D)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Color(0xFF666666),
              tabs: [
                Tab(child: SizedBox(width: 150, child: Center(child: Text('视图')))),
                Tab(child: SizedBox(width: 150, child: Center(child: Text('任务管理')))),
              ],
              indicatorPadding: EdgeInsets.zero,
              labelPadding: EdgeInsets.zero,
              dividerColor: Colors.transparent, // 移除横线
            ),
          ),
          // 视图内容区域
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 视图页面
                Column(
                  children: [
                    // 视图切换按钮
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
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 400), // 动画时长保持不变
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation, // 使用淡入淡出效果
                            child: child,
                          );
                        },
                        child: _buildCurrentView(),
                      ),
                    ),
                  ],
                ),
                // 任务管理页面
                _buildTaskManagementView(),
              ],
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
            gradient: isSelected
                ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 22,
              ),
              SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 关键修复：确保每个视图返回不同的Widget实例
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
          key: ValueKey('month_view'),
          child: _buildMonthView(),
        );
      default:
        return _buildMonthView();
    }
  }

  Widget _buildDayView() {
    final today = DateTime.now();
    final todayEvents = _events.where((event) =>
        _isSameDate(event['date'], today)).toList();

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
                _tabController.animateTo(1); // 切换到任务管理Tab
                _showTaskDetail(event); // 显示任务详情
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
                                colors: [event['color'], event['color'].withOpacity(0.7)],
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
                                    Icon(Icons.access_time, size: 16, color: Color(0xFF666666)),
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
    final startOfWeek = _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: weekDays.map((day) {
          final dayEvents = _events.where((e) => _isSameDate(e['date'], day)).toList();
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
                          child: Center(child: Text('🌟', style: TextStyle(fontSize: 12))),
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
                      _tabController.animateTo(1); // 切换到任务管理Tab
                      _showTaskDetail(event); // 显示任务详情
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(event['emoji'], style: TextStyle(fontSize: 20)),
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

  Widget _buildMonthView() {
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
            child: Row(
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
                      color: Color(0xFFFF8C42).withValues(alpha: 0.1),
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
                      color: Color(0xFFFF8C42).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.chevron_right, color: Color(0xFFFF8C42)),
                  ),
                ),
              ],
            ),
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
                Row(
                  children: ['日', '一', '二', '三', '四', '五', '六']
                      .map((day) => Expanded(
                    child: Container(
                      height: 40,
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                  ))
                      .toList(),
                ),
                SizedBox(height: 8),
                ...List.generate(6, (weekIndex) {
                  return Row(
                    children: List.generate(7, (dayIndex) {
                      final cellIndex = weekIndex * 7 + dayIndex;
                      return Expanded(child: _buildCalendarCell(cellIndex));
                    }),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 20),
          _buildMonthEventsPreview(),
        ],
      ),
    );
  }

  Widget _buildCalendarCell(int index) {
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    final dayNumber = index - (firstWeekday - 1) + 1;
    final daysInMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;

    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return Container(height: 50);
    }

    final date = DateTime(_currentDate.year, _currentDate.month, dayNumber);
    final hasEvent = _events.any((event) => _isSameDate(event['date'], date));
    final isToday = _isSameDate(date, DateTime.now());

    return GestureDetector(
      onTap: () {
        if (hasEvent) {
          _showDayEvents(date);
        }
      },
      child: Container(
        height: 50,
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: isToday
              ? LinearGradient(colors: [Color(0xFFFF8C42), Color(0xFFFF6B9D)])
              : null,
          color: isToday ? null : (hasEvent ? Color(0xFFFFE66D).withOpacity(0.3) : null),
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
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? Colors.white : Color(0xFF333333),
              ),
            ),
            if (hasEvent)
              Container(
                width: 6,
                height: 6,
                margin: EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: isToday ? Colors.white : Color(0xFFFF8C42),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthEventsPreview() {
    final monthEvents = _events.where((event) =>
    event['date'].year == _currentDate.year &&
        event['date'].month == _currentDate.month).toList();

    if (monthEvents.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24),
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
            Text('📅', style: TextStyle(fontSize: 40)),
            SizedBox(height: 12),
            Text(
              '本月暂无任务',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 本月任务',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 16),
          ...monthEvents.take(5).map((event) => GestureDetector(
            onTap: () {
              _tabController.animateTo(1); // 跳转到任务管理
              setState(() {
                _currentTask = event;
              });
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: event['color'].withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(event['emoji'], style: TextStyle(fontSize: 20)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['title'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Text(
                          '${event['date'].day}日 ${event['time']} · 进度: ${(event['progress'] * 100).toInt()}%',
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
          if (monthEvents.length > 5)
            Center(
              child: Text(
                '还有 ${monthEvents.length - 5} 个任务...',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDayEvents(DateTime date) {
    final dayEvents = _events.where((event) =>
        _isSameDate(event['date'], date)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                '${date.month}月${date.day}日 任务',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: dayEvents.length,
                itemBuilder: (context, index) {
                  final event = dayEvents[index];
                  return GestureDetector(
                    onTap: () {
                      _tabController.animateTo(1); // 切换到任务管理Tab
                      _showTaskDetail(event); // 显示任务详情
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: event['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: event['color'].withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: event['color'],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    event['emoji'],
                                    style: TextStyle(fontSize: 24),
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      event['time'] ?? '未设置时间',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF666666),
                                      ),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    Color color;
    String text;
    switch (status) {
      case TaskStatus.pending:
        color = Colors.grey;
        text = '待开始';
        break;
      case TaskStatus.inProgress:
        color = Colors.blue;
        text = '进行中';
        break;
      case TaskStatus.completed:
        color = Colors.green;
        text = '已完成';
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
        style: TextStyle(color: color, fontSize: 12),
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
    const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return weekdays[weekday - 1];
  }


  Widget _buildTaskManagementView() {
    final monthEvents = _events.where((event) =>
    event['date'].year == _currentDate.year &&
        event['date'].month == _currentDate.month).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '任务详情',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 16),
          if (_currentTask != null)
            Container(
              padding: EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _currentTask['color'],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            _currentTask['emoji'],
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
                              _currentTask['title'],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '日期: ${_currentTask['date'].month}月${_currentTask['date'].day}日 ${_currentTask['time'] ?? '未设置时间'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '类型: ${_currentTask['type'] ?? '未知'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '负责人: ${_currentTask['owner'] ?? '未指定'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '协作者: ${_currentTask['collaborators']?.join(', ') ?? '无'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '日志: ${_currentTask['log'] ?? '无记录'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (_currentTask['progress'] ?? 0.0).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _currentTask['status'] == TaskStatus.completed
                          ? Colors.green
                          : Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '进度: ${((_currentTask['progress'] ?? 0.0) * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildStatusChip(_currentTask['status'] ?? TaskStatus.pending),
                ],
              ),
            )
          else
            Center(
              child: Text(
                '请选择一个任务以查看详情',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF999999),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 显示任务详情
  void _showTaskDetail(Map<String, dynamic> task) {
    setState(() {
      _currentTask = task;
    });
  }
}