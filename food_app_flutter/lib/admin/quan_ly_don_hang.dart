import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuanLyDonHang extends StatefulWidget {
  const QuanLyDonHang({super.key});

  @override
  State<QuanLyDonHang> createState() => _QuanLyDonHangState();
}

class _QuanLyDonHangState extends State<QuanLyDonHang> {
  List<dynamic> _orders = [];
  final List<String> _statuses = [
    'Tất cả',
    'Chờ xác nhận',
    'Đang giao',
    'Hoàn thành',
    'Đã hủy'
  ];
  String _selectedStatus = 'Tất cả';
  String _search = '';
  bool _loading = true;

  Future<void> fetchOrders() async {
    setState(() => _loading = true);
    // Giả lập API, bạn thay endpoint thật ở đây
    final endpoint = 'http://10.0.2.2:3000/api/v1/orders';
    try {
      final response = await http.get(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _orders = data['data']?['items'] ?? [];
      }
    } catch (e) {}
    setState(() => _loading = false);
  }

  List<dynamic> get filteredOrders {
    var list = _selectedStatus == 'Tất cả'
        ? _orders
        : _orders.where((e) => e['status'] == _selectedStatus).toList();
    if (_search.isNotEmpty) {
      list = list
          .where((e) =>
              (e['customerName'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(_search.toLowerCase()) ||
              (e['orderCode'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(_search.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Chờ xác nhận':
        return Colors.orange;
      case 'Đang giao':
        return Colors.blue;
      case 'Hoàn thành':
        return Colors.green;
      case 'Đã hủy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case 'Chờ xác nhận':
        return Icons.hourglass_top;
      case 'Đang giao':
        return Icons.delivery_dining;
      case 'Hoàn thành':
        return Icons.check_circle;
      case 'Đã hủy':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Quản Lý Đơn Hàng',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange)),
              ),
              // Bộ lọc trạng thái
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statuses
                      .map((status) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(status),
                              selected: _selectedStatus == status,
                              selectedColor: statusColor(status),
                              onSelected: (v) {
                                setState(() => _selectedStatus = status);
                              },
                              labelStyle: TextStyle(
                                  color: _selectedStatus == status
                                      ? Colors.white
                                      : statusColor(status)),
                            ),
                          ))
                      .toList(),
                ),
              ),
              // Tìm kiếm
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên khách hoặc mã đơn...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              // Danh sách đơn hàng
              Expanded(
                child: filteredOrders.isEmpty
                    ? const Center(child: Text('Không có đơn hàng!'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, i) {
                          final order = filteredOrders[i];
                          return Card(
                            color: Colors.orange.shade100,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: Icon(statusIcon(order['status'] ?? ''),
                                  color: statusColor(order['status'] ?? ''),
                                  size: 40),
                              title: Text('Mã đơn: ${order['orderCode'] ?? ''}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Khách: ${order['customerName'] ?? ''}',
                                      style: const TextStyle(
                                          color: Colors.orange)),
                                  Text(
                                      'Tổng tiền: ${order['total']?.toString() ?? '0'}đ',
                                      style: const TextStyle(
                                          color: Colors.deepOrange)),
                                  Text('Ngày: ${order['date'] ?? ''}',
                                      style: const TextStyle(
                                          color: Colors.orange)),
                                ],
                              ),
                              trailing: Text(order['status'] ?? '',
                                  style: TextStyle(
                                      color: statusColor(order['status'] ?? ''),
                                      fontWeight: FontWeight.bold)),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Chi tiết đơn hàng'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Mã đơn: ${order['orderCode'] ?? ''}'),
                                        Text(
                                            'Khách: ${order['customerName'] ?? ''}'),
                                        Text(
                                            'Tổng tiền: ${order['total']?.toString() ?? '0'}đ'),
                                        Text('Ngày: ${order['date'] ?? ''}'),
                                        Text(
                                            'Trạng thái: ${order['status'] ?? ''}'),
                                        // Có thể thêm chi tiết món ăn trong đơn
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        child: const Text('Đóng'),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
  }
}
