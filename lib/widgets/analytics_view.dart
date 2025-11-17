import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/analytics_service.dart';

class AnalyticsView extends StatefulWidget {
  @override
  _AnalyticsViewState createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> with TickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedTab = 'overview';
  late Future<List<dynamic>> _chartDataFuture;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();
    _chartDataFuture = AnalyticsService.fetchChartData();
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
          // 标签页 (保持不变)
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTabButton('overview', '概览', '📊'),
                _buildTabButton('keywords', '关键词', '🔍'),
                _buildTabButton('ai', 'MBTI', '🧠'),
                _buildTabButton('fortune', '运势', '🔮'),
              ],
            ),
          ),

          // 内容区域
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _buildCurrentTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label, String emoji) {
    bool isSelected = _selectedTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = tab;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.all(4),
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFFF8C42) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: TextStyle(fontSize: 16)),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Color(0xFF666666),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_selectedTab) {
      case 'overview':
        return KeyedSubtree(
          key: ValueKey('overview'),
          child: _buildOverviewTab(),
        );
      case 'keywords':
        return KeyedSubtree(
          key: ValueKey('keywords'),
          child: _buildKeywordsTab(),
        );
      case 'ai':
        return KeyedSubtree(
          key: ValueKey('ai'),
          child: _buildAITab(),
        );
      case 'fortune':
        return KeyedSubtree(
          key: ValueKey('fortune'),
          child: _buildFortuneTab(),
        );
      default:
        return KeyedSubtree(
          key: ValueKey('overview'),
          child: _buildOverviewTab(),
        );
    }
  }

  Widget _buildOverviewTab() {
    return FutureBuilder<List<dynamic>>(
      future: _chartDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('加载统计失败: ${snapshot.error}', style: TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('本周无任务数据'));
        }

        final chartData = snapshot.data!;

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildPieChart(chartData),
              SizedBox(height: 16),
              _buildHorizontalStats(chartData),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHorizontalStats(List<dynamic> chartData) {

    // (辅助函数 getCount 保持不变)
    int getCount(String statusKey) {
      final item = chartData.firstWhere(
            (d) => (d['status'] as String? ?? '').toLowerCase() == statusKey.toLowerCase(),
        orElse: () => {'count': 0},
      );
      if (statusKey == 'completed') {
        final itemCn = chartData.firstWhere(
              (d) => (d['status'] as String? ?? '') == '已完成',
          orElse: () => {'count': 0},
        );
        return (item['count'] as int? ?? 0) + (itemCn['count'] as int? ?? 0);
      }
      return (item['count'] as int? ?? 0);
    }

    int publishedCount = getCount("published");
    int reportedCount = getCount("reported");
    int completedCount = getCount("completed");

    return Container(
      margin: EdgeInsets.all(0), // (移除多余的外边距)
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
              '已发布',
              publishedCount.toString(),
              _getStatusColor("published")
          ),
          _buildStatItem(
              '已提交',
              reportedCount.toString(),
              _getStatusColor("reported")
          ),
          _buildStatItem(
              '已完成',
              completedCount.toString(),
              _getStatusColor("completed")
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count, Color color) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, String emoji, Color color) {
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
        children: [
          Text(emoji, style: TextStyle(fontSize: 32)),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildPieChart(List<dynamic> chartData) {
    double total = 0;
    chartData.forEach((item) {
      total += (item['count'] as int? ?? 0);
    });
    if (total == 0) {
      // (如果总数是0, 饼图不需要显示)
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(child: Text('本周无任务数据')),
      );
    }

    // 生成饼图切片
    final pieSections = chartData.map((item) {
      final double value = (item['count'] as int? ?? 0).toDouble();
      final String status = item['status'] as String? ?? '未知';
      final double percentage = (value / total) * 100;

      return PieChartSectionData(
        color: _getStatusColor(status),
        value: value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 80,
        titleStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2)],
        ),
      );
    }).toList();

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
        children: [
          Text(
            '本周任务状态',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 24),
          // 饼图
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: pieSections,
                centerSpaceRadius: 40,
                sectionsSpace: 4,
              ),
            ),
          ),
          SizedBox(height: 24)
        ],
      ),
    );
  }

  Widget _buildStatusCards(List<dynamic> chartData) {

    // 辅助函数：安全地从图表数据中获取计数值
    int getCount(String statusKey) {
      final item = chartData.firstWhere(
            (d) => (d['status'] as String? ?? '').toLowerCase() == statusKey.toLowerCase(),
        orElse: () => {'count': 0},
      );
      // (我们也检查 '已完成' 这个中文键, 以防万一)
      if (statusKey == 'completed') {
        final itemCn = chartData.firstWhere(
              (d) => (d['status'] as String? ?? '') == '已完成',
          orElse: () => {'count': 0},
        );
        return (item['count'] as int? ?? 0) + (itemCn['count'] as int? ?? 0);
      }
      return (item['count'] as int? ?? 0);
    }

    // 获取 3 种状态的计数值
    int publishedCount = getCount("published");
    int reportedCount = getCount("reported");
    int completedCount = getCount("completed"); // (已包含 "已完成")

    return Column(
      children: [
        _buildStatCard(
            '已发布',
            publishedCount.toString(),
            'Published',
            '📋',
            _getStatusColor("published")
        ),
        SizedBox(height: 12),
        _buildStatCard(
            '已提交',
            reportedCount.toString(),
            'Reported',
            '📝',
            _getStatusColor("reported")
        ),
        SizedBox(height: 12),
        _buildStatCard(
            '已完成',
            completedCount.toString(),
            'Completed',
            '✅',
            _getStatusColor("completed")
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    // (将你 API 返回的 status 字符串映射为颜色)
    switch (status.toLowerCase()) {
      case 'published':
        return Color(0xFFFF8C42); // 橙色
      case 'reported':
        return Colors.purple; // 紫色
      case 'completed':
        return Color(0xFF88D8B0); // 绿色
      default:
        return Colors.grey;
    }
  }
  Widget _buildKeywordsTab() {
    final keywords = [
      {'word': '项目', 'count': 25, 'trend': 'up'},
      {'word': '学习', 'count': 18, 'trend': 'up'},
      {'word': '团队', 'count': 15, 'trend': 'stable'},
      {'word': '客户', 'count': 12, 'trend': 'down'},
      {'word': '优化', 'count': 10, 'trend': 'up'},
      {'word': '反馈', 'count': 8, 'trend': 'stable'},
      {'word': '进展', 'count': 6, 'trend': 'up'},
      {'word': '协作', 'count': 5, 'trend': 'stable'},
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 关键词云
          Container(
            width: double.infinity,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔍 关键词分析',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 20),
                ...keywords.map((keyword) => _buildKeywordItem(keyword)).toList(),
              ],
            ),
          ),
          SizedBox(height: 20),

          // AI生成的工作清单
          Container(
            width: double.infinity,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 AI生成工作清单',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 20),
                _buildTaskItem('继续推进项目相关工作', 85),
                _buildTaskItem('安排团队学习分享会', 72),
                _buildTaskItem('跟进客户反馈处理', 68),
                _buildTaskItem('完成代码优化任务', 55),
                _buildTaskItem('准备下周工作计划', 45),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildKeywordItem(Map<String, dynamic> keyword) {
    Color trendColor = keyword['trend'] == 'up'
        ? Colors.green
        : keyword['trend'] == 'down'
        ? Colors.red
        : Colors.grey;
    IconData trendIcon = keyword['trend'] == 'up'
        ? Icons.trending_up
        : keyword['trend'] == 'down'
        ? Icons.trending_down
        : Icons.trending_flat;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              keyword['word'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ),
          Text(
            '${keyword['count']}次',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(width: 8),
          Icon(
            trendIcon,
            size: 16,
            color: trendColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String task, int importance) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFFF8C42), width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              task,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF333333),
              ),
            ),
          ),
          Text(
            '${importance}%',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFFF8C42),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAITab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // MBTI分析
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
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
                  '🧠 MBTI职场性格分析',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    _buildMBTITrait('I', '内向', true),
                    _buildMBTITrait('E', '外向', false),
                    _buildMBTITrait('N', '直觉', true),
                    _buildMBTITrait('S', '感觉', false),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    _buildMBTITrait('T', '思维', true),
                    _buildMBTITrait('F', '情感', false),
                    _buildMBTITrait('J', '判断', true),
                    _buildMBTITrait('P', '感知', false),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '推测类型：INTJ (建筑师)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '您展现出典型的INTJ特质：善于独立思考、注重长远规划、追求专业精进。在工作中表现出强烈的目标导向和系统性思维。',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // AI建议
          ...['工作风格分析', '性格特征洞察', '核心优势识别', '发展建议'].map((title) =>
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 16),
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
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      _getAIInsightContent(title),
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildMBTITrait(String trait, String name, bool active) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              trait,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFortuneTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 职场运势
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
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
                Text('🔮', style: TextStyle(fontSize: 40)),
                SizedBox(height: 16),
                Text(
                  '职场运势解析',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '基于日志关键词的智能分析',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    _buildFortuneItem('⭐', '事业运', '旺盛'),
                    _buildFortuneItem('🌟', '学习运', '上升'),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    _buildFortuneItem('💫', '人际运', '平稳'),
                    _buildFortuneItem('✨', '创新运', '待发'),
                  ],
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎯 本周运势指引',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '根据您的工作日志分析，本周您的事业运势呈上升趋势。"项目"和"学习"关键词频繁出现，表明您正处于快速成长期。建议把握机会，在技能提升方面加大投入，同时注意与团队成员的协作沟通。',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // 幸运建议
          Container(
            width: double.infinity,
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
                  '🍀 今日幸运建议',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 16),
                _buildLuckyItem('幸运颜色', '橙色 🧡', '穿橙色系服装有助提升工作运势'),
                _buildLuckyItem('幸运时间', '上午9-11点', '这个时段思维最活跃，适合处理重要事务'),
                _buildLuckyItem('幸运方位', '东南方', '在东南方向的位置工作效率更高'),
                _buildLuckyItem('幸运数字', '7', '今天与数字7相关的事物会带来好运'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFortuneItem(String emoji, String title, String status) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLuckyItem(String title, String value, String description) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8C42),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAIInsightContent(String title) {
    switch (title) {
      case '工作风格分析':
        return '您展现出强烈的项目导向思维，善于制定计划和推进执行。这表明您具有优秀的组织能力和目标导向性，属于典型的执行者类型。建议继续发挥这一优势，同时注意平衡细节与全局视野。';
      case '性格特征洞察':
        return '您是一个天生的乐观主义者，即使面对挑战也能保持积极的心态。这种正能量不仅有助于您自己的成长，也能感染周围的同事。您的情绪稳定性很高，适合承担更多的团队协调工作。';
      case '核心优势识别':
        return '您的优势在于综合能力的均衡发展。您不仅具备扎实的专业技能，还有良好的学习能力和适应性。这种全面发展的特质，为您的职业发展提供了更多可能性。';
      case '发展建议':
        return '时间管理优化：建议使用番茄工作法或时间块管理，提高工作效率；技能拓展：建议制定学习计划，定期更新专业技能；继续保持：您目前的工作状态很好，建议保持现有的工作节奏和方法。';
      default:
        return '基于您的工作模式分析，为您提供个性化的发展建议。';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
