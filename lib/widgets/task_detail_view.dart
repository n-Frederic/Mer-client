import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pandora_app/widgets/reject_reason_dialog.dart';
import 'package:pandora_app/widgets/task_report_detail_view.dart';
import '../models/task.dart';
import '../models/task_report.dart';
import '../models/role.dart';
import '../models/task_user.dart';
import '../models/log.dart';
import 'subtask_detail_view.dart';
import 'log_view_detail.dart';
import 'task_report_view.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/task_report_service.dart';

class TaskDetailView extends StatefulWidget {
  final String taskId;
  final Function(Task)? onTaskUpdated;

  const TaskDetailView({
    Key? key,
    required this.taskId,
    this.onTaskUpdated,
  }) : super(key: key);

  @override
  _TaskDetailViewState createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  late Future<Map<String, dynamic>> _dataFuture;
  Map<String, List<TaskReport>> _userReports = {};
  List<TaskUser> _taskAssignees = [];
  TaskUser? _taskAssigner;
  bool _isLoadingReports = false;
  bool _isLoadingAssignment = false;
  bool _isLoadingStatistics = false; //
  Task? _currentTask;
  String _currentUserId = '';
  Map<String, dynamic>? _reportStatistics;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    try {
      final userId = await AuthService.getSavedUserId();
      if (mounted) {
        setState(() {
          _currentUserId = userId?.toString() ?? '';
        });
      }
    } catch (e) {
      print('获取当前用户ID失败: $e');
    }
  }

  Future<void> _initializeData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingReports = true;
          _isLoadingAssignment = true;
          _isLoadingStatistics = true;
        });
      }

      await _checkStatusConsistency();

      _dataFuture = _loadData();
      await Future.wait([
        _loadTaskReports(),
        _loadTaskAssignmentInfo(),
        _loadReportStatistics(),
      ]);
    } catch (e) {
      print('初始化数据失败: $e');
    }
  }

  // 新增：检查状态一致性（自动修复卡住的任务状态）
  Future<void> _checkStatusConsistency() async {
    // 1. 确保数据已加载且任务存在
    if (_currentTask == null || _reportStatistics == null) return;

    // 2. 获取统计数据
    final int total = _safeToInt(_reportStatistics!['total_assignees']);
    final int approved = _safeToInt(_reportStatistics!['approved_reports']);

    print('🔍 [状态自检] 总人数: $total, 已通过: $approved, 当前任务状态: ${_currentTask!.status}');

    // 3. 核心判断：如果所有人已通过，但任务状态不是 Completed 或 Closed
    bool isTaskIncomplete = _currentTask!.status != TaskStatus.completed &&
        _currentTask!.status != TaskStatus.closed;

    if (total > 0 && total == approved && isTaskIncomplete) {
      print('⚠️ [状态自检] 检测到状态不一致！所有报告已通过，但任务未完成。正在自动修复...');

      try {
        // 调用服务更新状态
        final success = await TaskService.updateTaskStatus(
            widget.taskId,
            TaskStatus.completed
        );

        if (success) {
          print('✅ [状态自检] 自动修复成功，任务已标记为完成');

          // 重新加载任务详情以更新UI（进度条等）
          final updatedTask = await TaskService.fetchTaskById(widget.taskId);

          if (mounted) {
            setState(() {
              _currentTask = updatedTask;
              // 如果需要，可以更新 _dataFuture 的缓存，或者直接 setState 触发重绘
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.auto_fix_high, color: Colors.white),
                    SizedBox(width: 8),
                    Text('检测到所有报告已通过，任务状态已自动更新为完成'),
                  ],
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        print('❌ [状态自检] 自动修复失败: $e');
      }
    } else {
      print('✅ [状态自检] 状态正常，无需修复');
    }
  }

  Future<Map<String, dynamic>> _loadData() async {
    print('🚀 开始加载任务数据，任务ID: ${widget.taskId}');
    try {
      final task = await TaskService.fetchTaskById(widget.taskId);
      _currentTask = task;
      print('✅ 任务数据加载成功: ${task.title}');

      final currentUserId = (await AuthService.getSavedUserId())?.toString() ?? '';
      print('👤 当前用户ID: $currentUserId');

      final profile = await ProfileService.getUserProfile();
      final role = _extractUserRole(profile);
      print('🎭 用户角色: ${role.name} (ID: ${role.roleId})');

      return {
        'task': task,
        'currentUserId': currentUserId,
        'role': role,
      };
    } catch (e) {
      print('❌ 加载任务数据失败: $e');
      rethrow;
    }
  }

  Future<void> _loadTaskAssignmentInfo() async {
    if (mounted) {
      setState(() {
        _isLoadingAssignment = true;
      });
    }

    try {
      final assignmentInfo = await TaskService.fetchTaskAssignmentInfo(widget.taskId);

      if (mounted) {
        setState(() {
          _taskAssignees = assignmentInfo['assignees'] ?? [];
          _taskAssigner = assignmentInfo['assigner'];
          _isLoadingAssignment = false;
        });
      }
    } catch (e) {
      print('加载任务分配信息失败: $e');
      if (mounted) {
        setState(() {
          _taskAssignees = [];
          _taskAssigner = null;
          _isLoadingAssignment = false;
        });
      }
    }
  }

  Future<void> _loadTaskReports() async {
    print('🔄 [_loadTaskReports] 开始加载任务报告');

    if (mounted) {
      setState(() {
        _isLoadingReports = true;
      });
    }

    try {
      final userReports = await TaskReportService.fetchTaskReportsByUser(widget.taskId);
      print('✅ [_loadTaskReports] 报告加载成功');
      print('   📊 报告数据: ${userReports.keys.toList()}');

      // 打印每个用户的报告状态
      userReports.forEach((userId, reports) {
        print('   👤 用户 $userId 的报告数量: ${reports.length}');
        if (reports.isNotEmpty) {
          final latestReport = reports.last;
          print('     最新报告ID: ${latestReport.id}');
          print('     报告状态: ${latestReport.status}');
          print('     报告内容: ${latestReport.content}');
          print('     创建时间: ${latestReport.createdAt}');
          if (latestReport.approvedAt != null) {
            print('     审批时间: ${latestReport.approvedAt}');
          }
          if (latestReport.rejectedAt != null) {
            print('     拒绝时间: ${latestReport.rejectedAt}');
          }
        }
      });

      if (mounted) {
        setState(() {
          _userReports = userReports;
          _isLoadingReports = false;
        });
      }
    } catch (e) {
      print('❌ [_loadTaskReports] 加载任务报告失败: $e');
      if (mounted) {
        setState(() {
          _userReports = {};
          _isLoadingReports = false;
        });
      }
    }
  }

  // 加载报告统计信息
  Future<void> _loadReportStatistics() async {
    print('📊 开始加载报告统计信息，任务ID: ${widget.taskId}');

    if (mounted) {
      setState(() {
        _isLoadingStatistics = true;
      });
    }

    try {
      final statistics = await TaskReportService.fetchReportStatistics(widget.taskId);
      print('✅ 报告统计信息加载成功: $statistics');

      if (mounted) {
        setState(() {
          _reportStatistics = statistics;
          _isLoadingStatistics = false;
        });
      }
    } catch (e) {
      print('❌ 加载报告统计信息失败: $e');
      if (mounted) {
        setState(() {
          _reportStatistics = null;
          _isLoadingStatistics = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _dataFuture = _loadData();
      _isLoadingReports = true;
      _isLoadingAssignment = true;
      _isLoadingStatistics = true;
    });
    await Future.wait([
      _loadTaskReports(),
      _loadTaskAssignmentInfo(),
      _loadReportStatistics(),
    ]);
    if (mounted) {
      setState(() {});
    }
  }

  Role _extractUserRole(Map<String, dynamic> profile) {
    final user = profile['user'] as Map<String, dynamic>? ?? {};
    final roleId = int.tryParse(user['role_id']?.toString() ?? '') ?? 0;
    final roleName = user['role_name']?.toString() ?? '未知角色';
    final roleDesc = user['role_desc']?.toString();
    return Role(roleId: roleId, name: roleName, description: roleDesc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('加载任务详情失败: ${snapshot.error}',
                    style: TextStyle(color: Colors.red)),
              ),
            );
          }

          if (snapshot.hasData) {
            final Task loadedTask = snapshot.data!['task'] as Task;
            final String currentUserId = snapshot.data!['currentUserId'] as String;
            final Role currentUserRole = snapshot.data!['role'] as Role;

            final progress = _calculateTaskProgress(loadedTask);

            return RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTaskInfo(loadedTask, progress),
                    SizedBox(height: 20),
                    _buildTaskDetailsList(loadedTask),
                    SizedBox(height: 20),
                    _buildSubtasks(loadedTask, currentUserRole),
                    SizedBox(height: 20),
                    _buildCollaborators(),
                    SizedBox(height: 20),
                    _buildTaskLogsList(loadedTask.relatedLogs),
                    SizedBox(height: 20),
                    _buildReportSection(loadedTask, currentUserRole, currentUserId),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }

          return Center(child: Text('未知状态'));
        },
      ),
    );
  }

