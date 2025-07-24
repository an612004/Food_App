import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// Hàm upload ảnh lên Cloudinary, trả về link ảnh
Future<String?> uploadImageToCloudinary(File imageFile) async {
  final cloudName = 'demo'; // Thay bằng cloud name của bạn
  final uploadPreset = 'demo'; // Thay bằng upload preset của bạn
  final url =
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
  final request = http.MultipartRequest('POST', url)
    ..fields['upload_preset'] = uploadPreset
    ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
  final response = await request.send();
  if (response.statusCode == 200) {
    final respStr = await response.stream.bytesToString();
    final jsonResp = jsonDecode(respStr);
    return jsonResp['secure_url'] as String?;
  }
  return null;
}

class QuanLyMonAn extends StatefulWidget {
  const QuanLyMonAn({super.key});

  @override
  State<QuanLyMonAn> createState() => _QuanLyMonAnState();
}

class _QuanLyMonAnState extends State<QuanLyMonAn> {
  List<dynamic> _foods = [];
  List<dynamic> _categories = [];
  String _selectedCategory = 'Tất cả';
  String _search = '';
  bool _sortAsc = true;
  bool _loading = true;
  // Danh mục món ăn (ngoài "Tất cả")
  List<dynamic> get _realCategories => _categories;

  Future<void> fetchFoods() async {
    setState(() => _loading = true);
    try {
      final resFood = await http
          .get(Uri.parse('https://food-app-cweu.onrender.com/api/v1/products'));
      final resCat = await http.get(
          Uri.parse('https://food-app-cweu.onrender.com/api/v1/categories'));
      if (resFood.statusCode == 200 && resCat.statusCode == 200) {
        final dataFood = jsonDecode(resFood.body);
        final dataCat = jsonDecode(resCat.body);
        _foods = dataFood['data']?['items'] ?? [];
        _categories = dataCat['data']?['items'] ?? [];
      }
    } catch (e) {}
    setState(() => _loading = false);
  }

