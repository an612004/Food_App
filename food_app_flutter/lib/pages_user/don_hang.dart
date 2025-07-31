import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_app_flutter/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Danh sách trạng thái đơn hàng
final List<String> statusList = [
  'Tất cả',
  'Chờ xác nhận',
  'Đang chuẩn bị',
  'Hoàn thành',
  'Thanh toán',
  'Đã hủy',
];

class MonAnYeuThich extends ConsumerStatefulWidget {
  const MonAnYeuThich({super.key});

  @override
  ConsumerState<MonAnYeuThich> createState() => _MonAnYeuThichState();
}

class _MonAnYeuThichState extends ConsumerState<MonAnYeuThich> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String? userId;
  String _selectedStatus = 'Tất cả'; // Biến trạng thái được chọn

  @override
  void initState() {
    super.initState();
    fetchOrders();

    final socketService = ref.read(socketServiceProvider).socket;
  socketService.on('order:updated', (data) {
    print('Nhận socket order:updated');
    if (!mounted) return;

    final updatedOrder = data as Map<String, dynamic>;
    setState(() {
      // Tìm và cập nhật đơn hàng trong danh sách
      final index = orders.indexWhere((o) =>
          o['id'] == updatedOrder['id'] || o['_id'] == updatedOrder['_id']);
      if (index != -1) {
        orders[index] = updatedOrder;
      }
    });
  });
  }

  // Lấy token từ SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Giải mã JWT để lấy userId
  String? _getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payloadMap = json.decode(payload);
      return payloadMap['id'] ?? payloadMap['_id'] ?? payloadMap['userId'];
    } catch (e) {
      debugPrint('Lỗi giải mã token: $e');
      return null;
    }
  }

  // Lấy danh sách đơn hàng từ API
  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
    });

    final token = await _getToken();
    if (token == null) {
      if (mounted) {
        setState(() {
          orders = [];
          isLoading = false;
        });
        _showSnackBar('Không tìm thấy token đăng nhập. Vui lòng đăng nhập lại.',
            Colors.red);
      }
      return;
    }

    final currentUserId = _getUserIdFromToken(token);
    debugPrint('userId từ token: ' + (currentUserId ?? 'null'));

    if (currentUserId == null) {
      if (mounted) {
        setState(() {
          orders = [];
          isLoading = false;
        });
        _showSnackBar(
            'Không thể lấy ID người dùng từ token. Vui lòng đăng nhập lại.',
            Colors.red);
      }
      return;
    }

    userId = currentUserId;

    try {
      final response = await http.get(
        Uri.parse('https://food-app-cweu.onrender.com/api/v1/orders'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = (data['data'] ?? []) as List;

        // In ra userId/user của từng đơn hàng để debug
        for (var e in items) {
          debugPrint('Order id: ' +
              (e['id']?.toString() ?? e['_id']?.toString() ?? 'null') +
              ' | userId: ' +
              (e['userId']?.toString() ?? 'null') +
              ' | user: ' +
              (e['user']?.toString() ?? 'null'));
        }

        if (mounted) {
          setState(() {
            orders = items
                .where((e) =>
                    // Lọc đúng theo user['id'] (API trả về trường này)
                    (e['user'] is Map && e['user']['id'] == userId))
                .map<Map<String, dynamic>>((e) => e as Map<String, dynamic>)
                .toList();
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            orders = [];
            isLoading = false;
          });
          _showSnackBar(
              'Lỗi khi tải đơn hàng: ${response.statusCode}', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          orders = [];
          isLoading = false;
        });
        _showSnackBar(
            'Không thể kết nối đến máy chủ. Vui lòng thử lại.', Colors.red);
      }
      debugPrint('Lỗi fetchOrders: $e');
    }
  }

  // Hiển thị SnackBar thông báo
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lọc danh sách đơn hàng dựa trên _selectedStatus
    final filteredOrders = orders.where((order) {
      if (_selectedStatus == 'Tất cả') {
        return true;
      }
      return order['status'] == _selectedStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng của bạn',
            style: TextStyle(color: Colors.deepOrange)),
        backgroundColor: Colors.orange.shade50,
        iconTheme: const IconThemeData(color: Colors.deepOrange),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.deepOrange),
            onPressed: fetchOrders,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long,
                            color: Colors.deepOrange, size: 32),
                        SizedBox(width: 10),
                        Text('Đơn hàng của bạn',
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
                    child: filteredOrders.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline,
                                    size: 48, color: Colors.orange),
                                SizedBox(height: 16),
                                Text(
                                    'Chưa có đơn hàng nào hoặc không có đơn hàng phù hợp với trạng thái đã chọn!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.orange)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, i) {
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
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10),
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
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mã đơn: ${order['id'] ?? order['_id'] ?? 'Không có'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                      Text(
                                        'Tên: ${order['user']?['fullName'] ?? 'Chưa có thông tin'}',
                                        style: const TextStyle(
                                            color: Colors.orange),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'SĐT: ${order['user']?['phone'] ?? 'Không có'}',
                                        style: const TextStyle(
                                            color: Colors.deepOrange),
                                      ),
                                      Text(
                                        'Địa chỉ: ${order['address'] ?? 'Không có'}',
                                        style: const TextStyle(
                                            color: Colors.orange),
                                      ),
                                      Text(
                                        'Tổng tiền: ${order['total']?.toStringAsFixed(0) ?? '0'}đ',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
                                                    color: statusColor,
                                                    size: 12),
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
                                      if (order.containsKey('items') &&
                                          order['items'] is List &&
                                          (order['items'] as List).isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('Sản phẩm:',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              ...(order['items']
                                                      as List<dynamic>)
                                                  .map<Widget>((item) => Row(
                                                        children: [
                                                          if (item != null &&
                                                              item.containsKey(
                                                                  'thumbnail') &&
                                                              item['thumbnail'] !=
                                                                  null)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      right:
                                                                          8.0),
                                                              child: Image.network(
                                                                  item[
                                                                      'thumbnail'],
                                                                  width: 32,
                                                                  height: 32,
                                                                  fit: BoxFit
                                                                      .cover),
                                                            ),
                                                          Flexible(
                                                            child:Text(
  '${item['title'] ?? item['name'] ?? 'Không rõ'} x${item['quantity'] ?? 1} - ${(num.tryParse(item['price']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}đ'
),
                                                          ),
                                                        ],
                                                      ))
                                                  .toList(),
                                            ],
                                          ),
                                        )
                                      else
                                        const Padding(
                                          padding: EdgeInsets.only(top: 8.0),
                                          child: Text(
                                              'Không có sản phẩm nào trong đơn hàng này.'),
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
                                        title: const Text('Chi tiết đơn hàng'),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  'Mã đơn: ${order['id'] ?? order['_id'] ?? 'Không có'}'),
                                              Text(
                                                  'Tên: ${order['user']?['fullName'] ?? 'Chưa có thông tin'}'),
                                              Text(
                                                  'SĐT: ${order['user']?['phone'] ?? 'Không có'}'),
                                              Text(
                                                  'Địa chỉ: ${order['address'] ?? 'Không có'}'),
                                              Text(
                                                  'Tổng tiền: ${order['total']?.toStringAsFixed(0) ?? '0'}đ'),
                                              Text(
                                                  'Trạng thái: ${order['status'] ?? 'Chờ xác nhận'}'),
                                              if (order.containsKey('items') &&
                                                  order['items'] is List &&
                                                  (order['items'] as List)
                                                      .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text('Sản phẩm:',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                      ...(order['items']
                                                              as List<dynamic>)
                                                          .map<Widget>(
                                                              (item) => Row(
                                                                    children: [
                                                                      if (item !=
                                                                              null &&
                                                                          item.containsKey(
                                                                              'thumbnail') &&
                                                                          item['thumbnail'] !=
                                                                              null)
                                                                        Padding(
                                                                          padding: const EdgeInsets
                                                                              .only(
                                                                              right: 8.0),
                                                                          child: Image.network(
                                                                              item['thumbnail'],
                                                                              width: 32,
                                                                              height: 32,
                                                                              fit: BoxFit.cover),
                                                                        ),
                                                                      Flexible(
                                                                        child: Text(
                                                                            '${item?['title'] ?? item?['name'] ?? 'Không rõ'} x${item?['quantity'] ?? 1} - ${item?['price']?.toStringAsFixed(0) ?? 0}đ'),
                                                                      ),
                                                                    ],
                                                                  ))
                                                          .toList(),
                                                    ],
                                                  ),
                                                )
                                              else
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 8.0),
                                                  child: Text(
                                                      'Không có sản phẩm nào trong đơn hàng này.'),
                                                ),
                                            ],
                                          ),
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
      ),
    );
  }
}
