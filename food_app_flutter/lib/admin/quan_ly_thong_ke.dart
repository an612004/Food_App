import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class QuanLyThongKe extends StatefulWidget {
  const QuanLyThongKe({super.key});

  @override
  State<QuanLyThongKe> createState() => _QuanLyThongKeState();
}

class _QuanLyThongKeState extends State<QuanLyThongKe> {
  Map<String, dynamic> _stats = {};
  List<dynamic> _revenueChart = [];
  bool _loading = true;

  Future<void> fetchStats() async {
    setState(() => _loading = true);
    final endpoint = 'http://10.0.2.2:3000/api/v1/stats';
    try {
      final response = await http.get(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _stats = data['data'] ?? {};
        _revenueChart = _stats['revenueChart'] ?? [];
      }
    } catch (e) {
      debugPrint('Lỗi fetchStats: $e');
    }
    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thống Kê',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _StatCard(
                        title: 'Doanh thu',
                        value: '${_stats['totalRevenue'] ?? 0}đ',
                        icon: Icons.attach_money,
                        color: Colors.green,
                      ),
                      _StatCard(
                        title: 'Đơn hàng',
                        value: '${_stats['totalOrders'] ?? 0}',
                        icon: Icons.shopping_cart,
                        color: Colors.orange,
                      ),
                      _StatCard(
                        title: 'Người dùng',
                        value: '${_stats['totalUsers'] ?? 0}',
                        icon: Icons.person,
                        color: Colors.blue,
                      ),
                      _StatCard(
                        title: 'Món bán chạy',
                        value: _stats['bestSeller'] ?? 'Không có',
                        icon: Icons.fastfood,
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Biểu đồ doanh thu theo tháng',
                    style: TextStyle(fontSize: 18, color: Colors.deepOrange),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: _revenueChart.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.grey, size: 40),
                                SizedBox(height: 8),
                                Text(
                                  'Không có dữ liệu',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 ||
                                          idx >= _revenueChart.length) {
                                        return const SizedBox();
                                      }
                                      return Text(
                                        _revenueChart[idx]['month'] ?? '',
                                        style: const TextStyle(fontSize: 12),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    for (int i = 0;
                                        i < _revenueChart.length;
                                        i++)
                                      FlSpot(
                                        i.toDouble(),
                                        (_revenueChart[i]['revenue'] ?? 0)
                                            .toDouble(),
                                      ),
                                  ],
                                  isCurved: true,
                                  color: Colors.orange,
                                  barWidth: 4,
                                  dotData: FlDotData(show: true),
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
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
