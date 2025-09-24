import 'package:flutter/material.dart';
import 'log_view_detail.dart';

class LogView extends StatefulWidget {
  @override
  _LogViewState createState() => _LogViewState();
}

class _LogViewState extends State<LogView> with TickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedScope = 'personal'; // personal, company, external
  String _selectedMode = 'my'; // my, team, member, approval
  String _selectedTimeFilter = 'all'; // all, today, this_week, this_year
  Set<String> _selectedMembers = {};
  String _searchTerm = '';

  final Map<String, dynamic> _currentUser = {
    'name': '张小兔',
    'role': '团队长',
    'department': '技术部',
    'avatar': '🐰',
    'canViewSubordinates': true,
    'canRequestApproval': true,
  };

  final List<Map<String, dynamic>> _teamMembers = [
    {'id': '1', 'name': '小王', 'authorName': '小王', 'avatar': '🐱'},
    {'id': '2', 'name': '小李', 'authorName': '小李', 'avatar': '🐶'},
    {'id': '3', 'name': '小张', 'authorName': '小张', 'avatar': '🐼'},
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
                        child: Text(_currentUser['avatar'],
                            style: TextStyle(fontSize: 24)),
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
                    // 在这里添加搜索框
                    Expanded(
                      child: Container(
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
                            hintStyle:
                            TextStyle(color: Color(0xFF999999), fontSize: 14),
                            prefixIcon: Icon(Icons.search,
                                color: Color(0xFF999999), size: 20),
                            border: InputBorder.none,
                            contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterButton('my', '我的日志', Color(0xFFFF8C42)),
                      if (_currentUser['canViewSubordinates']) ...[
                        SizedBox(width: 8),
                        _buildFilterButton('member', '成员日志', Color(0xFFFF8C42)),
                      ],
                      SizedBox(width: 8),
                      _buildFilterButton('approval', '待审批', Color(0xFFFF8C42)),
                    ],
                  ),
                ),
                SizedBox(height: 8),
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
          Expanded(
            child: _buildLogList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String value, String label, Color color) {
    final isSelected = _selectedMode == value;
    final isMemberButton = value == 'member' && _currentUser['canViewSubordinates'];

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isMemberButton) {
            _selectedMode = value;
          } else if (value == 'my' || value == 'approval') {
            _selectedMode = value;
            _selectedMembers.clear();
          } else {
            _selectedTimeFilter = value;
          }
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isMemberButton && isSelected) ...[
              SizedBox(width: 4),
              GestureDetector(
                onTap: _showMemberSelectionDialog,
                child: Icon(
                  Icons.filter_list,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  void _showMemberSelectionDialog() {
    Set<String> tempSelectedMembers = Set.from(_selectedMembers);
    String tempSearchTerm = '';

    // 模拟层级数据，与您的实际数据结构相匹配
    final List<String> departments = ['技术部', '市场部', '销售部'];
    final Map<String, List<String>> teamsByDepartment = {
      '技术部': ['前端团队', '后端团队'],
      '市场部': ['运营团队', '品牌团队'],
      '销售部': ['国内销售', '海外销售'],
    };
    final Map<String, List<Map<String, dynamic>>> membersByTeam = {
      '前端团队': [
        {'id': '1', 'name': '小王'},
        {'id': '3', 'name': '小张'},
      ],
      '后端团队': [
        {'id': '2', 'name': '小李'},
      ],
      '运营团队': [
        {'id': '4', 'name': '小赵'},
      ],
      '品牌团队': [
        {'id': '5', 'name': '小钱'},
      ],
      '国内销售': [
        {'id': '6', 'name': '小孙'},
      ],
      '海外销售': [
        {'id': '7', 'name': '小吴'},
      ],
    };

    String? selectedDepartment;
    String? selectedTeam;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // 根据选定的部门和团队获取基础成员列表
            List<Map<String, dynamic>> baseMembers = [];
            if (selectedTeam != null) {
              baseMembers = membersByTeam[selectedTeam] ?? [];
            } else if (selectedDepartment != null) {
              List<String> teamsInDepartment = teamsByDepartment[selectedDepartment] ?? [];
              for (var team in teamsInDepartment) {
                baseMembers.addAll(membersByTeam[team] ?? []);
              }
            } else {
              baseMembers = _teamMembers;
            }

            // 在基础列表上进行模糊搜索过滤
            final filteredMembers = baseMembers.where((member) {
              return member['name'].toLowerCase().contains(tempSearchTerm.toLowerCase());
            }).toList();

            return AlertDialog(
              title: Text('选择成员'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 模糊搜索框
                    TextField(
                      decoration: InputDecoration(
                        hintText: '搜索成员...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          tempSearchTerm = value;
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    // 部门下拉菜单
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: '部门',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      value: selectedDepartment,
                      items: departments.map((String department) {
                        return DropdownMenuItem(
                          value: department,
                          child: Text(department),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          selectedDepartment = newValue;
                          selectedTeam = null;
                          tempSearchTerm = ''; // 重置搜索词
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    // 团队下拉菜单（级联）
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: '团队',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      value: selectedTeam,
                      items: selectedDepartment != null
                          ? (teamsByDepartment[selectedDepartment] ?? []).map((String team) {
                        return DropdownMenuItem(
                          value: team,
                          child: Text(team),
                        );
                      }).toList()
                          : [],
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          selectedTeam = newValue;
                          tempSearchTerm = ''; // 重置搜索词
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    // 成员列表（根据下拉菜单和搜索框双重过滤）
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredMembers.length,
                        itemBuilder: (BuildContext context, int index) {
                          final member = filteredMembers[index];
                          final isSelected = tempSelectedMembers.contains(member['id']);
                          return CheckboxListTile(
                            title: Text(member['name']),
                            value: isSelected,
                            onChanged: (bool? newValue) {
                              setDialogState(() {
                                if (newValue == true) {
                                  tempSelectedMembers.add(member['id']);
                                } else {
                                  tempSelectedMembers.remove(member['id']);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('取消'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text('确定'),
                  onPressed: () {
                    setState(() {
                      _selectedMode = 'member';
                      _selectedMembers = tempSelectedMembers;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
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
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    children: (log['tags'] as List<String>)
                        .map((tag) => Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                    ))
                        .toList(),
                  ),
                ),
                IconButton(
                  onPressed: () => _showLogDetail(log),
                  icon: Icon(Icons.visibility,
                      size: 20, color: Color(0xFF999999)),
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
      if (_searchTerm.isNotEmpty) {
        if (!log['title'].toLowerCase().contains(_searchTerm.toLowerCase()) &&
            !log['content'].toLowerCase().contains(_searchTerm.toLowerCase())) {
          return false;
        }
      }

      bool scopeMatch = false;
      switch (_selectedScope) {
        case 'personal':
          scopeMatch =
              log['scope'] == 'team' || log['author'] == _currentUser['name'];
          break;
        case 'company':
          scopeMatch =
              log['scope'] == 'department' || log['scope'] == 'company';
          break;
        case 'external':
          scopeMatch = log['scope'] == 'external';
          break;

      }
      if (!scopeMatch) return false;

      bool modeMatch = false;
      switch (_selectedMode) {
        case 'my':
          modeMatch = log['author'] == _currentUser['name'];
          break;
        case 'team':
          modeMatch = log['scope'] == 'team';
          break;
        case 'member':
        // 成员筛选逻辑
          if (_selectedMembers.isEmpty) return false;
          modeMatch = _selectedMembers.any(
                  (id) => _teamMembers.any((m) => m['id'] == id && m['name'] == log['author']));
          break;
        case 'approval':
          modeMatch = log['status'] == '待审批';
          break;
        default:
          modeMatch = true;
      }
      if (!modeMatch) return false;

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
          timeMatch = logDate
              .isAfter(startOfWeek.subtract(Duration(microseconds: 1))) &&
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
        return _selectedMembers.isEmpty ? '请选择要查看的团队成员' : '该成员暂无日志记录';
      case 'approval':
        return '暂无待审批的日志';
      default:
        return '暂无相关日志';
    }
  }

  void _showLogDetail(Map<String, dynamic> log) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogDetailView(log: log),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}