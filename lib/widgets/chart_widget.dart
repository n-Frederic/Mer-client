import 'package:flutter/material.dart';

class ChartWidget extends StatelessWidget {
  final String title;
  final List<double> data;
  final List<String> labels;

  const ChartWidget({
    Key? key,
    required this.title,
    required this.data,
    required this.labels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Container(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.asMap().entries.map((entry) {
              final index = entry.key;
              final value = entry.value;
              final height = (value / maxValue) * 160;
              
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 10),
                      ),
                      SizedBox(height: 4),
                      Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: Color(0xFF1976D2),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        labels[index],
                        style: TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
