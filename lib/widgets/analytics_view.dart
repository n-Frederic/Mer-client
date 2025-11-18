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
  late Future<Map<String, dynamic>> _summaryFuture;
  late Future<Map<String, dynamic>> _personalityFuture;
  late Future<Map<String, dynamic>> _fortuneFuture;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();
    _chartDataFuture = AnalyticsService.fetchChartData();
    _summaryFuture = AnalyticsService.fetchSummary();
    _personalityFuture = AnalyticsService.fetchPersonality();
    _fortuneFuture = AnalyticsService.fetchFortune();
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


  Widget _buildKeywordItem(Map<String, dynamic> keyword) {

    final String term = keyword['term'] as String? ?? '...';
    final int count = keyword['count'] as int? ?? 0;

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
              term, // (使用 'term')
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ),
          Text(
            '$count 次', // (使用 'count')
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
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

  Widget _buildSummaryCard(String summary, {bool isError = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        // (如果 'ok: false', 显示灰色卡片, 否则显示 AI 渐变色)
        gradient: isError
            ? LinearGradient(colors: [Colors.grey[700]!, Colors.grey[800]!])
            : LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
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
            isError ? 'ℹ️ 提示' : '🎯 本周 AI 工作总结', // (动态标题)
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Text(
            summary, // (显示 "本周暂无日志..." 或 真实总结)
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordsListCard(List<dynamic> keywords) {
    return Container(
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

          if (keywords.isEmpty)
            Center(child: Text('本周无关键词', style: TextStyle(color: Colors.grey)))
          else
          // (遍历真实的 keywords)
            ...keywords.map((keyword) {
              // (确保 keyword 是 Map<String, dynamic>)
              if (keyword is Map<String, dynamic>) {
                return _buildKeywordItem(keyword);
              }
              return SizedBox.shrink();
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildKeywordsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _summaryFuture, // (使用 AI 总结接口的 Future)
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('加载关键词失败: ${snapshot.error}', style: TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData) {
          return Center(child: Text('未找到关键词数据'));
        }

        // (API 成功返回数据)
        final Map<String, dynamic> data = snapshot.data!;
        final bool ok = data['ok'] as bool? ?? false;
        final String summary = data['summary'] as String? ?? 'AI 总结加载失败';
        final List<dynamic> keywords = data['keywords'] as List<dynamic>? ?? [];

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSummaryCard(summary, isError: !ok),
              SizedBox(height: 20),
              // (如果 ok: true 且有关键词, 才显示关键词列表)
              if (ok && keywords.isNotEmpty)
                _buildKeywordsListCard(keywords)
              else if (ok && keywords.isEmpty)
                Center(child: Text('本周无关键词'))
              else
                SizedBox.shrink(), // (如果 ok: false, 不显示关键词)
            ],
          ),
        );
      },
    );
  }


  Widget _buildAITab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _personalityFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('加载 MBTI 失败: ${snapshot.error}', style: TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData) {
          return Center(child: Text('无法生成性格分析'));
        }

        final data = snapshot.data!;
        final String type = data['type'] as String? ?? '????';
        final List<dynamic> breakdown = data['breakdown'] as List<dynamic>? ?? [];

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // 1. MBTI 结果卡片
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧠 MBTI 职场性格分析',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 20),

                    // 第一行：I N T J
                    Row(children: [
                      _buildMBTITrait('I', '内向', type.contains('I')),
                      _buildMBTITrait('N', '直觉', type.contains('N')),
                      _buildMBTITrait('T', '思维', type.contains('T')),
                      _buildMBTITrait('J', '判断', type.contains('J')),
                    ]),
                    SizedBox(height: 12),
                    // 第二行：E S F P
                    Row(children: [
                      _buildMBTITrait('E', '外向', type.contains('E')),
                      _buildMBTITrait('S', '实感', type.contains('S')),
                      _buildMBTITrait('F', '情感', type.contains('F')),
                      _buildMBTITrait('P', '感知', type.contains('P')),
                    ]),

                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('推测类型：$type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 8),
                          Text(
                            data['analysisSummary'] as String? ?? '基于您的工作日志分析得出的性格倾向。',
                            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // 2. 详细分析列表
              if (breakdown.isEmpty)
                Center(child: Text('暂无详细分析', style: TextStyle(color: Colors.grey)))
              else
                ...breakdown.map((item) {
                  if (item is Map<String, dynamic>) {
                    return Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['dimension']} (${item['type']})',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                          ),
                          SizedBox(height: 12),
                          Text(
                            item['description'] as String? ?? '',
                            style: TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.5),
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox.shrink();
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMBTITrait(String trait, String name, bool active) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.05), // (非激活时更透明)
          borderRadius: BorderRadius.circular(8),
          border: active ? Border.all(color: Colors.white, width: 1) : null, // (激活时加边框)
        ),
        child: Column(
          children: [
            Text(trait, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: active ? Colors.white : Colors.white60)),
            Text(name, style: TextStyle(fontSize: 12, color: active ? Colors.white : Colors.white60)),
          ],
        ),
      ),
    );
  }

  Widget _buildFortuneTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fortuneFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('加载运势失败: ${snapshot.error}', style: TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData) {
          return Center(child: Text('无法获取运势数据'));
        }

        final data = snapshot.data!;
        final String analysis = data['analysis'] as String? ?? '暂无分析';
        final Map<String, dynamic> suggestion = data['suggestion'] as Map<String, dynamic>? ?? {};

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // 1. 运势分析卡片
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
                      '基于 AI 的智能分析',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    SizedBox(height: 24),

                    // (移除了之前的 4 个指标行，因为 API 只返回了整体分析)

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
                            analysis,
                            style: TextStyle(
                              fontSize: 16,
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

              // 2. 幸运建议卡片
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
                    // 【使用真实数据】
                    _buildLuckyItem('幸运颜色', suggestion['color']?.toString() ?? '未知', '提升气场'),
                    _buildLuckyItem('幸运时间', suggestion['time']?.toString() ?? '未知', '高效时刻'),
                    _buildLuckyItem('幸运方位', suggestion['direction']?.toString() ?? '未知', '能量聚集'),
                    _buildLuckyItem('幸运数字', suggestion['number']?.toString() ?? '未知', '开启好运'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
