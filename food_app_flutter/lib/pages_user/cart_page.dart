import 'package:flutter/material.dart';
import 'home.dart'; // Giữ nguyên import
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; 
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
  final TextEditingController _phoneController = TextEditingController();
  List<Map<String, dynamic>> cartItems = [];
  String paymentMethod = 'cod';

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
      'productId': widget.food?['id'] ?? widget.food?['productId'], // Thêm dòng này
      'name': widget.food?['title'] ?? widget.food?['name'] ?? 'Không tên',
      'price': widget.food?['price'] ?? 0,
      'quantity': widget.quantity ?? 1,
      'thumbnail': widget.food?['thumbnail'] ?? '',
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

 

Future<void> _placeOrder() async {
  if (cartItems.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Giỏ hàng trống!')),
    );
    return;
  }
  if (_formKey.currentState?.validate() != true) {
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bạn chưa đăng nhập!')),
    );
    return;
  }
  final orderData = {
  'address': _addressController.text.trim(),
  'notes': _notesController.text.trim(),
  'restaurantId': '14c90cd2-4e4b-11f0-a57b-c84bd64b6215',
  'phone': _phoneController.text.trim(),
  'items': cartItems
      .map((item) => {
            'productId': item['productId'],
            'quantity': item['quantity'],
          })
      .toList(),
  if (paymentMethod != 'credit_card')
    'paymentMethod': paymentMethod.toLowerCase(), // Chỉ truyền khi không phải momo
};
  print(orderData);
  try {
    final apiUrl = paymentMethod == 'credit_card'
        ? 'https://food-app-cweu.onrender.com/api/v1/momo'
        : 'https://food-app-cweu.onrender.com/api/v1/orders';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(orderData),
    );

    if (paymentMethod == 'credit_card') {
      final resData = jsonDecode(response.body);
      print(resData);final TextEditingController _nameController = TextEditingController();

      if (response.statusCode == 201 && resData['data']?['payUrl'] != null) {
        final payUrl = resData['data']['payUrl'];
        if (await canLaunchUrl(Uri.parse(payUrl))) {
          await launchUrl(Uri.parse(payUrl), mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể mở trang thanh toán!')),
          );
        }
        setState(() {
        CartPage.globalCartItems.clear();
        cartItems.clear();
      });
      Navigator.of(context).pushReplacementNamed('/donhang');
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đặt hàng thất bại: ${resData['message'] ?? 'Lỗi không xác định'}')),
        );
        return;
      }
    }

    // Xử lý như cũ cho COD
    if (response.statusCode == 201 || response.statusCode == 200) {
      setState(() {
        CartPage.globalCartItems.clear();
        cartItems.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt hàng thành công!')),
      );
      Navigator.of(context).pushReplacementNamed('/donhang');
    } else {
      final error = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đặt hàng thất bại: ${error['message']}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi kết nối: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng của bạn',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        iconTheme:
            const IconThemeData(color: Colors.white), // Đặt màu icon về trắng
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Giỏ hàng',
            onPressed: () {},
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: cartItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_shopping_cart,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Giỏ hàng trống!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Hãy thêm món ngon vào giỏ của bạn nhé!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              // Changed: Wrapped with SingleChildScrollView
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Changed: Integrated cart items directly into the Column
                    ...cartItems.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final Map<String, dynamic> item = entry.value;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        elevation: 4, // Thêm đổ bóng
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12), // Bo góc mềm mại
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: item['thumbnail'] != null &&
                                        item['thumbnail'].isNotEmpty
                                    ? Image.network(
                                        item['thumbnail'],
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.orange[50],
                                          child: const Icon(Icons.fastfood,
                                              color: Colors.orange, size: 40),
                                        ),
                                      )
                                    : Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.orange[50],
                                        child: const Icon(Icons.fastfood,
                                            color: Colors.orange, size: 40),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item['price']}đ',
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey[700]),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            _buildQuantityButton(
                                                Icons.remove_circle_outline,
                                                () {
                                              setState(() {
                                                if (item['quantity'] > 1) {
                                                  item['quantity']--;
                                                  CartPage.globalCartItems[
                                                          index]['quantity'] =
                                                      item['quantity'];
                                                }
                                              });
                                            }),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                              child: Text(
                                                '${item['quantity']}',
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            _buildQuantityButton(
                                                Icons.add_circle_outline, () {
                                              setState(() {
                                                item['quantity']++;
                                                CartPage.globalCartItems[index]
                                                        ['quantity'] =
                                                    item['quantity'];
                                              });
                                            }),
                                          ],
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red, size: 24),
                                          onPressed: () => removeItem(index),
                                          tooltip: 'Xóa món ăn',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    _buildOrderSummary(),
                  ],
                ),
              ),
            ),
      // bottomNavigationBar: null, // Có thể bỏ nếu không cần thiết
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.orange),
        onPressed: onPressed,
        constraints: const BoxConstraints(), // Để icon không bị giãn quá mức
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3), // Shadows on top
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng:',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              Text(
                '${totalPrice}đ',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1), // Đường kẻ phân cách
          Text(
            'Phương thức thanh toán:',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('COD (Thanh toán khi nhận hàng)'),
                  value: 'COD',
                  groupValue: paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      paymentMethod = value!;
                    });
                  },
                  activeColor: Colors.orange,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Chuyển khoản'),
                  value: 'credit_card',
                  groupValue: paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      paymentMethod = value!;
                    });
                  },
                  activeColor: Colors.orange,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextFormField(_phoneController, 'Số điện thoại',
              keyboardType: TextInputType.phone,
              validator: (value) => value == null || value.isEmpty
                  ? 'Vui lòng nhập số điện thoại'
                  : null),
          _buildTextFormField(_addressController, 'Địa chỉ giao hàng',
              validator: (value) => value == null || value.isEmpty
                  ? 'Vui lòng nhập địa chỉ giao hàng'
                  : null),
          _buildTextFormField(_notesController, 'Ghi chú (tuỳ chọn)',
              maxLines: 2),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              onPressed: _placeOrder, // Gọi hàm đặt hàng
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'Xác nhận đặt hàng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String labelText,
      {TextInputType? keyboardType,
      String? Function(String?)? validator,
      int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
      ),
    );
  }
}

