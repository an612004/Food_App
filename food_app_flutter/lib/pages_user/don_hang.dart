import 'package:flutter/material.dart';

final List<String> statusList = [
  'Tất cả',
  'Chờ xác nhận',
  'Đã xác nhận',
  'Đang giao',
  'Đã giao',
  'Đã hủy',
];
String _selectedStatus = 'Tất cả';

class MonAnYeuThich extends StatefulWidget {
  const MonAnYeuThich({super.key});

  @override
  State<MonAnYeuThich> createState() => _MonAnYeuThichState();
}

class _MonAnYeuThichState extends State<MonAnYeuThich> {
  List<Map<String, dynamic>> orders = [];
  bool _loading = false;

  // Giả lập lấy đơn hàng từ API, bạn thay endpoint thật ở đây
  Future<void> fetchOrders() async {
    setState(() => _loading = true);
    // final endpoint = 'http://10.0.2.2:3000/api/v1/orders/user';
    // try {
    //   final response = await http.get(Uri.parse(endpoint));
    //   if (response.statusCode == 200) {
    //     final data = jsonDecode(response.body);
    //     orders = data['data']?['items'] ?? [];
    //   }
    // } catch (e) {}
    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
        : Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long,
                          color: Colors.deepOrange, size: 32),
                      const SizedBox(width: 10),
                      const Text('Đơn hàng của bạn',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange)),
                    ],
                  ),
                ),
                // Bộ lọc trạng thái
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt,
                          color: Colors.orange, size: 22),
                      const SizedBox(width: 8),
                      const Text('Lọc trạng thái:',
                          style: TextStyle(
                              fontSize: 16, color: Colors.deepOrange)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedStatus,
                        items: statusList
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: (newStatus) {
                          if (newStatus != null) {
                            setState(() => _selectedStatus = newStatus);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: orders.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Image.asset('assets/images/empty_order.png', height: 120),
                            const SizedBox(height: 16),
                            const Text('Chưa có đơn hàng nào!',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.orange)),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: orders
                              .where((order) =>
                                  _selectedStatus == 'Tất cả' ||
                                  order['status'] == _selectedStatus)
                              .length,
                          itemBuilder: (context, i) {
                            final filteredOrders = orders
                                .where((order) =>
                                    _selectedStatus == 'Tất cả' ||
                                    order['status'] == _selectedStatus)
                                .toList();
                            final order = filteredOrders[i];
                            Color statusColor;
                            switch (order['status']) {
                              case 'Chờ xác nhận':
                                statusColor = Colors.orange;
                                break;
                              case 'Đã xác nhận':
                                statusColor = Colors.blue;
                                break;
                              case 'Đang giao':
                                statusColor = Colors.purple;
                                break;
                              case 'Đã giao':
                                statusColor = Colors.green;
                                break;
                              case 'Đã hủy':
                                statusColor = Colors.red;
                                break;
                              default:
                                statusColor = Colors.grey;
                            }
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.shade100,
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange.shade50,
                                  child: const Icon(Icons.fastfood,
                                      color: Colors.deepOrange),
                                ),
                                title: Text('Mã đơn: ${order['id'] ?? ''}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Tổng tiền: ${order['total'] ?? 0}đ',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                statusColor.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.circle,
                                                  color: statusColor, size: 12),
                                              const SizedBox(width: 6),
                                              Text(
                                                  order['status'] ??
                                                      'Chờ xác nhận',
                                                  style: TextStyle(
                                                      color: statusColor,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Icon(Icons.arrow_forward_ios,
                                    color: Colors.orange.shade300, size: 20),
                                onTap: () {
                                  // Xem chi tiết đơn hàng
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Chi tiết đơn hàng'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Mã đơn: ${order['id'] ?? ''}'),
                                          Text(
                                              'Tổng tiền: ${order['total'] ?? 0}đ'),
                                          Text(
                                              'Trạng thái: ${order['status'] ?? 'Chờ xác nhận'}'),
                                          // Thêm thông tin sản phẩm nếu có
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          child: const Text('Đóng'),
                                          onPressed: () =>
                                              Navigator.pop(context),
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
            ),
          );
  }
}
