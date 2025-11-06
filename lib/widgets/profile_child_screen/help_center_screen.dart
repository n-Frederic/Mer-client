import 'package:flutter/material.dart';

class HelpCenterScreen extends StatefulWidget {
  @override
  _HelpCenterScreenState createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  int? expandedIndex;

  final List<Map<String, String>> faqs = [
    {
      'question': '如何创建新的任务？',
      'answer': '点击主页面的"+"按钮，填写任务名称、描述和截止日期，即可创建新任务。',
    },
    {
      'question': '如何导出我的数据？',
      'answer': '在分析页面，点击右上角的"导出"按钮，选择导出格式（CSV 或 PDF）即可。',
    },
    {
      'question': '如何与他人共享任务？',
      'answer': '打开任务详情，点击"分享"按钮，输入对方邮箱或选择联系人即可共享。',
    },
    {
      'question': '如何重置密码？',
      'answer': '在登录页面点击"忘记密码"，输入注册邮箱，按照邮件指示重置密码。',
    },
    {
      'question': '离线模式支持吗？',
      'answer': '支持！所有本地数据都会在设备上保存，网络恢复后自动同步到云端。',
    },
  ];

  // 📩 弹出邮箱对话框
  void _showEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('联系我们'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_outline, color: Colors.orange, size: 40),
            SizedBox(height: 10),
            Text(
              '有事没事都可以联系：',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            SizedBox(height: 8),
            SelectableText(
              '2625791372@qq.com',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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

  // ☎ 弹出在线客服对话框
  void _showCustomerServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('在线客服'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/customer_service.png', // 这里放你的客服图片路径
              height: 120,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 10),
            Text(
              '客服电话：-----------',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 6),
            Text(
              '服务时间：随时都可以',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('帮助中心'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '常见问题',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: faqs.length,
                itemBuilder: (context, index) {
                  return _buildFAQItem(index);
                },
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFFFB3BA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(0xFFFFB3BA),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💬 仍需帮助？',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '联系我们的支持团队',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showEmailDialog,
                          icon: Icon(Icons.mail),
                          label: Text('邮件'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFFB3BA),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showCustomerServiceDialog,
                          icon: Icon(Icons.chat),
                          label: Text('在线客服'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF8C42),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(int index) {
    bool isExpanded = expandedIndex == index;
    final item = faqs[index];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => expandedIndex = isExpanded ? null : index),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['question']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Color(0xFFFF8C42),
                    ),
                  ],
                ),
              ),
              if (isExpanded)
                Container(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(color: Color(0xFFEEEEEE)),
                      SizedBox(height: 12),
                      Text(
                        item['answer']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