// ---

class OrderPage extends StatefulWidget {
  final String paymentMethod;
  final List<Map<String, dynamic>>? initialOrders;
  const OrderPage({super.key, this.paymentMethod = 'COD', this.initialOrders});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  late List<Map<String, dynamic>> orders;

  final Map<String, String> statusMap = {
    'pending': 'Chờ xác nhận',
    'confirmed': 'Đã xác nhận',
    'delivering': 'Đang giao',
    'delivered': 'Đã giao',
    'cancelled': 'Đã hủy',
  };

  @override
  void initState() {
    super.initState();
    orders = widget.initialOrders ?? [];
    // Tải các đơn hàng từ API khi trang được khởi tạo
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa đăng nhập!')),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://food-app-cweu.onrender.com/api/v1/orders/my-orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedOrders = jsonDecode(response.body)['data'];
        setState(() {
          orders = fetchedOrders
              .map((order) => order as Map<String, dynamic>)
              .toList();
        });
      } else {
        debugPrint('Failed to load orders: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải đơn hàng.')),
        );
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối khi tải đơn hàng: $e')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'delivering':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
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
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Bạn chưa có đơn hàng nào.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hãy bắt đầu đặt món ngay bây giờ!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      // Chắc chắn Home.dart là route đầu tiên, hoặc điều hướng đến trang chính
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) =>
                                const TrangHome()), // Thay thế bằng trang chủ của bạn nếu cần
                      );
                    },
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Xem thực đơn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final String currentStatusDisplay =
                    statusMap[order['status']] ?? 'Không xác định';

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mã đơn hàng: ${order['_id'] ?? 'N/A'}', // Sử dụng _id nếu có
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tổng tiền: ${order['totalPrice'] != null ? order['totalPrice'] : order['total']}đ',
                          style: const TextStyle(
                              fontSize: 15,
                              color: Colors.red,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phương thức thanh toán: ${order['paymentMethod'] == 'cod' ? 'COD (Thanh toán khi nhận hàng)' : 'Chuyển khoản'}',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Địa chỉ: ${order['address'] ?? 'N/A'}',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        if (order['notes'] != null && order['notes'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Ghi chú: ${order['notes']}',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[700]),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Trạng thái: ',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[700]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                        order['status'] ?? 'unknown')
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                currentStatusDisplay,
                                style: TextStyle(
                                  color: _getStatusColor(
                                      order['status'] ?? 'unknown'),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, thickness: 1),
                        const Text(
                          'Chi tiết món ăn:',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap:
                              true, // Quan trọng để ListView.builder lồng nhau
                          physics:
                              const NeverScrollableScrollPhysics(), // Vô hiệu hóa cuộn của ListView con
                          itemCount: (order['items'] as List).length,
                          itemBuilder: (context, itemIndex) {
                            final foodItem =
                                (order['items'] as List)[itemIndex];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4.0),
                                    child: foodItem['thumbnail'] != null &&
                                            foodItem['thumbnail'].isNotEmpty
                                        ? Image.network(
                                            foodItem['thumbnail'],
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                  Icons.image_not_supported,
                                                  size: 25),
                                            ),
                                          )
                                        : Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.grey[200],
                                            child: const Icon(
                                                Icons.image_not_supported,
                                                size: 25),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${foodItem['title'] ?? 'N/A'}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          '${foodItem['quantity'] ?? 1} x ${foodItem['price'] ?? 0}đ',
                                          style: TextStyle(
                                              color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
