// reject_reason_dialog.dart
import 'package:flutter/material.dart';

class RejectReasonDialog extends StatefulWidget {
  @override
  _RejectReasonDialogState createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<RejectReasonDialog> {
  final TextEditingController _reasonController = TextEditingController();
  final List<String> _commonReasons = [
    '工作内容描述不清晰',
    '缺少必要的现场照片',
    '位置信息不准确',
    '工作成果未达到要求',
    '其他原因'
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '请输入拒绝原因',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // 常用原因选择
            Text('常用原因:', style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _commonReasons.map((reason) =>
                  FilterChip(
                    label: Text(reason, style: TextStyle(fontSize: 12)),
                    selected: _reasonController.text == reason,
                    onSelected: (selected) {
                      setState(() {
                        _reasonController.text = selected ? reason : '';
                      });
                    },
                  )
              ).toList(),
            ),

            SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: '或输入其他原因...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text('取消'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _reasonController.text.trim()),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('确认拒绝'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}