// 报告部分显示逻辑
  Widget _buildReportSection(Task task, Role currentUserRole, String currentUserId) {
    print('🎪 _buildReportSection 被调用');
    print('   任务状态: ${task.status}');
    print('   当前用户角色: ${currentUserRole.name}');
    print('   当前用户ID: $currentUserId');
    print('   统计信息加载状态: ${_isLoadingStatistics ? "加载中" : "完成"}');
    print('   接口统计信息: $_reportStatistics');

    // 调试：显示每个用户的报告状态
    print('👥 用户报告状态详情:');
    _userReports.forEach((userId, reports) {
      final user = _getUserById(userId);
      final latestReport = reports.isNotEmpty ? reports.last : null;
      final status = latestReport?.status ?? ReportStatus.pending;
      print('   ${user.name} (${user.userId}): $status');
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReportProgress(),
        SizedBox(height: 16),
        _buildReportInfo(),
        SizedBox(height: 16),

        // 提交报告按钮
        if (_canSubmitReport(currentUserRole, task, currentUserId))
          _buildSubmitReportButton(task),

        // 审批按钮区域 - 只有审核者且任务状态为reported时可以审批
        if (_canApproveReport(task, currentUserRole, currentUserId) && task.status == TaskStatus.reported)
          _buildApproveRejectButtons(task),

        // 任务完成提示
        if (task.status == TaskStatus.completed)
          _buildCompletionMessage(),
      ],
    );
  }
  // 计算任务进度
  double _calculateTaskProgress(Task task) {
    print('🎯 计算任务进度，任务状态: ${task.status}');

    double progress;

    switch (task.status) {
      case TaskStatus.published:
        progress = 0.33;
        print('📝 任务已发布，进度: 33%');
        break;
      case TaskStatus.reported:
        progress = 0.66;
        print('📤 报告已提交，进度: 66%');
        break;
      case TaskStatus.completed:
        progress = 1.0;
        print('✅ 任务已完成，进度: 100%');
        break;
      case TaskStatus.closed:
        progress = 1.0;
        print('🔒 任务已关闭，进度: 100%');
        break;
      default:
        progress = 0.0;
        print('❓ 未知任务状态，进度: 0%');
    }

    print('🎯 最终任务进度: ${(progress * 100).toInt()}%');
    return progress;
  }

  // 报告进度显示
  Widget _buildReportProgress() {
    final totalAssignees = _taskAssignees.length;
    print('📊 _buildReportProgress 被调用: 总指派人数 = $totalAssignees');

    if (totalAssignees == 0) {
      print('⚠️ 没有指派人员，跳过进度显示');
      return SizedBox();
    }

    // 获取统计信息
    final reportStats = _getReportStatistics();
    print('📈 使用的统计信息: $reportStats');

    // 计算各种状态的人数
    final approvedCount = reportStats['approved'] ?? 0;
    final submittedCount = reportStats['submitted'] ?? 0;
    final rejectedCount = reportStats['rejected'] ?? 0;

    // 报告完成进度 = 已通过人数 / 总人数
    final reportProgressValue = totalAssignees > 0 ? approvedCount / totalAssignees : 0.0;
    final reportProgressPercent = totalAssignees > 0 ? (approvedCount / totalAssignees * 100).toStringAsFixed(1) : '0.0';

    print('📐 报告进度计算: $approvedCount/$totalAssignees = $reportProgressPercent%');
    print('📊 状态分布: 已通过=$approvedCount, 待审核=$submittedCount, 已拒绝=$rejectedCount');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('报告审核进度', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                if (_isLoadingStatistics)
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            SizedBox(height: 12),

            // 报告审核进度条
            LinearProgressIndicator(
              value: reportProgressValue,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('审核进度: $approvedCount/$totalAssignees'),
                Text('$reportProgressPercent%'),
              ],
            ),
            SizedBox(height: 12),

            // 显示各种状态的人数
            _buildProgressDetailRow('✅ 已通过', approvedCount, Colors.green),
            _buildProgressDetailRow('⏳ 待审核', submittedCount, Colors.orange),
            _buildProgressDetailRow('❌ 已拒绝', rejectedCount, Colors.red),
          ],
        ),
      ),
    );
  }

  // 获取统计信息（简化版，完全依赖接口）
  Map<String, int> _getReportStatistics() {
    print('🔍 获取统计信息...');

    if (_reportStatistics != null && _reportStatistics!.isNotEmpty) {
      print('✅ 使用接口统计信息');
      print('   接口原始数据: $_reportStatistics');

      final stats = _reportStatistics!;

      // 直接从接口获取已通过和已拒绝的数量
      final approved = _safeToInt(stats['approved_reports']);
      final rejected = _safeToInt(stats['rejected_reports']);
      final totalAssignees = _safeToInt(stats['total_assignees']);

      // 待审核数量 = 总人数 - 已通过 - 已拒绝
      final submitted = totalAssignees - approved - rejected;

      final result = {
        'approved': approved,
        'submitted': submitted,
        'rejected': rejected,
      };

      print('   映射后的统计信息: $result');
      print('   计算逻辑: $totalAssignees - $approved - $rejected = $submitted');
      return result;
    } else {
      print('❌ 接口数据不可用，返回空统计');
      return {'approved': 0, 'submitted': 0, 'rejected': 0};
    }
  }

  // 安全转换为int类型
  int _safeToInt(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is double) {
      return value.toInt();
    } else if (value is String) {
      return int.tryParse(value) ?? 0;
    } else {
      return 0;
    }
  }

  // 计算报告统计信息 - 修复返回类型
  Map<String, int> _calculateReportStatistics() {
    int approvedCount = 0;
    int submittedCount = 0;
    int rejectedCount = 0;
    int pendingCount = 0;

    print('🔍 开始计算报告统计信息...');
    print('   总指派人数: ${_taskAssignees.length}');
    print('   用户报告数据: ${_userReports.keys.toList()}');

    _taskAssignees.forEach((user) {
      final userReports = _userReports[user.userId] ?? [];
      if (userReports.isEmpty) {
        pendingCount++;
      } else {
        final latestReport = userReports.last;
        switch (latestReport.status) {
          case ReportStatus.approved:
            approvedCount++;
            break;
          case ReportStatus.submitted:
            submittedCount++;
            break;
          case ReportStatus.rejected:
            rejectedCount++;
            break;
          case ReportStatus.pending:
            pendingCount++;
            break;
        }
      }
    });

    return {
      'approved': approvedCount,
      'submitted': submittedCount,
      'rejected': rejectedCount,
      'pending': pendingCount,
    };
  }

  // 进度详情行
  Widget _buildProgressDetailRow(String label, int count, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14))),
          Text('$count 人', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  bool _canSubmitReport(Role role, Task task, String currentUserId) {
    // 检查是否是任务的被指派者
    final isAssignee = _taskAssignees.any((assignee) => assignee.userId == _currentUserId);
    if (!isAssignee) return false;

    // 检查任务状态是否允许提交报告
    if (task.status == TaskStatus.completed || task.status == TaskStatus.closed) {
      return false;
    }

    // 检查用户当前报告状态
    final userReports = _userReports[_currentUserId] ?? [];
    if (userReports.isNotEmpty) {
      final latestReport = userReports.last;
      // 只有报告被拒绝或没有报告时可以重新提交
      return latestReport.status == ReportStatus.rejected;
    }

    // 没有报告记录，可以提交
    return true;
  }

  bool _canApproveReport(Task task, Role currentUserRole, String currentUserId) {
    final isCreator = task.creator?.userId == currentUserId;
    final isAdmin = currentUserRole.roleId == 5;
    final isAssigner = _taskAssigner?.userId == currentUserId;

    return isCreator || isAdmin || isAssigner;
  }

  Widget _buildSubmitReportButton(Task task) {
    final currentUserReports = _userReports[_currentUserId] ?? [];
    final hasRejectedReport = currentUserReports.isNotEmpty &&
        currentUserReports.last.status == ReportStatus.rejected;

    return Center(
      child: ElevatedButton(
        onPressed: () => _handleReport(task),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFF8C42),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(hasRejectedReport ? Icons.refresh : Icons.assignment_turned_in, size: 20),
            SizedBox(width: 8),
            Text(hasRejectedReport ? '重新提交报告' : '提交工作报告', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // 完成提示
  Widget _buildCompletionMessage() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '所有报告已通过审核，任务已完成',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

// 审批按钮区域
  Widget _buildApproveRejectButtons(Task task) {
    final pendingReports = _getPendingReports();
    final canApproveAll = pendingReports > 0;

    return Column(
      children: [
        // 查看所有报告按钮
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            onPressed: _showAllReportsDialog,
            icon: Icon(Icons.list_alt, size: 20),
            label: Text('查看所有报告', style: TextStyle(fontSize: 16)),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: Colors.blue),
            ),
          ),
        ),

        // 批量审批按钮
        if (canApproveAll)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              onPressed: () => _handleApproveAllReports(task),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              icon: Icon(Icons.check_circle_outline, size: 20),
              label: Text('一键通过所有待审核报告 ($pendingReports)'),
            ),
          ),

        // 单个用户报告审批区域 - 只显示待审核的报告
        ..._buildUserReportApprovalCards(),
      ],
    );
  }

