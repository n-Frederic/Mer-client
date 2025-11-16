import 'package:flutter/material.dart';
import 'log_view_detail.dart';
import '../models/log.dart';
import '../services/log_service.dart';
import '../models/user.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';

class LogView extends StatefulWidget {
  @override
  _LogViewState createState() => _LogViewState();
}

class _LogViewState extends State<LogView> with TickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedMode = 'my'; // my, team, approval
  String _selectedTimeFilter = 'all'; // all, today, this_week, this_year
  Set<String> _selectedMembers = {};
  String _searchTerm = '';
  Map<String, User> _userCache = {};
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<LogListResponse> _logsFuture;
  List<String> _searchTags = [];

  Map<String, dynamic> _currentUser = {
    'name': '加载中...',
    'role': '...',
    'department': '...',
    'avatar': '👤',
    'canViewSubordinates': false,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
    _logsFuture = _fetchLogs();
    _profileFuture = ProfileService.getUserProfile();
    _loadUserProfile();
  }

  // 【新增】加载用户信息
  void _loadUserProfile() async {
    try {
      final profileData = await ProfileService.getUserProfile();
      if (profileData['user'] != null) {
        final user = profileData['user'] as Map<String, dynamic>;
        setState(() {
          _currentUser = {
            'name': user['name'] ?? '未知姓名',
            'role': 'ID: ${user['role_id'] ?? '?'}',
            'department': user['team'] ?? '未知团队',
            'avatar': (user['name'] as String? ?? '').isNotEmpty
                ? (user['name'] as String).substring(0, 1)
                : '👤',
            'canViewSubordinates': true, // 临时硬编码
          };
        });
      }
    } catch (e) {
      print('加载用户信息失败: $e');
    }
  }

  Future<LogListResponse> _fetchLogs() {
    // 当 _selectedMode 为 'member' 但没有选择成员时，返回空列表
    if (_selectedMode == 'member' && _selectedMembers.isEmpty) {
      return Future.value(LogListResponse(logs: [], total: 0, page: 1, pageSize: 10));
    }

    return LogService.fetchScopedLogs(
      mode: _selectedMode,
      timeFilter: _selectedTimeFilter,
      keyword: _searchTerm,
      tags: _searchTags,
      memberIds: _selectedMode == 'member' ? _selectedMembers.toList() : null,
    );
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
                    // 搜索框
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            final List<String> tags = [];
                            final List<String> keywords = [];
                            final parts = value.split(' ');

                            for (final part in parts) {
                              if (part.startsWith('#') && part.length > 1) {
                                // 是标签
                                tags.add(part.substring(1));
                              } else if (part.isNotEmpty) {
                                // 是普通关键词
                                keywords.add(part);
                              }
                            }

                            // 更新状态变量
                            _searchTerm = keywords.join(' ');
                            _searchTags = tags;

                            // 触发 API 调用
                            setState(() {
                              _logsFuture = _fetchLogs();
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
                      _buildFilterButton('my', '我的日志', Color(0xFFFF8C42), _currentUser['canViewSubordinates'] as bool),
                      if (_currentUser['canViewSubordinates'] as bool) ...[
                        SizedBox(width: 8),
                        _buildFilterButton('member', '成员日志', Color(0xFFFF8C42), _currentUser['canViewSubordinates'] as bool),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterButton('all', '全部', Color(0xFF4ECDC4), _currentUser['canViewSubordinates'] as bool),
                      SizedBox(width: 8),
                      _buildFilterButton('today', '本日', Color(0xFF4ECDC4), _currentUser['canViewSubordinates'] as bool),
                      SizedBox(width: 8),
                      _buildFilterButton('this_week', '本周', Color(0xFF4ECDC4), _currentUser['canViewSubordinates'] as bool),
                      SizedBox(width: 8),
                      _buildFilterButton('this_year', '本年', Color(0xFF4ECDC4), _currentUser['canViewSubordinates'] as bool),
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


  Widget _buildFilterButton(String value, String label, Color color, bool canViewSubordinates) {
    // 【修正】让时间按钮也能正确高亮
    final isSelected = _selectedMode == value || _selectedTimeFilter == value;
    // 【修正】使用传入的 canViewSubordinates
    final isMemberButton = value == 'member' && canViewSubordinates;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isMemberButton) {
            _selectedMode = value;
          } else if (value == 'my') {
            _selectedMode = value;
            _selectedMembers.clear();
          } else {
            _selectedTimeFilter = value;
          }
          _logsFuture = _fetchLogs();
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

  // 【替换】整个 _showMemberSelectionDialog 方法
  void _showMemberSelectionDialog() {
    Set<String> tempSelectedMembers = Set.from(_selectedMembers);
    String tempSearchTerm = '';
    String? selectedDepartment; // 部门 ID
    String? selectedTeam; // 团队 ID

    // 用于驱动 FutureBuilders 的 Futures
    // (注意：这些 Future 需要在 StatefulBuilder 之外管理，
    // 但为了简化，我们暂时在 setDialogState 中重新触发它们)
    // 更好的做法是使用 .update() 方法

    // 我们需要一个方法来重新加载用户
    Future<Map<String, dynamic>> loadUsers(String? deptId, String? teamId, String keyword) {
      return ProfileService.fetchScopedUsers(
        departmentId: deptId,
        teamId: teamId,
        keyword: keyword,
      );
    }

    // 初始化 Futures
    Future<List<dynamic>> departmentsFuture = ProfileService.fetchDepartments();
    Future<List<dynamic>> teamsFuture = ProfileService.fetchTeams(departmentId: null);
    Future<Map<String, dynamic>> usersFuture = loadUsers(null, null, '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {

            return AlertDialog(
              title: Text('选择成员'),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
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
                          usersFuture = loadUsers(selectedDepartment, selectedTeam, tempSearchTerm);
                        });
                      },
                    ),
                    SizedBox(height: 12),

                    // 【修改】部门下拉菜单 (使用 FutureBuilder)
                    FutureBuilder<List<dynamic>>(
                        future: departmentsFuture,
                        builder: (context, snapshot) {
                          // --- 【⬇️ 修复：添加错误和加载中处理 ⬇️】 ---
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text('加载部门中...');
                          }
                          if (snapshot.hasError) {
                            return Text('加载部门失败: ${snapshot.error}');
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Text('未找到部门数据');
                          }
                          // --- 【⬆️ 修复结束 ⬆️】 ---

                          final departments = snapshot.data!;

                          return DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: '部门',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10),
                            ),
                            value: selectedDepartment,

                            items: departments.map((dept) {
                              return DropdownMenuItem(
                                value: dept['deptId'].toString(),
                                child: Text(dept['name'] ?? '未知部门'),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setDialogState(() {
                                selectedDepartment = newValue;
                                selectedTeam = null;
                                teamsFuture = ProfileService.fetchTeams(departmentId: selectedDepartment);
                                usersFuture = loadUsers(selectedDepartment, selectedTeam, tempSearchTerm);
                              });
                            },
                          );
                        }
                    ),
                    SizedBox(height: 12),

                    FutureBuilder<List<dynamic>>(
                        future: teamsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text('加载团队中...');
                          }
                          final teams = snapshot.data ?? [];

                          return DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: '团队',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10),
                            ),
                            value: selectedTeam,
                            items: teams.map((team) {
                              return DropdownMenuItem(
                                value: team['team_id'].toString(), // 存 ID
                                child: Text(team['name']), // 显示 Name
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setDialogState(() {
                                selectedTeam = newValue;
                                // 重新加载用户
                                usersFuture = loadUsers(selectedDepartment, selectedTeam, tempSearchTerm);
                              });
                            },
                          );
                        }
                    ),
                    SizedBox(height: 12),

                    // 【修改】成员列表 (使用 FutureBuilder)
                    Expanded(
                      child: FutureBuilder<Map<String, dynamic>>(
                          future: usersFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('加载用户失败'));
                            }
                            if (!snapshot.hasData || (snapshot.data?['list'] as List).isEmpty) {
                              return Center(child: Text('未找到成员'));
                            }

                            final users = snapshot.data!['list'] as List<dynamic>;

                            return ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (BuildContext context, int index) {
                                // API (GET /api/user/scoped) 返回 { user_id: ..., name: ... }
                                final member = users[index];
                                final memberId = member['user_id'].toString();
                                final memberName = member['name'];

                                final isSelected = tempSelectedMembers.contains(memberId);

                                return CheckboxListTile(
                                  title: Text(memberName),
                                  value: isSelected,
                                  onChanged: (bool? newValue) {
                                    setDialogState(() {
                                      if (newValue == true) {
                                        tempSelectedMembers.add(memberId);
                                      } else {
                                        tempSelectedMembers.remove(memberId);
                                      }
                                    });
                                  },
                                );
                              },
                            );
                          }
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
                      // 【新增】确定后重新加载日志
                      _logsFuture = _fetchLogs();
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
      // 使用 FutureBuilder 监听 _logsFuture
      return FutureBuilder<LogListResponse>(
        future: _logsFuture,
        builder: (context, snapshot) {

          // 1. 加载中
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // 2. 加载失败
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('加载日志失败: ${snapshot.error}',
                    style: TextStyle(color: Colors.red)),
              ),
            );
          }

          // 3. 成功，但列表为空
          if (!snapshot.hasData || snapshot.data!.logs.isEmpty) {
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

          // 4. 成功，渲染列表
          final logs = snapshot.data!.logs;
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return _buildLogCard(logs[index]);
            },
          );
        },
      );
    }

    // 【替换】整个 _buildLogCard 方法
    Widget _buildLogCard(Log log) {
      // 【修改】从缓存中获取作者信息
      // (我们稍后会实现 _userCache 的填充, 现在先用占位符)
      final authorName = _userCache[log.userId]?.name ?? '用户 ${log.userId}';
      final authorAvatar = _userCache[log.userId]?.username?.substring(0, 1) ?? '👤'; // 假设用首字母

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
            mainAxisSize: MainAxisSize.min, // 【修正】限制卡片内容高度
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 【修改】使用占位头像
                  Text(authorAvatar, style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // 【修正】限制内部 Column 高度
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // 【修改】使用 todaySummary 或 title (如果存在)
                          log.todaySummary ?? '日志 (ID: ${log.logId})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          authorName, // 【修改】使用缓存的作者名
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
                      color: _getStatusColor(log.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.status ?? '未知',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    _formatDate(log.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // 【修改】显示 Today Summary
              if (log.todaySummary != null && log.todaySummary!.isNotEmpty)
                Text(
                  log.todaySummary!,
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
                      // 【修改】显示数据库返回的 Tags
                      children: log.tags
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

  Color _getStatusColor(String? status) {
    switch (status) {
      case '已通过':
        return Color(0xFF4ECDC4);
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
      default:
        return '暂无相关日志';
    }
  }

  void _showLogDetail(Log log) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogDetailView(logId: log.logId),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}