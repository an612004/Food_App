import 'package:flutter/material.dart';
import 'home.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// ...existing code...

class CartPage extends StatefulWidget {
  final Map<String, dynamic>? food;
  final int? quantity;
  static final List<Map<String, dynamic>> globalCartItems = [];
  const CartPage({Key? key, this.food, this.quantity}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  List<Map<String, dynamic>> cartItems = [];
  String paymentMethod = 'COD';

  int get totalPrice {
    int sum = 0;
    for (var item in cartItems) {
      sum += ((item['price'] ?? 0) as num).toInt() *
          ((item['quantity'] ?? 1) as int);
    }
    return sum;
  }

  @override
  void initState() {
    super.initState();
    // Nếu có món mới được truyền vào, thêm vào giỏ hàng toàn cục
    if (widget.food != null && widget.quantity != null) {
      CartPage.globalCartItems.add({
        'name': widget.food!['title'] ?? 'Không tên',
        'price': widget.food!['price'] ?? 0,
        'quantity': widget.quantity,
        'thumbnail': widget.food!['thumbnail'],
      });
    }
    cartItems = List<Map<String, dynamic>>.from(CartPage.globalCartItems);
  }

  void removeItem(int index) {
    setState(() {
      CartPage.globalCartItems.removeAt(index);
      cartItems = List<Map<String, dynamic>>.from(CartPage.globalCartItems);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Giỏ hàng',
            onPressed: () {},
          ),
        ],
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text('Chưa có món nào trong giỏ hàng'))
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: item['thumbnail'] != null
                                ? CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(item['thumbnail']),
                                    backgroundColor: Colors.orange[100],
                                  )
                                : CircleAvatar(
                                    backgroundColor: Colors.orange[100],
                                    child: const Icon(Icons.fastfood,
                                        color: Colors.orange),
                                  ),
                            title: Text(item['name']),
                            subtitle: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: Colors.orange),
                                  onPressed: () {
                                    setState(() {
                                      if (item['quantity'] > 1) {
                                        item['quantity']--;
                                        CartPage.globalCartItems[index]
                                            ['quantity'] = item['quantity'];
                                      }
                                    });
                                  },
                                ),
                                Text('Số lượng: ${item['quantity']}'),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline,
                                      color: Colors.orange),
                                  onPressed: () {
                                    setState(() {
                                      item['quantity']++;
                                      CartPage.globalCartItems[index]
                                          ['quantity'] = item['quantity'];
                                    });
                                  },
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${item['price']}đ'),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => removeItem(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tổng tiền: ${totalPrice}đ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.red)),
                        const SizedBox(height: 8),
                        Text('Phương thức thanh toán:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Radio<String>(
                              value: 'COD',
                              groupValue: paymentMethod,
                              onChanged: (value) {
                                setState(() {
                                  paymentMethod = value!;
                                });
                              },
                            ),
                            const Text('COD'),
                            Radio<String>(
                              value: 'Bank',
                              groupValue: paymentMethod,
                              onChanged: (value) {
                                setState(() {
                                  paymentMethod = value!;
                                });
                              },
                            ),
                            const Text('Chuyển khoản'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                              labelText: 'Tên người nhận'),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Vui lòng nhập tên'
                              : null,
                        ),
                        TextFormField(
                          controller: _phoneController,
                          decoration:
                              const InputDecoration(labelText: 'Số điện thoại'),
                          keyboardType: TextInputType.phone,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Vui lòng nhập số điện thoại'
                              : null,
                        ),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                              labelText: 'Địa chỉ giao hàng'),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Vui lòng nhập địa chỉ'
                              : null,
                        ),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                              labelText: 'Ghi chú (tuỳ chọn)'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange),
                          onPressed: () async {
                            if (cartItems.isEmpty) return;
                            if (_formKey.currentState?.validate() != true)
                              return;

                            // Lấy token đăng nhập
                            final prefs = await SharedPreferences.getInstance();
                            final token = prefs.getString('token');
                            if (token == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Bạn chưa đăng nhập!')),
                              );
                              return;
                            }
                            final orderData = {
                              'items': cartItems
                                  .map((item) => {
                                        'quantity': item['quantity'].toString(),
                                        'title': item['name'],
                                        'thumbnail': item['thumbnail'],
                                        'price': item['price'].toString(),
                                      })
                                  .toList(),
                              'restaurantId':
                                  '67757705-3181-4524-9bc2-2ae994102462',
                              'paymentMethod': 'cod',
                              'status': 'pending',
                              'address': _addressController.text.trim(),
                              'notes': _notesController.text.trim().isEmpty
                                  ? null
                                  : _notesController.text.trim(),
                              'phone': _phoneController.text.trim(),
                              'name': _nameController.text.trim(),
                            };

// Debug print before sending
                            debugPrint(
                                'Sending order data: ${jsonEncode(orderData)}');

                            try {
                              final response = await http.post(
                                Uri.parse(
                                    'https://food-app-cweu.onrender.com/api/v1/orders'),
                                headers: {
                                  'Content-Type': 'application/json',
                                  'Authorization': 'Bearer $token',
                                },
                                body: jsonEncode(orderData),
                              );

                              debugPrint(
                                  'Response status: ${response.statusCode}');
                              debugPrint('Response body: ${response.body}');

                              if (response.statusCode == 201 ||
                                  response.statusCode == 200) {
                                // Success handling
                                setState(() {
                                  CartPage.globalCartItems.clear();
                                  cartItems.clear();
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Đặt hàng thành công!')),
                                );
                                Navigator.of(context)
                                    .pushReplacementNamed('/donhang');
                              } else {
                                // Error handling with more details
                                final error = jsonDecode(response.body);
                                debugPrint('Error details: $error');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Đặt hàng thất bại: ${error['message']}')),
                                );
                              }
                            } catch (e) {
                              debugPrint('Exception while creating order: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi kết nối: $e')),
                              );
                            }
                          },
                          child: const Text('Đặt hàng'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: null,
    );
  }
}

class OrderPage extends StatefulWidget {
  final String paymentMethod;
  final List<Map<String, dynamic>>? initialOrders;
  const OrderPage({super.key, this.paymentMethod = 'COD', this.initialOrders});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  late List<Map<String, dynamic>> orders;

  final List<String> statusList = [
    'Chờ xác nhận',
    'Đã xác nhận',
    'Đang giao',
    'Đã giao',
    'Đã hủy',
  ];

  void updateStatus(int index, String newStatus) {
    setState(() {
      orders[index]['status'] = newStatus;
    });
  }

  @override
  void initState() {
    super.initState();
    orders = widget.initialOrders ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Giỏ hàng',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
        ],
      ),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có đơn nào'),
                  const SizedBox(height: 16),
                  Text(
                      'Phương thức thanh toán: ${widget.paymentMethod == 'COD' ? 'COD' : 'Chuyển khoản'}'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text('Mã đơn: ${order['id']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tổng tiền: ${order['total']}đ'),
                        Text(
                            'Phương thức thanh toán: ${order['paymentMethod'] == 'COD' ? 'COD' : 'Chuyển khoản'}'),
                        Row(
                          children: [
                            const Text('Trạng thái: '),
                            DropdownButton<String>(
                              value: order['status'],
                              items: statusList
                                  .map((status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      ))
                                  .toList(),
                              onChanged: (newStatus) {
                                if (newStatus != null) {
                                  updateStatus(index, newStatus);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
