import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuanLyPhanQuyen extends StatefulWidget {
  const QuanLyPhanQuyen({super.key});

  @override
  State<QuanLyPhanQuyen> createState() => _QuanLyPhanQuyenState();
}

class _QuanLyPhanQuyenState extends State<QuanLyPhanQuyen> {
  String? _apiMessage;
  List<dynamic> _roles = [];
  bool _loading = true;

  Future<void> fetchRoles() async {
    setState(() => _loading = true);
    final endpoint = 'https://food-app-cweu.onrender.com/api/v1/roles';
    try {
      final response = await http.get(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is List) {
          _apiMessage = null;
          _roles = data['data'];
        } else if (data['data'] is Map) {
          _apiMessage = null;
          _roles = data['data']?['items'] ?? [];
        } else {
          // Nếu là chuỗi thông báo hoặc không đúng cấu trúc, bỏ qua _apiMessage và hiển thị mặc định
          _roles = [];
        }
      }
      // Nếu không có role nào, hiển thị mặc định 2 role admin và user
      if (_roles.isEmpty) {
        _roles = [
          {
            'id': 'admin-default',
            'name': 'admin',
            'permissions': ['*'],
          },
          {
            'id': 'user-default',
            'name': 'user',
            'permissions': [],
          },
        ];
      }
      _apiMessage = null;
    } catch (e) {}
    setState(() => _loading = false);
  }

  Future<void> addOrEditRole([Map<String, dynamic>? role]) async {
    final nameController =
        TextEditingController(text: role?['name'] ?? role?['title'] ?? '');
    final isEdit = role != null;
    String? snackMessage;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Sửa vai trò' : 'Thêm vai trò'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên vai trò'),
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
              final name = nameController.text.trim();
              if (name.isEmpty) {
                snackMessage = 'Vui lòng nhập tên vai trò!';
                Navigator.pop(context);
                return;
              }
              final data = {
                'name': name,
              };
              final endpoint = isEdit
                  ? 'https://food-app-cweu.onrender.com/api/v1/roles/${role['id']}'
                  : 'https://food-app-cweu.onrender.com/api/v1/roles';
              final method = isEdit ? 'PUT' : 'POST';
              try {
                final request = http.Request(method, Uri.parse(endpoint))
                  ..headers['Content-Type'] = 'application/json'
                  ..body = jsonEncode(data);
                final streamed = await request.send();
                if (streamed.statusCode == 200 || streamed.statusCode == 201) {
                  snackMessage = isEdit ? 'Đã lưu!' : 'Đã thêm!';
                  Navigator.pop(context);
                  // Đợi một chút để backend cập nhật, sau đó reload danh sách
                  await Future.delayed(const Duration(milliseconds: 300));
                  await fetchRoles();
                } else {
                  snackMessage = 'Lỗi: ${streamed.statusCode}';
                  Navigator.pop(context);
                }
              } catch (e) {
                snackMessage = 'Lỗi: $e';
                Navigator.pop(context);
              }
            },
            child: Text(isEdit ? 'Lưu' : 'Thêm'),
          ),
        ],
      ),
    );
    if (snackMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snackMessage!)),
      );
    }
  }

  Future<void> deleteRole(Map<String, dynamic> role) async {
    final endpoint =
        'https://food-app-cweu.onrender.com/api/v1/roles/${role['id']}';
    try {
      final response = await http.delete(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        await fetchRoles();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa vai trò!')),
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
    fetchRoles();
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
                child: const Text('Quản Lý Phân Quyền',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm vai trò'),
                  onPressed: () => addOrEditRole(),
                ),
              ),
              Expanded(
                child: _apiMessage != null
                    ? Center(
                        child: Text(_apiMessage!,
                            style: const TextStyle(
                                fontSize: 18, color: Colors.orange)))
                    : _roles.isEmpty
                        ? const Center(child: Text('Không có vai trò!'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _roles.length,
                            itemBuilder: (context, i) {
                              final role = _roles[i];
                              return Card(
                                color: Colors.orange.shade100,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: const Icon(Icons.security,
                                      color: Colors.deepOrange, size: 40),
                                  title: Text(
                                      role['name'] ??
                                          role['title'] ??
                                          'Không tên',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange)),
                                  subtitle: null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        tooltip: 'Sửa',
                                        onPressed: () => addOrEditRole(role),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        tooltip: 'Xóa',
                                        onPressed: () async {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                  'Xác nhận xóa vai trò'),
                                              content: Text(
                                                  'Bạn có chắc chắn muốn xóa vai trò "${role['name'] ?? role['title'] ?? ''}"?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('Hủy'),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red),
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text('Xóa'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await deleteRole(role);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(role['name'] ??
                                            role['title'] ??
                                            'Không tên'),
                                        content: null,
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
          );
  }
}
