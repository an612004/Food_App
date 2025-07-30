import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cart_page.dart';

class TrangHome extends StatefulWidget {
  final void Function(int quantity)? onAddToCart;
  const TrangHome({Key? key, this.onAddToCart}) : super(key: key);

  @override
  State<TrangHome> createState() => _TrangHomeState();
}

class _TrangHomeState extends State<TrangHome> {
  late Future<List<dynamic>> _discountFoodsFuture;
  late Future<List<dynamic>> _featuredFoodsFuture;

  // Thêm biến lưu tên người dùng
  String? userName;
  String? userId;
  String? userEmail;

  Future<void> fetchUserName() async {
    // Ưu tiên lấy id hoặc email từ arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      userId = args['userId'] as String?;
      userEmail = args['userEmail'] as String?;
    }
    String? apiUrl;
    if (userId != null) {
      apiUrl = 'https://food-app-cweu.onrender.com/api/v1/users/$userId';
    } else if (userEmail != null) {
      apiUrl =
          'https://food-app-cweu.onrender.com/api/v1/users?email=$userEmail';
    }
    if (apiUrl != null) {
      try {
        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (userId != null) {
            userName = data['data']?['fullName'] ??
                data['data']?['name'] ??
                data['data']?['username'] ??
                '';
          } else if (userEmail != null) {
            final items = data['data']?['items'] ?? [];
            if (items.isNotEmpty) {
              userName = items[0]['fullName'] ??
                  items[0]['name'] ??
                  items[0]['username'] ??
                  '';
            }
          }
        }
      } catch (e) {
        userName = null;
      }
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lấy id hoặc email từ arguments, gọi API lấy tên user
    fetchUserName();
  }

  Future<List<dynamic>> fetchDiscountFoods() async {
    final endpoint = 'https://food-app-cweu.onrender.com/api/v1/products/';
    final response = await http.get(Uri.parse(endpoint));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['data']?['items'] ?? [];
      final discountFoods =
          items.where((e) => (e['discountPercentage'] ?? 0) > 0).toList();
      return discountFoods.take(5).toList();
    } else {
      throw Exception('Lỗi API: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> fetchFeaturedFoods() async {
    final endpoint = 'https://food-app-cweu.onrender.com/api/v1/products/';
    final response = await http.get(Uri.parse(endpoint));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['data']?['items'] ?? [];
      final featured = items.where((e) => e['featured'] == true).toList();
      if (featured.isEmpty) {
        return items.take(5).toList();
      }
      return featured;
    } else {
      throw Exception('Lỗi API: ${response.statusCode}');
    }
  }

  final ValueNotifier<int> _bannerIndexNotifier = ValueNotifier<int>(0);
  late PageController _bannerController;

  final List<String> banners = [
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
    'https://images.pexels.com/photos/461382/pexels-photo-461382.jpeg',
    'https://images.pexels.com/photos/70497/pexels-photo-70497.jpeg',
    'https://images.unsplash.com/photo-1525755662778-989d0524087e',
  ];

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(viewportFraction: 0.9);
    _featuredFoodsFuture = fetchFeaturedFoods();
    _discountFoodsFuture = fetchDiscountFoods();
    Future.microtask(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startBannerAutoSlide();
      });
    });
  }

  void _startBannerAutoSlide() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      _bannerIndexNotifier.value =
          (_bannerIndexNotifier.value + 1) % banners.length;
      _bannerController.animateToPage(
        _bannerIndexNotifier.value,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      return true;
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _bannerIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.orange,
          title: const Text('Trang Chủ', style: TextStyle(color: Colors.white)),
          elevation: 0,
          centerTitle: true,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 16), // Sửa lại padding
          children: [
            // Chào mừng user
            if (userName != null && userName!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Xin chào, $userName!',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 17, 16, 15),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // Giới thiệu app
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.shade200,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('FOOD APP KFC',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                      'Ứng dụng đặt món ăn online, nhanh chóng, tiện lợi và nhiều ưu đãi hấp dẫn!',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
            // Banner hình ảnh món ăn tự động trượt
            SizedBox(
              height: 160,
              child: Stack(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: _bannerIndexNotifier,
                    builder: (context, bannerIndex, _) {
                      return PageView.builder(
                        itemCount: banners.length,
                        controller: _bannerController,
                        onPageChanged: (i) => _bannerIndexNotifier.value = i,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.shade200,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                )
                              ],
                              image: DecorationImage(
                                image: NetworkImage(banners[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  // Dots indicator
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: ValueListenableBuilder<int>(
                      valueListenable: _bannerIndexNotifier,
                      builder: (context, bannerIndex, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                              banners.length,
                              (i) => Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: i == bannerIndex
                                          ? Colors.orange
                                          : Colors.white,
                                      border: Border.all(
                                          color: Colors.orange, width: 1),
                                    ),
                                  )),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Tiêu đề món ăn nổi bật
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('🔥 Món ăn nổi bật',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange)),
              ],
            ),
            const SizedBox(height: 12),
            // Danh sách món ăn nổi bật
            FutureBuilder<List<dynamic>>(
              future: _featuredFoodsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    children: List.generate(
                      5,
                      (index) => Card(
                        color: Colors.orange.shade100,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: SizedBox(
                            width: 60,
                            height: 60,
                            child: ColoredBox(
                              color: Colors.orange.shade200,
                              child: Container(),
                            ),
                          ),
                          title: SizedBox(
                            height: 16,
                            child: ColoredBox(
                              color: Colors.orange.shade200,
                              child: Container(),
                            ),
                          ),
                          subtitle: SizedBox(
                            height: 14,
                            child: ColoredBox(
                              color: Colors.orange.shade100,
                              child: Container(),
                            ),
                          ),
                          trailing: SizedBox(
                            width: 40,
                            height: 14,
                            child: ColoredBox(
                              color: Colors.orange.shade100,
                              child: Container(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                final foods = snapshot.data ?? [];
                if (foods.isEmpty) {
                  return const Center(child: Text('Không có món ăn nổi bật!'));
                }
                return Column(
                  children: foods
                      .map((food) => Card(
                            color: Colors.orange.shade100,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: food['thumbnail'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
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
                                  style: const TextStyle(color: Colors.orange)),
                              trailing: Text(
                                  food['category']?['title']?.toString() ?? '',
                                  style: const TextStyle(
                                      color: Colors.deepOrange)),
                              onTap: () {
                                int quantity = 1;
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    final price = food['price'] ?? 0;
                                    final discount =
                                        food['discountPercentage'] ?? 0;
                                    final discountedPrice = discount > 0
                                        ? (price * (1 - discount / 100)).round()
                                        : price;
                                    return StatefulBuilder(
                                      builder: (context, setState) {
                                        return Dialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24)),
                                          backgroundColor: Colors.white,
                                          child: SingleChildScrollView(
                                            child: Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Center(
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      child: food['thumbnail'] !=
                                                              null
                                                          ? Image.network(
                                                              food['thumbnail'],
                                                              width: 180,
                                                              height: 180,
                                                              fit: BoxFit.cover)
                                                          : Container(
                                                              width: 180,
                                                              height: 180,
                                                              color: Colors
                                                                  .orange
                                                                  .shade100,
                                                              child: const Icon(
                                                                  Icons
                                                                      .fastfood,
                                                                  size: 80,
                                                                  color: Colors
                                                                      .deepOrange),
                                                            ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                      food['title'] ??
                                                          'Không tên',
                                                      style: const TextStyle(
                                                          fontSize: 22,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors
                                                              .deepOrange)),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      if (discount > 0)
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .redAccent
                                                                .withOpacity(
                                                                    0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: Text(
                                                              '-${discount.toString()}%',
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .redAccent,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                        ),
                                                      if (discount > 0)
                                                        const SizedBox(
                                                            width: 8),
                                                      Text('Giá: ',
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                      Text(
                                                        '${discount > 0 ? discountedPrice : price}đ',
                                                        style: TextStyle(
                                                          color: discount > 0
                                                              ? Colors.redAccent
                                                              : Colors
                                                                  .deepOrange,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                          decoration: discount >
                                                                  0
                                                              ? TextDecoration
                                                                  .lineThrough
                                                              : null,
                                                        ),
                                                      ),
                                                      if (discount > 0) ...[
                                                        const SizedBox(
                                                            width: 8),
                                                        Text('${price}đ',
                                                            style: const TextStyle(
                                                                color: Colors
                                                                    .deepOrange,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 18)),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
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
                                                        onPressed: quantity > 1
                                                            ? () =>
                                                                setState(() {
                                                                  quantity--;
                                                                })
                                                            : null,
                                                      ),
                                                      Text(quantity.toString(),
                                                          style: const TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
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
                                                  Text('Mô tả:',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  Text(
                                                      food['description'] ??
                                                          'Không có',
                                                      style: const TextStyle(
                                                          color:
                                                              Colors.black87)),
                                                  const SizedBox(height: 8),
                                                  Text('Danh mục:',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  Text(
                                                      food['category']?['title']
                                                              ?.toString() ??
                                                          '',
                                                      style: const TextStyle(
                                                          color: Colors
                                                              .deepOrange)),
                                                  const SizedBox(height: 20),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      TextButton(
                                                        child: const Text(
                                                            'Đóng',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .deepOrange)),
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                      ),
                                                      ElevatedButton.icon(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.orange,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      18,
                                                                  vertical: 12),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12)),
                                                        ),
                                                        icon: const Icon(
                                                            Icons
                                                                .add_shopping_cart,
                                                            color:
                                                                Colors.white),
                                                        label: const Text(
                                                            'Thêm vào giỏ hàng',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                          Navigator.of(context)
                                                              .push(
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (context) =>
                                                                      CartPage(
                                                                food: food,
                                                                quantity:
                                                                    quantity,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            // Tiêu đề món ăn đang giảm giá
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('💸 Món ăn đang giảm giá',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange)),
              ],
            ),
            const SizedBox(height: 12),
            // Danh sách món ăn giảm giá
            FutureBuilder<List<dynamic>>(
              future: _discountFoodsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    children: List.generate(
                      5,
                      (index) => Card(
                        color: Colors.orange.shade100,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: SizedBox(
                            width: 60,
                            height: 60,
                            child: ColoredBox(
                              color: Colors.orange.shade200,
                              child: Container(),
                            ),
                          ),
                          title: SizedBox(
                            height: 16,
                            child: ColoredBox(
                              color: Colors.orange.shade200,
                              child: Container(),
                            ),
                          ),
                          subtitle: SizedBox(
                            height: 14,
                            child: ColoredBox(
                              color: Colors.orange.shade100,
                              child: Container(),
                            ),
                          ),
                          trailing: SizedBox(
                            width: 40,
                            height: 14,
                            child: ColoredBox(
                              color: Colors.orange.shade100,
                              child: Container(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                final foods = snapshot.data ?? [];
                if (foods.isEmpty) {
                  return const Center(child: Text('Không có món ăn giảm giá!'));
                }
                return Column(
                  children: foods
                      .map((food) => Card(
                            color: Colors.orange.shade100,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: food['thumbnail'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        food['thumbnail'],
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.local_offer,
                                      size: 40, color: Colors.redAccent),
                              title: Text(food['title'] ?? 'Không tên',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange)),
                              subtitle: Text(
                                  'Giá gốc: ${food['price']?.toString() ?? '0'}đ\nGiảm: ${food['discountPercentage']?.toString() ?? '0'}%',
                                  style: const TextStyle(color: Colors.orange)),
                              trailing: Text(
                                  food['category']?['title']?.toString() ?? '',
                                  style: const TextStyle(
                                      color: Colors.deepOrange)),
                              onTap: () {
                                int quantity = 1;
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    final price = food['price'] ?? 0;
                                    final discount =
                                        food['discountPercentage'] ?? 0;
                                    final discountedPrice = discount > 0
                                        ? (price * (1 - discount / 100)).round()
                                        : price;
                                    return StatefulBuilder(
                                      builder: (context, setState) {
                                        return AlertDialog(
                                          title: Text(
                                              food['title'] ?? 'Không tên'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (food['thumbnail'] != null)
                                                Image.network(food['thumbnail'],
                                                    width: 120,
                                                    height: 120,
                                                    fit: BoxFit.cover),
                                              const SizedBox(height: 8),
                                              Text(
                                                  'Giá ban đầu: ${price.toString()}đ',
                                                  style: const TextStyle(
                                                      color: Colors.deepOrange,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              if (discount > 0) ...[
                                                Text(
                                                    'Giá giảm: ${discountedPrice.toString()}đ',
                                                    style: const TextStyle(
                                                        color: Colors.redAccent,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text(
                                                    'Giảm: ${discount.toString()}%'),
                                              ],
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Text('Số lượng:',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  IconButton(
                                                    icon: const Icon(Icons
                                                        .remove_circle_outline),
                                                    onPressed: quantity > 1
                                                        ? () => setState(() {
                                                              quantity--;
                                                            })
                                                        : null,
                                                  ),
                                                  Text(quantity.toString(),
                                                      style: const TextStyle(
                                                          fontSize: 16)),
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
                                              Text(
                                                  'Mô tả: ${food['description'] ?? 'Không có'}'),
                                              Text(
                                                  'Danh mục: ${food['category']?['title']?.toString() ?? ''}'),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              child: const Text('Đóng'),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                            ),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
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
                                                // TODO: Thêm logic thêm vào giỏ hàng với số lượng
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context)
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
                          ))
                      .toList(),
                );
              },
            ),
            // Thông tin liên hệ và ưu đãi
            Container(
              // width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.shade200,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.phone, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Liên hệ: 1900 8888',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.location_on, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Địa chỉ: 123 Đường ABC, Quận 1, TP.HCM',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    icon: const Icon(Icons.card_giftcard, color: Colors.white),
                    label: const Text('Nhận ưu đãi hôm nay',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