  // Quản lý danh mục: thêm/xóa/sửa
  Future<void> showCategoryManager() async {
    final newCatController = TextEditingController();
    bool isAdding = false;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Danh mục món ăn'),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListView(
                    shrinkWrap: true,
                    children: _realCategories
                        .map((cat) => ListTile(
                              title: Text(cat['title'] ?? ''),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  if (isAdding)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newCatController,
                            decoration: const InputDecoration(
                              labelText: 'Tên danh mục mới',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          tooltip: 'Thêm',
                          onPressed: () async {
                            final title = newCatController.text.trim();
                            if (title.isEmpty) return;
                            // Gọi API thêm danh mục
                            final endpoint =
                                'https://food-app-cweu.onrender.com/api/v1/categories';
                            try {
                              final response = await http.post(
                                Uri.parse(endpoint),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({'title': title}),
                              );
                              if (response.statusCode == 201 ||
                                  response.statusCode == 200) {
                                newCatController.clear();
                                setStateDialog(() => isAdding = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Đã thêm danh mục!')),
                                  );
                                }
                                await fetchFoods();
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Lỗi: ${response.statusCode}')),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e')),
                                );
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: 'Hủy',
                          onPressed: () {
                            setStateDialog(() => isAdding = false);
                          },
                        ),
                      ],
                    ),
                  if (!isAdding)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.add, color: Colors.orange),
                        label: const Text('Thêm danh mục',
                            style: TextStyle(color: Colors.orange)),
                        onPressed: () {
                          setStateDialog(() => isAdding = true);
                        },
                      ),
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
    );
  }

  List<dynamic> get filteredFoods {
    var list = _selectedCategory == 'Tất cả'
        ? _foods
        : _foods
            .where((e) => (e['category']?['title'] ?? '') == _selectedCategory)
            .toList();
    if (_search.isNotEmpty) {
      list = list
          .where((e) => (e['title'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_search.toLowerCase()))
          .toList();
    }
    list.sort((a, b) => _sortAsc
        ? (a['price'] ?? 0).compareTo(b['price'] ?? 0)
        : (b['price'] ?? 0).compareTo(a['price'] ?? 0));
    return list;
  }

  Future<void> addOrEditFood([Map<String, dynamic>? food]) async {
    debugPrint('addOrEditFood called. food: ${food?.toString()}');
    final titleController = TextEditingController(text: food?['title'] ?? '');
    final priceController =
        TextEditingController(text: food?['price']?.toString() ?? '');
    final descriptionController =
        TextEditingController(text: food?['description'] ?? '');
    final thumbnailController =
        TextEditingController(text: food?['thumbnail'] ?? '');
    File? pickedImage;
    String selectedCatId = food != null &&
            food['category'] != null &&
            food['category']['id'] != null
        ? food['category']['id']
        : (_realCategories.isNotEmpty ? _realCategories.first['id'] : '');
    final isEdit = food != null;
    await showDialog(
      context: context,
      builder: (context) {
        String tempCatId = selectedCatId;
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Text(isEdit ? 'Sửa món ăn' : 'Thêm món ăn'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Tên món'),
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Giá'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Mô tả'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: thumbnailController,
                          decoration: const InputDecoration(
                              labelText: 'Link ảnh (tự động khi upload)'),
                          readOnly: true,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.image, color: Colors.orange),
                        tooltip: 'Chọn ảnh từ thiết bị',
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (picked != null) {
                            pickedImage = File(picked.path);
                            thumbnailController.text = 'Đang upload...';
                            final url =
                                await uploadImageToCloudinary(pickedImage!);
                            if (url != null) {
                              thumbnailController.text = url;
                            } else {
                              thumbnailController.text = '';
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Upload ảnh thất bại!')),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tempCatId,
                    decoration: const InputDecoration(labelText: 'Danh mục'),
                    items: _realCategories.map<DropdownMenuItem<String>>((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['id'],
                        child: Text(cat['title'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => tempCatId = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Hủy'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () async {
                  String thumbnailUrl = thumbnailController.text;
                  // Nếu chọn ảnh mới thì upload, nếu không thì giữ nguyên ảnh cũ
                  if (pickedImage != null) {
                    thumbnailController.text = 'Đang upload...';
                    final url = await uploadImageToCloudinary(pickedImage!);
                    if (url != null) {
                      thumbnailUrl = url;
                      thumbnailController.text = url;
                    } else {
                      thumbnailController.text = '';
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Upload ảnh thất bại!')),
                        );
                      }
                      return;
                    }
                  }
                  // Nếu thêm mới thì bắt buộc phải có ảnh
                  if (!isEdit && (thumbnailUrl.isEmpty || thumbnailUrl == 'Đang upload...')) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng chọn và upload ảnh món ăn!')),
                      );
                    }
                    return;
                  }
                  final data = {
                    'title': titleController.text,
                    'price': int.tryParse(priceController.text) ?? 0,
                    'categoryId': tempCatId,
                    'description': descriptionController.text,
                  };
                  // Nếu có ảnh thì gửi lên, nếu không thì không gửi trường thumbnail khi chỉnh sửa
                  if (thumbnailUrl.isNotEmpty && thumbnailUrl != 'Đang upload...') {
                    data['thumbnail'] = thumbnailUrl;
                  }
                  final endpoint = isEdit
                      ? 'https://food-app-cweu.onrender.com/api/v1/products/${food['id']}'
                      : 'https://food-app-cweu.onrender.com/api/v1/products';
                  try {
                    http.Response response;
                    if (isEdit) {
                      response = await http.patch(
                        Uri.parse(endpoint),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode(data),
                      );
                    } else {
                      response = await http.post(
                        Uri.parse(endpoint),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode(data),
                      );
                    }
                    if (response.statusCode == 200 ||
                        response.statusCode == 201) {
                      if (mounted) {
                        Navigator.pop(context);
                        await fetchFoods();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isEdit ? 'Đã lưu!' : 'Đã thêm!')),
                        );
                      }
                    } else {
                      String errorMsg = 'Lỗi: ${response.statusCode}';
                      try {
                        final respJson = jsonDecode(response.body);
                        if (respJson['message'] != null)
                          errorMsg += '\n${respJson['message']}';
                        if (respJson['errors'] != null)
                          errorMsg += '\n${respJson['errors'].toString()}';
                      } catch (e) {
                        errorMsg += '\nKhông thể phân tích lỗi: $e';
                      }
                      debugPrint('API PATCH error: $errorMsg\nBody: ${response.body}');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errorMsg)),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  }
                },
                child: Text(isEdit ? 'Lưu' : 'Thêm'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> deleteFood(Map<String, dynamic> food) async {
    final endpoint =
        'https://food-app-cweu.onrender.com/api/v1/products/${food['id']}';
    try {
      final response = await http.delete(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        await fetchFoods();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa món ăn!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchFoods();
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
        : Container(
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Thêm món ăn',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => addOrEditFood(),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.category, color: Colors.white),
                        label: const Text('Quản lý danh mục',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => showCategoryManager(),
                      ),
                    ],
                  ),
                ),
                // ...existing code for category chips, search box...
                Expanded(
                  child: filteredFoods.isEmpty
                      ? Center(
                          child: Text('Không có món ăn nào!',
                              style: TextStyle(
                                  color: Colors.orange.shade400,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredFoods.length,
                          itemBuilder: (context, i) {
                            final food = filteredFoods[i];
                            return Card(
                              color: Colors.white,
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(food['title'] ?? 'Không tên'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (food['thumbnail'] != null)
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                food['thumbnail'],
                                                width: 180,
                                                height: 120,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          const SizedBox(height: 8),
                                          Text(
                                              'Giá: ${food['price']?.toString() ?? '0'}đ',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text(
                                              'Mô tả: ${food['description'] ?? 'Không có'}'),
                                          Text(
                                              'Danh mục: ${food['category']?['title'] ?? ''}'),
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
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: food['thumbnail'] != null
                                              ? Image.network(
                                                  food['thumbnail'],
                                                  width: 120,
                                                  height: 90,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  width: 120,
                                                  height: 90,
                                                  child: const Icon(
                                                      Icons.fastfood,
                                                      size: 60,
                                                      color: Colors.deepOrange),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        food['title'] ?? 'Không tên',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.deepOrange,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Giá: ${food['price']?.toString() ?? '0'}đ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Danh mục: ${food['category']?['title'] ?? ''}',
                                        style: const TextStyle(
                                          color: Colors.blueGrey,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.blue),
                                            tooltip: 'Chỉnh sửa',
                                            onPressed: () {
                                              debugPrint(
                                                  'Edit button pressed for food: ${food.toString()}');
                                              addOrEditFood(food);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            tooltip: 'Xóa',
                                            onPressed: () => deleteFood(food),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
