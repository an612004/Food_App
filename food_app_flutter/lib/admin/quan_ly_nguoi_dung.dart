import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class QuanLyNguoiDung extends StatefulWidget {
  const QuanLyNguoiDung({super.key});

  @override
  State<QuanLyNguoiDung> createState() => _QuanLyNguoiDungState();
}

class _QuanLyNguoiDungState extends State<QuanLyNguoiDung> {
  int _page = 1;
  final int _pageSize = 10000; // Hiển thị tất cả user trên 1 trang
  int _total = 0;
  bool _isLoadingMore = false;
  List<dynamic> _users = [];
  String _search = '';
  bool _sortAsc = true;
  bool _loading = true;
  // Make these fields final as suggested by 'prefer_final_fields'
  final TextEditingController _searchController =
      TextEditingController(); // Thêm controller cho search
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoadingMore &&
          _users.length < _total) {
        setState(() {
          _page++;
        });
        fetchUsers();
      }
    });

    // Listen to search controller changes
    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text;
        _page = 1; // Reset về trang 1 khi tìm kiếm
        // Không gọi fetchUsers ở đây, chỉ lọc local
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchUsers() async {
    setState(() {
      _loading = true;
      _isLoadingMore = true;
    });
    final endpoint =
        'https://food-app-cweu.onrender.com/api/v1/users?page=$_page&limit=$_pageSize&search=$_search';
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(endpoint),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );
      debugPrint('API response status: ${response.statusCode}');
      debugPrint('API response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['data']?['items'] ?? [];
        if (mounted) {
          setState(() {
            _users = items;
            _total = data['data']?['total'] ?? items.length;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi API: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      debugPrint('API error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi gọi API: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  List<dynamic> get filteredUsers {
    var list = _users;
    debugPrint(
        'filteredUsers.length = [33m[0m${list.length}, _users.length = ${_users.length}');
    if (_search.isNotEmpty) {
      final searchLower = _search.toLowerCase();
      list = list.where((e) {
        final fullName =
            (e['fullName'] ?? e['name'] ?? '').toString().toLowerCase();
        final email = (e['email'] ?? '').toString().toLowerCase();
        final phone = (e['phone'] ?? '').toString().toLowerCase();
        final address = (e['address'] ?? '').toString().toLowerCase();
        return fullName.contains(searchLower) ||
            email.contains(searchLower) ||
            phone.contains(searchLower) ||
            address.contains(searchLower);
      }).toList();
    }
    list.sort((a, b) => _sortAsc
        ? (a['fullName'] ?? a['name'] ?? '')
            .toString()
            .compareTo((b['fullName'] ?? b['name'] ?? '').toString())
        : (b['fullName'] ?? b['name'] ?? '')
            .toString()
            .compareTo((a['fullName'] ?? a['name'] ?? '').toString()));
    return list;
  }

  Future<void> addOrEditUser([Map<String, dynamic>? user]) async {
    // Controller cục bộ, dispose an toàn sau khi dialog đóng
    final fullNameController =
        TextEditingController(text: user?['fullName'] ?? '');
    final phoneController = TextEditingController(text: user?['phone'] ?? '');
    final emailController = TextEditingController(text: user?['email'] ?? '');
    final passwordController = TextEditingController();
    final isEdit = user != null;
    String? userId;
    if (isEdit) {
      if (user != null && user.containsKey('_id')) {
        userId = user['_id']?.toString();
      } else if (user != null && user.containsKey('id')) {
        userId = user['id']?.toString();
      }
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEdit ? 'Sửa người dùng' : 'Thêm người dùng'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              if (isEdit && userId != null)
                Text('ID: $userId',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(labelText: 'Họ và tên *'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại *'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email *'),
                enabled: !isEdit, // Chỉ nhập khi thêm, không cho sửa khi edit
              ),
              if (!isEdit)
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Mật khẩu *'),
                  obscureText: true,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              // Validate các trường bắt buộc khi thêm mới
              if (!isEdit &&
                  (fullNameController.text.isEmpty ||
                      emailController.text.isEmpty ||
                      phoneController.text.isEmpty ||
                      passwordController.text.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Vui lòng nhập đầy đủ họ tên, email, số điện thoại và mật khẩu!')),
                );
                return;
              }
              final data = isEdit
                  ? {
                      'fullName': fullNameController.text,
                      'phone': phoneController.text,
                    }
                  : {
                      'fullName': fullNameController.text,
                      'phone': phoneController.text,
                      'email': emailController.text,
                      'password': passwordController.text,
                    };
              String endpoint;
              if (isEdit) {
                if (userId == null || userId.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Không tìm thấy ID người dùng!')),
                    );
                  }
                  return;
                }
                endpoint =
                    'https://food-app-cweu.onrender.com/api/v1/users/$userId';
              } else {
                endpoint = 'https://food-app-cweu.onrender.com/api/v1/users';
              }
              try {
                final token = await _getToken();
                http.Response response;
                if (isEdit) {
                  response = await http.patch(
                    Uri.parse(endpoint),
                    headers: {
                      'Content-Type': 'application/json',
                      if (token != null) 'Authorization': 'Bearer $token',
                    },
                    body: jsonEncode(data),
                  );
                } else {
                  response = await http.post(
                    Uri.parse(endpoint),
                    headers: {
                      'Content-Type': 'application/json',
                      if (token != null) 'Authorization': 'Bearer $token',
                    },
                    body: jsonEncode(data),
                  );
                }
                if (response.statusCode == 200 || response.statusCode == 201) {
                  if (mounted) {
                    Navigator.pop(dialogContext);
                  }
                  // Luôn load lại danh sách mới nhất từ server
                  await fetchUsers();
                  if (mounted) {
                    setState(() {}); // Đảm bảo UI cập nhật
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Đã lưu!' : 'Đã thêm!')),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: ${response.statusCode}')),
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
    // Không dispose controller ở đây để tránh lỗi khi dialog chưa thực sự đóng
  }

  Future<void> deleteUser(Map<String, dynamic> user) async {
    // Lấy id đúng khi xóa user
    String? userId;
    if (user.containsKey('_id')) {
      userId = user['_id']?.toString();
    } else if (user.containsKey('id')) {
      userId = user['id']?.toString();
    }
    debugPrint('DELETE USER - id gửi lên: $userId, user: $user');
    if (userId == null || userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy ID người dùng!')),
        );
      }
      return;
    }
    final endpoint = 'https://food-app-cweu.onrender.com/api/v1/users/$userId';
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse(endpoint),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );
      debugPrint('DELETE USER response status: \\${response.statusCode}');
      debugPrint('DELETE USER response body: \\${response.body}');
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Luôn load lại danh sách mới nhất từ server
        await fetchUsers();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa người dùng!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Lỗi: ${response.statusCode} | ${response.body}')),
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
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
        : Container(
            color: Colors.orange.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm tên, email...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange),
                        onPressed: () => addOrEditUser(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredUsers.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= filteredUsers.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: Colors.orange)),
                        );
                      }
                      final user = filteredUsers[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: ListTile(
                          leading: user['avatar'] != null &&
                                  user['avatar'].toString().isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(user['avatar']))
                              : const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(
                              user['fullName'] ?? user['name'] ?? 'Không tên'),
                          subtitle: Text(
                            (user['email'] ?? '') +
                                (user['role'] != null &&
                                        (user['role'] as String).isNotEmpty
                                    ? ' | Vai trò: ${user['role']}'
                                    : ''),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.info, color: Colors.blue),
                                tooltip: 'Xem chi tiết',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Chi tiết người dùng'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'ID: \\${user['id'] ?? user['_id'] ?? ''}'),
                                          Text(
                                              'Tên: \\${user['fullName'] ?? user['name'] ?? ''}'),
                                          Text(
                                              'Email: \\${user['email'] ?? ''}'),
                                          Text('SĐT: \\${user['phone'] ?? ''}'),
                                          Text(
                                              'Giới tính: \\${user['gender'] ?? ''}'),
                                          Text(
                                              'Địa chỉ: \\${user['address'] ?? ''}'),
                                          Text(
                                              'Vai trò: \\${user['role'] ?? ''}'),
                                          Text(
                                              'Trạng thái: \\${user['status'] ?? ''}'),
                                          Text(
                                              'Ngày tạo: \\${user['createdAt'] ?? ''}'),
                                          Text(
                                              'Ngày cập nhật: \\${user['updatedAt'] ?? ''}'),
                                          if (user['avatar'] != null &&
                                              user['avatar']
                                                  .toString()
                                                  .isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: Image.network(
                                                  user['avatar'],
                                                  height: 60),
                                            ),
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
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.orange),
                                tooltip: 'Sửa',
                                onPressed: () => addOrEditUser(user),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Xóa',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Xác nhận xóa'),
                                      content: Text(
                                          'Bạn có chắc muốn xóa người dùng này?'),
                                      actions: [
                                        TextButton(
                                          child: const Text('Hủy'),
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red),
                                          child: const Text('Xóa',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await deleteUser(user);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Không cần phân trang, hiển thị tất cả user trên 1 trang
              ],
            ),
          );
  }
}
