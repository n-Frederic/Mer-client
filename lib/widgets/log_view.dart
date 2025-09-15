import 'package:flutter/material.dart';

class LogView extends StatefulWidget {
  @override
  _LogViewState createState() => _LogViewState();
}

class _LogViewState extends State<LogView> with TickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedScope = 'personal'; // personal, company, external
  String _selectedMode = 'my'; // my, team, member, approval
  String _selectedTimeFilter = 'all'; // all, today, this_week, this_year
  String _selectedMember = '';
  String _searchTerm = '';

  // 当前用户信息
  final Map<String, dynamic> _currentUser = {
    'name': '张小兔',
    'role': '团队长',
    'department': '技术部',
    'avatar': '🐰',
    'canViewSubordinates': true,
    'canRequestApproval': true,
  };

  // 团队成员
  final List<Map<String, dynamic>> _teamMembers = [
    {'id': '1', 'name': '小王', 'avatar': '🐱'},
    {'id': '2', 'name': '小李', 'avatar': '🐶'},
    {'id': '3', 'name': '小张', 'avatar': '🐼'},
  ];

  final List<Map<String, dynamic>> _logs = [
    {
      'id': '1',
      'title': '项目进展汇报',
      'content': '本周完成了用户界面优化，团队协作效率提升明显。下周计划开始后端接口对接工作。',
      'author': '张小兔',
      'authorAvatar': '🐰',
      'date': DateTime.now(),
      'mood': '😊',
      'tags': ['项目', '团队'],
      'status': '已通过',
      'scope': 'department',
    },
    {
      'id': '2',
      'title': '技能学习记录',
      'content': '深入学习了Flutter状态管理，对Provider有了更深理解。',
      'author': '小王',
      'authorAvatar': '🐱',
      'date': DateTime.now().subtract(Duration(hours: 2)),
      'mood': '🔥',
      'tags': ['学习', '技术'],
      'status': '待审批',
      'scope': 'team',
    },
    {
      'id': '3',
      'title': '客户反馈处理',
      'content': '处理了客户提出的UI优化建议，客户表示满意。',
      'author': '小李',
      'authorAvatar': '🐶',
      'date': DateTime.now().subtract(Duration(days: 1)),
      'mood': '😊',
      'tags': ['客户', '反馈'],
      'status': '已通过',
      'scope': 'company',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
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
          // 用户信息头部
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 用户基本信息
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(0xFFFF8C42).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(_currentUser['avatar'], style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentUser['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          Text(
                            '${_currentUser['role']} · ${_currentUser['department']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 权限标识
                    if (_currentUser['canViewSubordinates'])
                      Container(
                        margin: EdgeInsets.only(right: 8),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF4ECDC4).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_downward, size: 12, color: Color(0xFF4ECDC4)),
                            SizedBox(width: 4),
                            Text(
                              '可查看下级',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF4ECDC4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_currentUser['canRequestApproval'])
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF667eea).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_upward, size: 12, color: Color(0xFF667eea)),
                            SizedBox(width: 4),
                            Text(
                              '可申请审批',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF667eea),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),

                // 板块切换 (顶部 Tab)
                Row(
                  children: [
                    _buildScopeTab('personal', '👥 个人板块', Color(0xFF667eea)),
                    SizedBox(width: 8),
                    _buildScopeTab('company', '🏢 公司板块', Color(0xFF4ECDC4)),
                    SizedBox(width: 8),
                    _buildScopeTab('external', '🌐 其他公司', Color(0xFF764ba2)),
                  ],
                ),
                SizedBox(height: 12),

                // 搜索框
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchTerm = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: '搜索日志...',
                      hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF999999), size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                SizedBox(height: 12),

                // 固定筛选条件 - 模式
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterButton('my', '我的日志', Color(0xFFFF8C42)),
                      if (_currentUser['canViewSubordinates']) ...[
                        SizedBox(width: 8),
                        _buildFilterButton('team', '团队日志', Color(0xFFFF8C42)),
                        SizedBox(width: 8),
                        _buildFilterButton('member', '成员日志', Color(0xFFFF8C42)),
                      ],
                      SizedBox(width: 8),
                      _buildFilterButton('approval', '待审批', Color(0xFFFF8C42)),
                    ],
                  ),
                ),
                SizedBox(height: 8),

                // 固定筛选条件 - 成员（仅在成员日志模式下显示）
                if (_selectedMode == 'member' && _currentUser['canViewSubordinates'])
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: _teamMembers.map((member) {
                        return Row(
                          children: [
                            _buildMemberButton(member['id'], '${member['avatar']} ${member['name']}', Color(0xFFFF8C42)),
                            SizedBox(width: 8),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                if (_selectedMode == 'member' && _currentUser['canViewSubordinates']) SizedBox(height: 8),

                // 固定筛选条件 - 时间范围
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterButton('all', '全部', Color(0xFF4ECDC4)),
                      SizedBox(width: 8),
                      _buildFilterButton('today', '本日', Color(0xFF4ECDC4)),
                      SizedBox(width: 8),
                      _buildFilterButton('this_week', '本周', Color(0xFF4ECDC4)),
                      SizedBox(width: 8),
                      _buildFilterButton('this_year', '本年', Color(0xFF4ECDC4)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 日志列表
          Expanded(
            child: _buildLogList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeTab(String scope, String label, Color color) {
    bool isSelected = _selectedScope == scope;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedScope = scope;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String value, String label, Color color) {
    bool isSelected = _selectedMode == value || _selectedTimeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (value == 'my' || value == 'team' || value == 'member' || value == 'approval') {
            _selectedMode = value;
            if (_selectedMode != 'member') _selectedMember = '';
          } else {
            _selectedTimeFilter = value;
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMemberButton(String value, String label, Color color) {
    bool isSelected = _selectedMember == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMember = isSelected ? '' : value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLogList() {
    List<Map<String, dynamic>> filteredLogs = _getFilteredLogs();

    if (filteredLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📝', style: TextStyle(fontSize: 60)),
            SizedBox(height: 16),
            Text(
              '暂无日志记录',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
            SizedBox(height: 8),
            Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        return _buildLogCard(filteredLogs[index]);
      },
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 作者信息和状态
            Row(
              children: [
                Text(log['authorAvatar'], style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      Text(
                        log['author'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(log['status']),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    log['status'],
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  _formatDate(log['date']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // 内容
            Text(
              log['content'],
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),

            // 标签和操作
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    children: (log['tags'] as List<String>).map((tag) =>
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFE66D).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFFFF8C42),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ).toList(),
                  ),
                ),
                IconButton(
                  onPressed: () => _showLogDetail(log),
                  icon: Icon(Icons.visibility, size: 20, color: Color(0xFF999999)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredLogs() {
    final now = DateTime.now();
    return _logs.where((log) {
      // 搜索过滤
      if (_searchTerm.isNotEmpty) {
        if (!log['title'].toLowerCase().contains(_searchTerm.toLowerCase()) &&
            !log['content'].toLowerCase().contains(_searchTerm.toLowerCase())) {
          return false;
        }
      }

      // 板块过滤
      bool scopeMatch = false;
      switch (_selectedScope) {
        case 'personal':
          scopeMatch = log['scope'] == 'team' || log['author'] == _currentUser['name'];
          break;
        case 'company':
          scopeMatch = log['scope'] == 'department' || log['scope'] == 'company';
          break;
        case 'external':
          scopeMatch = log['scope'] == 'external';
          break;
      }
      if (!scopeMatch) return false;

      // 模式过滤
      bool modeMatch = false;
      switch (_selectedMode) {
        case 'my':
          modeMatch = log['author'] == _currentUser['name'];
          break;
        case 'team':
          modeMatch = log['scope'] == 'team';
          break;
        case 'member':
          if (_selectedMember.isEmpty) return false;
          String memberName = _teamMembers.firstWhere(
                (m) => m['id'] == _selectedMember,
            orElse: () => {'name': ''},
          )['name'];
          modeMatch = log['author'] == memberName;
          break;
        case 'approval':
          modeMatch = log['status'] == '待审批';
          break;
        default:
          modeMatch = true;
      }
      if (!modeMatch) return false;

      // 时间过滤
      DateTime logDate = log['date'];
      bool timeMatch = false;
      switch (_selectedTimeFilter) {
        case 'all':
          timeMatch = true;
          break;
        case 'today':
          timeMatch = logDate.year == now.year &&
              logDate.month == now.month &&
              logDate.day == now.day;
          break;
        case 'this_week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(Duration(days: 6));
          timeMatch = logDate.isAfter(startOfWeek.subtract(Duration(microseconds: 1))) &&
              logDate.isBefore(endOfWeek.add(Duration(days: 1)));
          break;
        case 'this_year':
          timeMatch = logDate.year == now.year;
          break;
      }

      return timeMatch;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '已通过':
        return Color(0xFF4ECDC4);
      case '待审批':
        return Color(0xFFFFE66D);
      case '已拒绝':
        return Color(0xFFFF6B9D);
      default:
        return Color(0xFF999999);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else {
      return '${difference.inDays}天前';
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedMode) {
      case 'my':
        return '还没有个人日志，开始记录吧！';
      case 'team':
        return '团队暂无日志记录';
      case 'member':
        return _selectedMember.isEmpty ? '请选择要查看的团队成员' : '该成员暂无日志记录';
      case 'approval':
        return '暂无待审批的日志';
      default:
        return '暂无相关日志';
    }
  }

  void _showLogDetail(Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(log['authorAvatar'], style: TextStyle(fontSize: 24)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log['title'],
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              Text(
                                '${log['author']} · ${_formatDate(log['date'])}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(log['status']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            log['status'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        log['content'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF333333),
                          height: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (log['tags'] as List<String>).map((tag) =>
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFF8C42), Color(0xFFFFE66D)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}