// 构建每个用户的报告审批卡片（只显示待审核的报告）
  List<Widget> _buildUserReportApprovalCards() {
    List<Widget> cards = [];

    print('🃏 [_buildUserReportApprovalCards] 开始构建审批卡片');
    print('   📊 当前用户报告数量: ${_userReports.length}');

    _userReports.forEach((userId, reports) {
      final user = _getUserById(userId);
      final latestReport = reports.isNotEmpty ? reports.last : null;

      if (latestReport != null) {
        print('   👤 检查用户 ${user.name} ($userId) 的报告状态: ${latestReport.status}');

        // 只显示待审核状态的报告
        if (latestReport.status == ReportStatus.submitted) {
          print('   ✅ 用户 ${user.name} 的报告需要审批，添加到卡片');
          cards.add(_buildUserReportCard(user, latestReport));
          cards.add(SizedBox(height: 12));
        } else {
          print('   ⏭️ 用户 ${user.name} 的报告状态为 ${latestReport.status}，跳过审批');
        }
      } else {
        print('   📭 用户 ${user.name} 没有报告');
      }
    });

    print('🃏 [_buildUserReportApprovalCards] 生成的审批卡片数量: ${cards.length}');

    // 如果没有待审核的报告，显示提示信息
    if (cards.isEmpty && _taskAssignees.isNotEmpty) {
      print('📭 没有待审核的报告，显示提示信息');
      cards.add(
        Card(
          color: Colors.grey[50],
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('暂无待审核的报告', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return cards;
  }

  TaskUser _getUserById(String userId) {
    return _taskAssignees.firstWhere(
          (assignee) => assignee.userId == userId,
      orElse: () => TaskUser(userId: userId, name: '未知用户'),
    );
  }

  Widget _buildUserReportCard(TaskUser user, TaskReport report) {
    // 根据报告状态决定显示内容
    final bool showApprovalButtons = report.status == ReportStatus.submitted;
    final bool showRejectedInfo = report.status == ReportStatus.rejected;
    final bool showApprovedInfo = report.status == ReportStatus.approved;

    Color statusColor = Colors.grey;
    String statusText = '未知';
    IconData statusIcon = Icons.help_outline;

    switch (report.status) {
      case ReportStatus.pending:
        statusColor = Colors.orange;
        statusText = '待提交';
        statusIcon = Icons.pending;
        break;
      case ReportStatus.submitted:
        statusColor = Colors.blue;
        statusText = '待审核';
        statusIcon = Icons.schedule;
        break;
      case ReportStatus.approved:
        statusColor = Colors.green;
        statusText = '已通过';
        statusIcon = Icons.check_circle;
        break;
      case ReportStatus.rejected:
        statusColor = Colors.red;
        statusText = '已拒绝';
        statusIcon = Icons.cancel;
        break;
    }

    print('🎴 [_buildUserReportCard] 构建报告卡片');
    print('   👤 用户: ${user.name}');
    print('   📊 报告状态: ${report.status}');
    print('   🔘 显示审批按钮: $showApprovalButtons');
    print('   ✅ 显示已通过信息: $showApprovedInfo');
    print('   ❌ 显示已拒绝信息: $showRejectedInfo');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(statusIcon, size: 20, color: statusColor),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('提交时间: ${_formatReportTime(report.createdAt)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      // 显示审批时间（如果已审批）
                      if (showApprovedInfo && report.approvedAt != null)
                        Text('通过时间: ${_formatReportTime(report.approvedAt!)}',
                            style: TextStyle(fontSize: 10, color: Colors.green)),
                      if (showRejectedInfo && report.rejectedAt != null)
                        Text('拒绝时间: ${_formatReportTime(report.rejectedAt!)}',
                            style: TextStyle(fontSize: 10, color: Colors.red)),
                    ],
                  ),
                ),
                Chip(
                  label: Text(statusText, style: TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            SizedBox(height: 12),

            // 报告内容
            if (report.content.isNotEmpty)
              Text(
                report.content.length > 100 ? '${report.content.substring(0, 100)}...' : report.content,
                style: TextStyle(fontSize: 14),
              ),

            // 拒绝原因（如果被拒绝）
            if (showRejectedInfo && report.rejectReason != null)
              Container(
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, size: 14, color: Colors.red),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '拒绝原因: ${report.rejectReason!}',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // 审批人信息（如果已审批）
            if (showApprovedInfo)
              Container(
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, size: 14, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      '已通过审核',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 12),

            // 操作按钮区域 - 只有待审核状态显示审批按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    print('🔍 查看报告详情: ${report.id}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskReportDetailView(
                          report: report,
                          taskId: widget.taskId,
                        ),
                      ),
                    );
                  },
                  child: Text('查看详情'),
                ),
                if (showApprovalButtons) ...[
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      print('✅ 审批通过报告: ${report.id}, 用户: ${user.userId}');
                      _handleApproveUserReport(widget.taskId, user.userId);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text('通过'),
                  ),
                  SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      print('❌ 拒绝报告: ${report.id}, 用户: ${user.userId}');
                      _handleRejectUserReport(widget.taskId, user.userId);
                    },
                    style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red)),
                    child: Text('拒绝', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '工作报告',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            SizedBox(width: 8),
            if (_isLoadingReports)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        SizedBox(height: 12),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: _isLoadingReports
                ? Center(child: CircularProgressIndicator())
                : _userReports.isEmpty
                ? Column(
              children: [
                Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[400]),
                SizedBox(height: 8),
                Text('暂无工作报告', style: TextStyle(color: Color(0xFF666666))),
              ],
            )
                : Column(
              children: _buildAllReportItems(),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAllReportItems() {
    List<Widget> items = [];

    _userReports.forEach((userId, reports) {
      final user = _getUserById(userId);

      // 只显示最新的报告
      if (reports.isNotEmpty) {
        final latestReport = reports.last;
        items.add(_buildReportItem(latestReport, user));
        items.add(SizedBox(height: 12));
      }
    });

    return items;
  }

  Widget _buildReportItem(TaskReport report, TaskUser user) {
    Color statusColor = Colors.grey;
    String statusText = '未知';
    IconData statusIcon = Icons.help_outline;

    switch (report.status) {
      case ReportStatus.pending:
        statusColor = Colors.orange;
        statusText = '待提交';
        statusIcon = Icons.pending;
        break;
      case ReportStatus.submitted:
        statusColor = Colors.blue;
        statusText = '待审核';
        statusIcon = Icons.schedule;
        break;
      case ReportStatus.approved:
        statusColor = Colors.green;
        statusText = '已通过';
        statusIcon = Icons.check_circle;
        break;
      case ReportStatus.rejected:
        statusColor = Colors.red;
        statusText = '已拒绝';
        statusIcon = Icons.cancel;
        break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskReportDetailView(
              report: report,
              taskId: widget.taskId,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(statusIcon, size: 16, color: statusColor),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(_formatReportTime(report.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Chip(
                  label: Text(statusText, style: TextStyle(color: Colors.white, fontSize: 10)),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            SizedBox(height: 8),
            if (report.content.isNotEmpty)
              Text(
                report.content.length > 100 ? '${report.content.substring(0, 100)}...' : report.content,
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
            if (report.status == ReportStatus.rejected && report.rejectReason != null)
              Container(
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, size: 14, color: Colors.red),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text('拒绝原因: ${report.rejectReason!}',
                          style: TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 处理报告提交
  Future<void> _handleReport(Task loadedTask) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskReportView(
          task: loadedTask,
          onReportSubmitted: _refreshData,
        ),
      ),
    );

    if (result == true) {
      await _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('工作报告提交成功')),
      );
    }
  }

// 审批单个用户的报告
  Future<void> _handleApproveUserReport(String taskId, String reporterId) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('通过报告'),
          content: Text('确定要通过这个用户的报告吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('通过'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        if (mounted) {
          setState(() {
            _isLoadingReports = true;
          });
        }

        // 1. 执行审批
        await TaskReportService.approveUserReport(taskId, reporterId);

        // 2. 关键步骤：审批成功后，立即检查是否触发任务完成
        await _checkAndUpdateTaskStatus(taskId);

        // 3. 刷新页面数据（这一步会重新加载任务状态，UI会自动变为完成态）
        await _refreshData();
      }
    } catch (e) {
      print('❌ 审批报告失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReports = false;
        });
      }
    }
  }

  // 拒绝单个用户的报告
  Future<void> _handleRejectUserReport(String taskId, String reporterId) async {
    try {
      final reason = await showDialog<String>(
        context: context,
        builder: (context) => RejectReasonDialog(),
      );

      if (reason != null && reason.isNotEmpty) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('拒绝报告'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('确定要拒绝这个报告吗？'),
                SizedBox(height: 8),
                Text('拒绝原因: $reason', style: TextStyle(color: Colors.red)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('拒绝'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          setState(() {
            _isLoadingReports = true;
          });

          // 调用拒绝报告接口
          await TaskReportService.rejectUserReport(taskId, reporterId, reason);
          await _refreshData();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('报告已拒绝，用户需要重新提交'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ 拒绝报告失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('操作失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReports = false;
        });
      }
    }
  }

// 一键通过所有待审核报告
  Future<void> _handleApproveAllReports(Task task) async {
    try {
      final pendingCount = _getPendingReports();
      if (pendingCount == 0) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('一键通过所有报告'),
          content: Text('确定要通过所有 $pendingCount 个待审核报告吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('全部通过'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        if (mounted) {
          setState(() {
            _isLoadingReports = true;
          });
        }

        // 1. 调用批量审批接口
        await TaskReportService.batchApproveReports(task.taskId);
        print('✅ 批量审批请求成功');

        // 2. 检查是否应该关闭任务
        // 虽然我们假设一键通过后就完成了，但为了保险（可能还有人没提交），
        // 我们还是调用 _checkAndUpdateTaskStatus 来决定是否改为 Completed
        await _checkAndUpdateTaskStatus(task.taskId);

        // 3. 刷新数据
        await _refreshData();
      }
    } catch (e) {
      print('❌ 一键审批失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReports = false;
        });
      }
    }
  }

