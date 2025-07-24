import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuanLyNguoiDung extends StatefulWidget {
  const QuanLyNguoiDung({super.key});

  @override
  State<QuanLyNguoiDung> createState() => _QuanLyNguoiDungState();
}

class _QuanLyNguoiDungState extends State<QuanLyNguoiDung> {
  int _page = 1;
  final int _pageSize = 10;
  int _total = 0;
  bool _isLoadingMore = false;
  List<dynamic> _users = [];
  List<String> _roles = ['Tất cả'];
  String _selectedRole = 'Tất cả';
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
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchUsers() async {
    if (_isLoadingMore) return;
    setState(() {
      _loading = _page == 1;
      _isLoadingMore = true;
    });
    final endpoint =
        'https://food-app-cweu.onrender.com/api/v1/users?page=$_page&limit=$_pageSize';
    try {
      final response = await http.get(Uri.parse(endpoint));
      debugPrint('API response status: ${response.statusCode}');
      debugPrint('API response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['data']?['items'] ?? [];
        if (mounted) {
          // Check mounted before setState
          setState(() {
            if (_page == 1) {
              _users = items;
            } else {
              _users.addAll(items);
            }
            _total = data['data']?['total'] ?? items.length;
            _roles = ['Tất cả'];
            _roles.addAll(_users
                .map((e) => (e['role'] ?? '').toString())
                .toSet()
                .where((c) => c.isNotEmpty));
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
      // Use finally to ensure _isLoadingMore is reset
      if (mounted) {
        setState(() {
          _loading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  List<dynamic> get filteredUsers {
    var list = _selectedRole == 'Tất cả'
        ? _users
        : _users.where((e) => e['role'] == _selectedRole).toList();
    if (_search.isNotEmpty) {
      list = list
          .where((e) =>
              (e['name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(_search.toLowerCase()) ||
              (e['email'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(_search.toLowerCase()))
          .toList();
    }
    list.sort((a, b) => _sortAsc
        ? (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString())
        : (b['name'] ?? '').toString().compareTo((a['name'] ?? '').toString()));
    return list;
  }

  Future<void> addOrEditUser([Map<String, dynamic>? user]) async {
    final nameController = TextEditingController(text: user?['name'] ?? '');
    final emailController = TextEditingController(text: user?['email'] ?? '');
    final avatarController = TextEditingController(text: user?['avatar'] ?? '');
    final isEdit = user != null;
    String selectedRole = user?['role'] ?? 'user';

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEdit ? 'Sửa người dùng' : 'Thêm người dùng'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Vai trò'),
                items: ['admin', 'user']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) selectedRole = value;
                },
              ),
              TextField(
                controller: avatarController,
                decoration: const InputDecoration(labelText: 'Link avatar'),
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
              final data = {
                'name': nameController.text,
                'email': emailController.text,
                'role': selectedRole,
                'avatar': avatarController.text,
              };
              final endpoint = isEdit
                  ? 'https://food-app-cweu.onrender.com/api/v1/users/${user!['id']}'
                  : 'https://food-app-cweu.onrender.com/api/v1/users';
              final method = isEdit ? 'PUT' : 'POST';
              try {
                final request = http.Request(method, Uri.parse(endpoint))
                  ..headers['Content-Type'] = 'application/json'
                  ..body = jsonEncode(data);
                final streamed = await request.send();
                if (streamed.statusCode == 200 || streamed.statusCode == 201) {
                  if (mounted) {
                    Navigator.pop(dialogContext);
                  }
                  await fetchUsers();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Đã lưu!' : 'Đã thêm!')),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: ${streamed.statusCode}')),
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

    nameController.dispose();
    emailController.dispose();
    avatarController.dispose();
  }

  Future<void> deleteUser(Map<String, dynamic> user) async {
    final endpoint =
        'https://food-app-cweu.onrender.com/api/v1/users/${user['id']}';
    try {
      final response = await http.delete(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        await fetchUsers();
        if (mounted) {
          // Check mounted before using context
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa người dùng!')),
          );
        }
      } else {
        if (mounted) {
          // Check mounted before using context
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Check mounted before using context
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
                // Tiêu đề
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.people, color: Colors.deepOrange, size: 32),
                      const SizedBox(width: 10),
                      const Text('Quản Lý Người Dùng',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange)),
                    ],
                  ),
                ),
                // Nút Thêm bên dưới tiêu đề, căn phải
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Thêm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () => addOrEditUser(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: _roles
                              .map((role) => ChoiceChip(
                                    label: Text(role,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    selected: _selectedRole == role,
                                    selectedColor: Colors.deepOrange,
                                    backgroundColor: Colors.orange.shade100,
                                    onSelected: (v) {
                                      setState(() => _selectedRole = role);
                                    },
                                    labelStyle: TextStyle(
                                        color: _selectedRole == role
                                            ? Colors.white
                                            : Colors.deepOrange),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: <Widget>[
                      const Text('Sắp xếp:',
                          style: TextStyle(
                              fontSize: 16, color: Colors.deepOrange)),
                      IconButton(
                        icon: Icon(
                            _sortAsc
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: Colors.deepOrange),
                        onPressed: () => setState(() => _sortAsc = !_sortAsc),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller:
                              _searchController, // Link controller to TextField
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm tên hoặc email...',
                            prefixIcon: const Icon(Icons.search,
                                color: Colors.deepOrange),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 15), // Adjusted padding
                          ),
                          onChanged: (value) {
                            // setState is now handled by the listener on _searchController
                            // _search = value; // No need for this line anymore
                          },
                        ),
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
                        color: Colors.white,
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 20), // Added horizontal margin
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 18),
                          child: Row(
                            children: <Widget>[
                              user['avatar'] != null &&
                                      user['avatar'].toString().isNotEmpty
                                  ? CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(user['avatar']),
                                      radius: 32,
                                    )
                                  : const CircleAvatar(
                                      backgroundColor: Colors.orange,
                                      radius: 32,
                                      child: Icon(Icons.person,
                                          color: Colors.white, size: 32),
                                    ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                        (user['fullName'] ??
                                                user['name'] ??
                                                'Không tên')
                                            .toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: Colors.deepOrange)),
                                    const SizedBox(height: 4),
                                    Text(user['email'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.orange)),
                                    const SizedBox(height: 2),
                                    Container(
                                      // Changed to SizedBox for whitespace
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(user['role'] ?? '',
                                          style: const TextStyle(
                                              color: Colors.deepOrange,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => addOrEditUser(user),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: const Text('Xác nhận xóa'),
                                        content: Text(
                                            'Bạn có chắc chắn muốn xóa người dùng "${user['name']}"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dialogContext),
                                            child: const Text('Hủy'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red),
                                            onPressed: () async {
                                              if (mounted) {
                                                Navigator.pop(dialogContext);
                                              }
                                              await deleteUser(user);
                                            },
                                            child: const Text('Xóa'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
