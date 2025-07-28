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
  // Status code từ API
  final List<String> _orderStatusList = [
    'pending', // Chờ xác nhận
    'preparing', // Đang giao
    'completed', // Hoàn thành
    'cancelled', // Đã hủy
  ];

  // Map status code <-> tiếng Việt
  String statusToVN(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'preparing':
        return 'Đang giao';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String statusFromVN(String vn) {
    switch (vn) {
      case 'Chờ xác nhận':
        return 'pending';
      case 'Đang giao':
        return 'preparing';
      case 'Hoàn thành':
        return 'completed';
      case 'Đã hủy':
        return 'cancelled';
      default:
        return vn;
    }
  }

  String _selectedStatus = 'Tất cả';
  String _search = '';
  bool _loading = true;

  Future<void> fetchOrders() async {
    setState(() => _loading = true);
    final endpoint = 'https://food-app-cweu.onrender.com/api/v1/Orders';
    try {
      final response = await http.get(Uri.parse(endpoint));
      debugPrint('Status: \\${response.statusCode}');
      debugPrint('Body: \\${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Parsed data: \\${data.toString()}');
        _orders = data['data'] ?? [];
        debugPrint('Orders length: \\${_orders.length}');
      }
    } catch (e) {
      debugPrint('Error: \\${e.toString()}');
    }
    setState(() => _loading = false);
  }

  List<dynamic> get filteredOrders {
    var list = _selectedStatus == 'Tất cả'
        ? _orders
        : _orders
            .where((e) => e['status'] == statusFromVN(_selectedStatus))
            .toList();
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
                                setState(() {
                                  if (_selectedStatus == status &&
                                      status != 'Tất cả') {
                                    _selectedStatus = 'Tất cả';
                                  } else {
                                    _selectedStatus = status;
                                  }
                                });
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
                              leading: Icon(
                                  statusIcon(statusToVN(order['status'] ?? '')),
                                  color: statusColor(
                                      statusToVN(order['status'] ?? '')),
                                  size: 40),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Mã đơn: ${order['orderCode'] ?? order['id'] ?? ''}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange)),
                                  Text(
                                      'Tên: ${order['name'] ?? order['customerName'] ?? ''}',
                                      style: const TextStyle(
                                          color: Colors.orange)),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('SĐT: ${order['phone'] ?? ''}',
                                      style: const TextStyle(
                                          color: Colors.deepOrange)),
                                  Text('Địa chỉ: ${order['address'] ?? ''}',
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
                              trailing: DropdownButton<String>(
                                value: order['status'],
                                items: _orderStatusList
                                    .map((status) => DropdownMenuItem(
                                          value: status,
                                          child: Text(statusToVN(status)),
                                        ))
                                    .toList(),
                                onChanged: (newStatus) async {
                                  if (newStatus != null &&
                                      newStatus != order['status']) {
                                    final orderId =
                                        order['id'] ?? order['orderCode'];
                                    final url =
                                        'https://food-app-cweu.onrender.com/api/v1/Orders/$orderId';
                                    try {
                                      final res = await http.patch(
                                        Uri.parse(url),
                                        headers: {
                                          'Content-Type': 'application/json'
                                        },
                                        body: jsonEncode({'status': newStatus}),
                                      );
                                      if (res.statusCode == 200) {
                                        setState(() {
                                          order['status'] = newStatus;
                                        });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Cập nhật trạng thái thất bại!')),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text('Lỗi kết nối!')),
                                      );
                                    }
                                  }
                                },
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Chi tiết đơn hàng'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Mã đơn: ${order['orderCode'] ?? order['id'] ?? ''}'),
                                          Text(
                                              'Tên: ${order['name'] ?? order['customerName'] ?? ''}'),
                                          Text('SĐT: ${order['phone'] ?? ''}'),
                                          Text(
                                              'Địa chỉ: ${order['address'] ?? ''}'),
                                          Text(
                                              'Tổng tiền: ${order['total']?.toString() ?? '0'}đ'),
                                          Text('Ngày: ${order['date'] ?? ''}'),
                                          Row(
                                            children: [
                                              const Text('Trạng thái: '),
                                              DropdownButton<String>(
                                                value: order['status'],
                                                items: _orderStatusList
                                                    .map((status) =>
                                                        DropdownMenuItem(
                                                          value: status,
                                                          child: Text(
                                                              statusToVN(
                                                                  status)),
                                                        ))
                                                    .toList(),
                                                onChanged: (newStatus) async {
                                                  if (newStatus != null &&
                                                      newStatus !=
                                                          order['status']) {
                                                    final orderId =
                                                        order['id'] ??
                                                            order['orderCode'];
                                                    final url =
                                                        'https://food-app-cweu.onrender.com/api/v1/Orders/$orderId';
                                                    try {
                                                      final res =
                                                          await http.patch(
                                                        Uri.parse(url),
                                                        headers: {
                                                          'Content-Type':
                                                              'application/json'
                                                        },
                                                        body: jsonEncode({
                                                          'status': newStatus
                                                        }),
                                                      );
                                                      if (res.statusCode ==
                                                          200) {
                                                        setState(() {
                                                          order['status'] =
                                                              newStatus;
                                                        });
                                                        Navigator.pop(context);
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                              content: Text(
                                                                  'Cập nhật trạng thái thành công!')),
                                                        );
                                                      } else {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                              content: Text(
                                                                  'Cập nhật trạng thái thất bại!')),
                                                        );
                                                      }
                                                    } catch (e) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                            content: Text(
                                                                'Lỗi kết nối!')),
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          if (order['items'] != null &&
                                              order['items'] is List &&
                                              order['items'].isNotEmpty)
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text('Danh sách món:',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                ...order['items']
                                                    .map<Widget>((item) =>
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 2),
                                                          child: Text(
                                                              '- ${item['name'] ?? ''} x${item['quantity'] ?? 1}'),
                                                        ))
                                                    .toList(),
                                              ],
                                            ),
                                        ],
                                      ),
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