// 统一的检查并更新任务状态方法
  Future<void> _checkAndUpdateTaskStatus(String taskId) async {
    try {
      print('🔍 开始检查是否所有报告都已通过...');

      // 1. 调用接口检查是否所有被指派人的报告都变成了 approved 状态
      final allApproved = await TaskReportService.checkAllReportsApproved(taskId);
      print('🔍 检查结果 (allApproved): $allApproved');

      if (allApproved) {
        print('🎉 所有报告已通过，正在将任务状态更新为 [已完成]...');

        // 2. 如果全部通过，调用更新状态接口
        // 注意：根据你提供的Service代码，updateTaskStatus 在 TaskReportService 中
        final success = await TaskService.updateTaskStatus(taskId, TaskStatus.completed);

        if (success) {
          print('✅ 任务状态已成功更新为 Completed');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('所有报告审核通过，任务已自动完成！'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          print('❌ 任务状态更新失败');
          throw Exception('任务状态更新接口返回 false');
        }
      } else {
        print('⏳ 还有未完成或待审核的报告，任务状态保持不变');
      }
    } catch (e) {
      print('❌ 检查并更新任务状态失败: $e');
      // 这里不抛出异常，以免中断主流程，但记录错误
    }
  }
  // 显示所有报告对话框
  void _showAllReportsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('所有工作报告'),
        content: Container(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: _buildAllReportItemsForDialog(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAllReportItemsForDialog() {
    List<Widget> items = [];

    _taskAssignees.forEach((user) {
      final userReports = _userReports[user.userId] ?? [];
      final hasReport = userReports.isNotEmpty;
      final latestReport = hasReport ? userReports.last : null;

      // 确定用户状态
      String statusText = '未提交';
      Color statusColor = Colors.grey;
      IconData statusIcon = Icons.pending;

      if (hasReport) {
        switch (latestReport!.status) {
          case ReportStatus.approved:
            statusText = '已通过';
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            break;
          case ReportStatus.submitted:
            statusText = '待审核';
            statusColor = Colors.orange;
            statusIcon = Icons.schedule;
            break;
          case ReportStatus.rejected:
            statusText = '已拒绝';
            statusColor = Colors.red;
            statusIcon = Icons.cancel;
            break;
          case ReportStatus.pending:
            statusText = '待提交';
            statusColor = Colors.blue;
            statusIcon = Icons.drafts;
            break;
        }
      }

      items.add(ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, size: 20, color: statusColor),
        ),
        title: Text(user.name),
        subtitle: Text(hasReport ?
        '${_formatReportTime(latestReport!.createdAt)}' :
        '尚未提交报告'),
        trailing: Chip(
          label: Text(
            statusText,
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
          backgroundColor: statusColor,
        ),
        onTap: hasReport ? () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskReportDetailView(
                report: latestReport!,
                taskId: widget.taskId,
              ),
            ),
          );
        } : null,
      ));

      items.add(Divider(height: 1));
    });

    return items;
  }

  // 获取待审核报告数量
  int _getPendingReports() {
    int count = 0;

    // 如果有接口统计信息，使用接口数据
    if (_reportStatistics != null && _reportStatistics!.isNotEmpty) {
      final stats = _getReportStatistics();
      count = stats['submitted'] ?? 0;
      print('📋 从接口获取待审核报告数量: $count');
    } else {
      // 否则使用本地计算
      _userReports.forEach((userId, reports) {
        if (reports.isNotEmpty && reports.last.status == ReportStatus.submitted) {
          count++;
        }
      });
      print('📋 从本地计算待审核报告数量: $count');
    }

    return count;
  }

  // 检查是否还有待审核的报告
  bool _hasPendingReports() {
    return _getPendingReports() > 0;
  }

  double _calculateProgress(Task task, Map<String, List<TaskReport>> userReports, List<TaskUser> assignees) {
    if (assignees.isEmpty) return 0.0;

    final approvedCount = userReports.values.where((reports) {
      return reports.any((report) => report.status == ReportStatus.approved);
    }).length;

    return approvedCount / assignees.length;
  }

  String _formatReportTime(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // 其他UI组件保持不变...
  Widget _buildTaskInfo(Task loadedTask, double progress) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFFF8C42), Color(0xFFFF6B9D)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text('📝', style: TextStyle(fontSize: 24))),
                ),
                SizedBox(width: 12),
                Expanded(child: Text(loadedTask.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
              ],
            ),
            SizedBox(height: 12),
            Text(loadedTask.description, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), height: 1.5)),
            SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(_getStatusText(loadedTask.status), style: TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: _getStatusColor(loadedTask.status),
                ),
                SizedBox(width: 8),
                Expanded(child: Text('当前状态: ${_getStatusDescription(loadedTask.status)}', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)))),
              ],
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 8),
            Text('进度: ${(progress * 100).toInt()}%', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }

  Widget _buildCollaborators() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('任务分配', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            SizedBox(width: 8),
            if (_isLoadingAssignment)
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        SizedBox(height: 12),

        if (_isLoadingAssignment)
          Center(child: CircularProgressIndicator())
        else if (_taskAssigner == null && _taskAssignees.isEmpty)
          Text('暂无分配信息', style: TextStyle(color: Color(0xFF666666)))
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_taskAssigner != null) ...[
                _buildAssignmentSection('指派人', [_taskAssigner!]),
                SizedBox(height: 16),
              ],
              if (_taskAssignees.isNotEmpty)
                _buildAssignmentSection('被指派人', _taskAssignees),
            ],
          ),
      ],
    );
  }

  Widget _buildAssignmentSection(String title, List<TaskUser> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: users.map((user) => Chip(
            label: Text(
              user.name,
              style: TextStyle(fontSize: 12),
            ),
            avatar: CircleAvatar(
              backgroundColor: title == '指派人' ? Color(0xFFFF8C42) : Colors.blue[100],
              radius: 12,
              child: Text(
                user.name.isNotEmpty ? user.name[0] : '?',
                style: TextStyle(
                  fontSize: 10,
                  color: title == '指派人' ? Colors.white : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 2,
            side: BorderSide(
              color: title == '指派人' ? Color(0xFFFF8C42).withOpacity(0.3) : Colors.blue.withOpacity(0.3),
            ),
          )).toList(),
        ),
      ],
    );
  }

  // 其他UI组件（_buildTaskDetailsList, _buildSubtasks, _buildTaskLogsList）保持不变...
  Widget _buildTaskDetailsList(Task loadedTask) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('任务详情', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        SizedBox(height: 12),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              children: [
                _buildDetailRow(
                    icon: Icons.person_outline,
                    title: '创建者',
                    value: loadedTask.creator?.name ?? '未知',
                    iconColor: Color(0xFF4ECDC4)
                ),
                Divider(height: 1),
                _buildDetailRow(
                    icon: Icons.person_add,
                    title: '指派人',
                    value: _taskAssigner?.name ?? '未指定',
                    iconColor: Color(0xFFFF8C42)
                ),
                Divider(height: 1),
                _buildDetailRow(
                    icon: Icons.people_outline,
                    title: '被指派人',
                    value: _taskAssignees.isEmpty ? '无' : '${_taskAssignees.length}人',
                    iconColor: Colors.blue
                ),
                Divider(height: 1),
                _buildDetailRow(
                    icon: Icons.flag_outlined,
                    title: '优先级',
                    value: loadedTask.priority.sqlValue,
                    iconColor: Color(0xFFFF6B9D)
                ),
                Divider(height: 1),
                _buildDetailRow(
                    icon: Icons.play_arrow_outlined,
                    title: '开始时间',
                    value: _formatTaskDate(loadedTask.startAt),
                    iconColor: Color(0xFF88D8B0)
                ),
                Divider(height: 1),
                _buildDetailRow(
                    icon: Icons.timer_outlined,
                    title: '截止时间',
                    value: _formatTaskDate(loadedTask.dueAt),
                    iconColor: Color(0xFFFF8C42)
                ),
                Divider(height: 1),
                _buildDetailRow(
                    icon: Icons.add_circle_outline,
                    title: '创建时间',
                    value: _formatTaskDate(loadedTask.createdAt),
                    iconColor: Color(0xFF999999)
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({required IconData icon, required String title, required String value, required Color iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(title, style: TextStyle(fontSize: 15, color: Color(0xFF666666))),
      trailing: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF333333))),
      dense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
    );
  }

  String _formatTaskDate(DateTime? date) {
    if (date == null) return '未设置';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSubtasks(Task loadedTask, Role currentUserRole) {
    // 简化处理，实际应根据任务数据渲染子任务
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('子任务', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        SizedBox(height: 12),
        Text('暂无子任务', style: TextStyle(color: Color(0xFF666666))),
      ],
    );
  }

  Widget _buildTaskLogsList(List<TaskRelatedLog> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('相关日志', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        SizedBox(height: 12),
        if (logs.isEmpty)
          Text('当前任务还没有关联的日志', style: TextStyle(color: Color(0xFF666666)))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final relatedLog = logs[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(relatedLog.title.isNotEmpty ? relatedLog.title : '日志 ${relatedLog.logId}', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('ID: ${relatedLog.logId}', style: TextStyle(color: Color(0xFF666666))),
                trailing: Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LogDetailView(logId: relatedLog.logId)),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  // 状态相关方法
  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.published: return '已发布';
      case TaskStatus.reported: return '已提交';
      case TaskStatus.completed: return '已完成';
      case TaskStatus.closed: return '已关闭';
      default: return '未知';
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.published: return Color(0xFFFF8C42);
      case TaskStatus.reported: return Colors.purple;
      case TaskStatus.completed: return Color(0xFF88D8B0);
      case TaskStatus.closed: return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _getStatusDescription(TaskStatus status) {
    switch (status) {
      case TaskStatus.published: return '任务已发布，等待提交报告';
      case TaskStatus.reported: return '已提交报告，等待审核';
      case TaskStatus.completed: return '任务已完成';
      case TaskStatus.closed: return '任务已关闭';
      default: return '未知状态';
    }
  }
}