import 'package:flutter/material.dart';
import 'cart_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '';

class TrangMonAn extends StatefulWidget {
  const TrangMonAn({super.key});

  @override
  State<TrangMonAn> createState() => _TrangMonAnState();
}

class _TrangMonAnState extends State<TrangMonAn> {
  String searchText = '';
  String selectedCategory = 'Tất cả';
  List<String> categories = ['Tất cả'];
  double minPrice = 0;
  double maxPrice = 1000000;
  int currentPage = 1;
  int pageSize = 10;
  int totalPages = 1;
  List<dynamic> allFoods = [];

  late Future<List<dynamic>> _foodsFuture;

  Future<List<dynamic>> fetchFoods() async {
    final endpoint = 'https://food-app-cweu.onrender.com/api/v1/products/';
    final response = await http.get(Uri.parse(endpoint));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['data']?['items'] ?? [];
      print('DEBUG: Số lượng món lấy từ API: ${items.length}');
      // Lấy danh mục
      final cats = items
          .map((e) => e['category']?['title'])
          .where((c) => c != null && c.toString().isNotEmpty)
          .map((c) => c.toString())
          .toSet()
          .toList();
      setState(() {
        categories = ['Tất cả', ...cats];
        allFoods = items;
        totalPages = (filteredFoods().length / pageSize).ceil().clamp(1, 999);
      });
      print('DEBUG: Số lượng món sau khi lọc: ${filteredFoods().length}');
      return items;
    } else {
      throw Exception('Lỗi API: ${response.statusCode}');
    }
  }

  @override
  void initState() {
    super.initState();
    _foodsFuture = fetchFoods();
  }

  List<dynamic> filteredFoods() {
    return allFoods.where((food) {
      final matchesSearch = food['title']
              ?.toString()
              .toLowerCase()
              .contains(searchText.toLowerCase()) ??
          false;
      final matchesCat = selectedCategory == 'Tất cả' ||
          (food['category']?['title']?.toString() == selectedCategory);
      final price = (food['price'] ?? 0).toDouble();
      final matchesPrice = price >= minPrice && price <= maxPrice;
      return matchesSearch && matchesCat && matchesPrice;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('🍽️ Món Ăn', style: TextStyle(color: Colors.white)),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // DEBUG: Hiển thị số lượng món lấy được từ API và sau khi lọc
              Builder(
                builder: (context) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text('DEBUG: Số lượng món từ API: ${allFoods.length}', style: TextStyle(color: Colors.red)),
                      // Text('DEBUG: Số lượng món sau khi lọc: ${filteredFoods().length}', style: TextStyle(color: Colors.red)),
                    ],
                  );
                },
              ),
              // Banner quảng cáo
              Container(
                width: double.infinity,
                height: 120,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.orangeAccent,
                        blurRadius: 8,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text('Khuyến mãi đặc biệt!',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text(
                                'Giảm giá 20% cho đơn hàng đầu tiên trong hôm nay.',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.local_offer,
                            color: Colors.orange, size: 40),
                      ),
                    ),
                  ],
                ),
              ),
              // Thanh tìm kiếm và lọc giá
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm món ăn...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.orange),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchText = value;
                          currentPage = 1;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Giá từ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          minPrice = double.tryParse(value) ?? 0;
                          currentPage = 1;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Đến',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          maxPrice = double.tryParse(value) ?? 1000000;
                          currentPage = 1;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Chọn danh mục
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories
                      .map((cat) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(cat,
                                  style: TextStyle(
                                      color: selectedCategory == cat
                                          ? Colors.white
                                          : Colors.orange)),
                              selected: selectedCategory == cat,
                              selectedColor: Colors.orange,
                              backgroundColor: Colors.white,
                              onSelected: (_) {
                                setState(() {
                                  selectedCategory = cat;
                                });
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              // Danh sách món ăn với phân trang
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _foodsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.orange));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Lỗi: ${snapshot.error}'));
                    }
                    // Sử dụng snapshot.data nếu lần đầu load
                    final foods = (snapshot.data ?? []) as List<dynamic>;
                    final filtered = filteredFoods();
                    if (foods.isEmpty && filtered.isEmpty) {
                      return const Center(
                          child: Text('Không có món ăn phù hợp!'));
                    }
                    // Phân trang
                    final showFoods = filtered.isNotEmpty ? filtered : foods;
                    final start = (currentPage - 1) * pageSize;
                    final end = (start + pageSize).clamp(0, showFoods.length);
                    final pageFoods = showFoods.sublist(start, end);
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: pageFoods.length,
                            itemBuilder: (context, index) {
                              final food = pageFoods[index];
                              return Card(
                                color: Colors.orange.shade100,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: food['thumbnail'] != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            food['thumbnail'],
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(Icons.fastfood,
                                          size: 40, color: Colors.deepOrange),
                                  title: Text(food['title'] ?? 'Không tên',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange)),
                                  subtitle: Text(
                                      'Giá: ${food['price']?.toString() ?? '0'}đ',
                                      style: const TextStyle(
                                          color: Colors.orange)),
                                  trailing: Text(
                                      food['category']?['title']?.toString() ??
                                          '',
                                      style: const TextStyle(
                                          color: Colors.deepOrange)),
                                  onTap: () {
                                    int quantity = 1;
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        final price =
                                            (food['price'] ?? 0).toDouble();
                                        return StatefulBuilder(
                                          builder: (context, setState) {
                                            final total = price * quantity;
                                            return AlertDialog(
                                              title: Text(
                                                  food['title'] ?? 'Không tên'),
                                              content: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (food['thumbnail'] !=
                                                        null)
                                                      Center(
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          child: Image.network(
                                                              food['thumbnail'],
                                                              width: 120,
                                                              height: 120,
                                                              fit:
                                                                  BoxFit.cover),
                                                        ),
                                                      ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                        'Giá: ${price.toStringAsFixed(0)}đ',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors
                                                                .deepOrange)),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        const Text('Số lượng:',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                        IconButton(
                                                          icon: const Icon(Icons
                                                              .remove_circle_outline),
                                                          onPressed: quantity >
                                                                  1
                                                              ? () =>
                                                                  setState(() {
                                                                    quantity--;
                                                                  })
                                                              : null,
                                                        ),
                                                        Text(
                                                            quantity.toString(),
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        16)),
                                                        IconButton(
                                                          icon: const Icon(Icons
                                                              .add_circle_outline),
                                                          onPressed: () =>
                                                              setState(() {
                                                            quantity++;
                                                          }),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                        'Tổng tiền: ${total.toStringAsFixed(0)}đ',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.red)),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                        'Mô tả: ${food['description'] ?? 'Không có'}'),
                                                    Text(
                                                        'Danh mục: ${food['category']?['title']?.toString() ?? ''}'),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  child: const Text('Đóng'),
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                ),
                                                ElevatedButton.icon(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.orange),
                                                  icon: const Icon(
                                                      Icons.add_shopping_cart,
                                                      color: Colors.white),
                                                  label: const Text(
                                                      'Thêm vào giỏ hàng',
                                                      style: TextStyle(
                                                          color: Colors.white)),
                                                  onPressed: () {
                                                    // Thêm vào giỏ hàng toàn cục
                                                    CartPage.globalCartItems.add({
  'productId': food['id'] ?? food['productId'], // Thêm dòng này!
  'name': food['title'] ?? 'Không tên',
  'price': food['price'] ?? 0,
  'quantity': quantity,
  'thumbnail': food['thumbnail'],
});
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'Đã thêm $quantity vào giỏ hàng!')),
                                                    );
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        // Phân trang
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: currentPage > 1
                                  ? () => setState(() => currentPage--)
                                  : null,
                            ),
                            Text('Trang $currentPage/$totalPages',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: currentPage < totalPages
                                  ? () => setState(() => currentPage++)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
