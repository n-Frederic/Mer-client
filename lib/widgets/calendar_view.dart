import 'package:flutter/material.dart';

enum TaskStatus { pending, inProgress, completed }

class CalendarView extends StatefulWidget {
  @override
  _CalendarViewState createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  String _viewMode = 'month'; // 当前视图模式
  DateTime _currentDate = DateTime.now(); // 当前日期

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // 任务数据
  List<Map<String, dynamic>> _events = [];

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
            Color(0xFFFFE66D).withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        children: [
          // 视图切换按钮
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
            child: Row(
              children: [
                _buildViewModeButton('day', '日视图', Icons.today, Color(0xFFFF6B9D)),
                _buildViewModeButton('week', '周视图', Icons.calendar_view_week, Color(0xFFFF9F51)),
                _buildViewModeButton('month', '月视图', Icons.calendar_view_month, Color(0xFF4ECDC4)),
                _buildViewModeButton('year', '年视图', Icons.calendar_today, Color(0xFFFFE66D)),
              ],
            ),
          ),

          // 内容区域 - 关键修复：确保不同视图返回不同Widget
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              // 为每个视图添加唯一key，确保切换时重新构建
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
      case 'year':
        return KeyedSubtree(
          key: ValueKey('year_view'),
          child: _buildYearView(),
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
          // 日期展示卡片
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

          // 当天任务列表
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
            ...todayEvents.map((event) => Container(
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
            )),
        ],
      ),
    );
  }

  Widget _buildMonthView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 月份导航
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
            ),
          ),
          SizedBox(height: 20),

          // 日历网格
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
                // 星期标题
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

                // 日期网格
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

          // 本月任务预览
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
          ...monthEvents.take(5).map((event) => Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: event['color'].withOpacity(0.1),
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

  Widget _buildYearView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 年份标题
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF8C42), Color(0xFFFFE66D)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFF8C42).withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${_currentDate.year}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '年度任务总览',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // 月份网格
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final monthEvents = _events.where((event) =>
              event['date'].year == _currentDate.year &&
                  event['date'].month == month).length;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentDate = DateTime(_currentDate.year, month);
                    _viewMode = 'month';
                  });
                },
                child: Container(
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getMonthName(month),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      SizedBox(height: 8),
                      if (monthEvents > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF8C42), Color(0xFFFFE66D)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$monthEvents 个任务',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '无任务',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
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
                  return Container(
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

  // 简化的周视图：只显示本周任务，基本样式，调整无任务状态对齐
  Widget _buildWeekView() {
    // 计算本周的起始日期（周一）
    final startOfWeek = _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
    // 生成本周的所有日期（周一至周日）
    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: weekDays.map((day) {
          // 获取当天的所有任务
          final dayEvents = _events.where((e) => _isSameDate(e['date'], day)).toList();
          // 判断是否是今天
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
                // 日期标题
                Text(
                  '${day.month}月${day.day}日 ${_getWeekdayName(day.weekday)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Color(0xFFFF6B9D) : Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 8),
                // 无任务状态
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
                // 有任务状态
                else
                  ...dayEvents.map((event) => Padding(
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
                  )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}