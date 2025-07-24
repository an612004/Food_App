import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../Page login/login_screen.dart';

class HoSo extends StatefulWidget {
  const HoSo({super.key});

  @override
  State<HoSo> createState() => _HoSoState();
}

class _HoSoState extends State<HoSo> {
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _user;
  final Map<String, TextEditingController> _controllers = {};

  Future<void> fetchUser() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      debugPrint('Token: $token');
      // Giải mã userId từ token JWT
      String? userId;
      if (token.isNotEmpty) {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload =
              utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
          final payloadMap = jsonDecode(payload);
          userId = payloadMap['userId']?.toString();
        }
      }
      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy userId trong token!')),
        );
        setState(() => _loading = false);
        return;
      }
      final endpoint =
          'https://food-app-cweu.onrender.com/api/v1/users/$userId';
      final response = await http.get(
        Uri.parse(endpoint),
        headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : {},
      );
      debugPrint('API response: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('User data: ${data['data']}');
        _user = data['data'] ?? {};
        // Tạo controller cho tất cả các trường
        _controllers.clear();
        _user?.forEach((key, value) {
          _controllers[key] =
              TextEditingController(text: value?.toString() ?? '');
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lấy thông tin: $e')),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> saveUser() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    // Giải mã userId từ token JWT
    String? userId;
    if (token.isNotEmpty) {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload =
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        final payloadMap = jsonDecode(payload);
        userId = payloadMap['userId']?.toString();
      }
    }
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy userId trong token!')),
      );
      setState(() => _saving = false);
      return;
    }
    final endpoint = 'https://food-app-cweu.onrender.com/api/v1/users/$userId';
    // Chỉ gửi các trường có giá trị khác rỗng cho API
    final Map<String, dynamic> bodyMap = {};
    if (_controllers['fullName'] != null &&
        _controllers['fullName']!.text.trim().isNotEmpty) {
      bodyMap['fullName'] = _controllers['fullName']!.text.trim();
    }
    if (_controllers['phone'] != null &&
        _controllers['phone']!.text.trim().isNotEmpty) {
      bodyMap['phone'] = _controllers['phone']!.text.trim();
    }
    if (_controllers['gender'] != null &&
        _controllers['gender']!.text.trim().isNotEmpty) {
      bodyMap['gender'] = _controllers['gender']!.text.trim();
    }
    final body = jsonEncode(bodyMap);
    try {
      final response = await http.patch(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: body,
      );
      debugPrint('PATCH response: ${response.body}');
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công!')),
        );
        await fetchUser();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${response.statusCode}')),
        );
        // Nếu lỗi, reset lại dữ liệu từ server
        await fetchUser();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
      // Nếu lỗi, reset lại dữ liệu từ server
      await fetchUser();
    }
    setState(() => _saving = false);
  }

  Future<void> deleteUser() async {
    final endpoint = 'https://food-app-cweu.onrender.com/api/v1/users/me';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa tài khoản'),
        content: const Text('Bạn có chắc chắn muốn xóa tài khoản này?'),
        actions: [
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final response = await http.delete(
        Uri.parse(endpoint),
        headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : {},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa tài khoản!')),
        );
        // Chuyển về màn hình đăng nhập
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xóa: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    // Hiện gmail, không cho sửa
    if (_controllers['email'] != null) {
      children.add(TextField(
        controller: _controllers['email'],
        decoration: InputDecoration(
          labelText: 'Gmail',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        readOnly: true,
      ));
      children.add(SizedBox(height: 16));
    }
    // Hiện thị fullName nếu có
    if (_controllers['fullName'] != null) {
      children.add(TextField(
        controller: _controllers['fullName'],
        decoration: InputDecoration(
          labelText: 'Họ và tên',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ));
      children.add(SizedBox(height: 16));
    }
    // Hiện ngày tạo
    if (_controllers['createdAt'] != null) {
      children.add(TextField(
        controller: _controllers['createdAt'],
        decoration: InputDecoration(
          labelText: 'Ngày tạo',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        readOnly: true,
      ));
      children.add(SizedBox(height: 16));
    }
    // Hiện ngày cập nhật
    if (_controllers['updatedAt'] != null) {
      children.add(TextField(
        controller: _controllers['updatedAt'],
        decoration: InputDecoration(
          labelText: 'Ngày cập nhật',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        readOnly: true,
      ));
      children.add(SizedBox(height: 24));
    }
    // Hiện thị tên đăng nhập
    if (_controllers['userName'] != null) {
      children.add(TextField(
        controller: _controllers['userName'],
        decoration: InputDecoration(
          labelText: 'Tên đăng nhập',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ));
      children.add(SizedBox(height: 16));
    } else if (_controllers['username'] != null) {
      children.add(TextField(
        controller: _controllers['username'],
        decoration: InputDecoration(
          labelText: 'Tên đăng nhập',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ));
      children.add(SizedBox(height: 16));
    } else if (_controllers['tenDangNhap'] != null) {
      children.add(TextField(
        controller: _controllers['tenDangNhap'],
        decoration: InputDecoration(
          labelText: 'Tên đăng nhập',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ));
      children.add(SizedBox(height: 16));
    }
    // Hiện thị tên
    if (_controllers['name'] != null) {
      children.add(TextField(
        controller: _controllers['name'],
        decoration: InputDecoration(
          labelText: 'Tên',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ));
      children.add(SizedBox(height: 16));
    }
    // Hiện thị số điện thoại
    if (_controllers['phone'] != null) {
      children.add(TextField(
        controller: _controllers['phone'],
        decoration: InputDecoration(
          labelText: 'Số điện thoại',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ));
      children.add(SizedBox(height: 16));
    }
    // Hiện thị trạng thái
    if (_controllers['status'] != null) {
      children.add(TextField(
        controller: _controllers['status'],
        decoration: InputDecoration(
          labelText: 'Trạng thái',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ));
      children.add(SizedBox(height: 16));
    }
    // Hiện giới tính
    if (_controllers['gender'] != null) {
      children.add(TextField(
        controller: _controllers['gender'],
        decoration: InputDecoration(
          labelText: 'Giới tính',
        ),
      ));
      children.add(SizedBox(height: 16));
    }
    // Hiện thị địa chỉ (ưu tiên address, nếu không có thì diaChi, nếu không có thì location)
    if (_controllers['address'] != null) {
      children.add(TextField(
        controller: _controllers['address'],
        decoration: InputDecoration(
          labelText: 'Địa chỉ',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ));
      children.add(SizedBox(height: 16));
    } else if (_controllers['diaChi'] != null) {
      children.add(TextField(
        controller: _controllers['diaChi'],
        decoration: InputDecoration(
          labelText: 'Địa chỉ',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ));
      children.add(SizedBox(height: 16));
    } else if (_controllers['location'] != null) {
      children.add(TextField(
        controller: _controllers['location'],
        decoration: InputDecoration(
          labelText: 'Địa chỉ',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ));
      children.add(SizedBox(height: 16));
    }
    // Nút lưu hồ sơ
    children.add(Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            icon: _saving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Icon(Icons.save, color: Colors.white),
            label: Text('Lưu hồ sơ',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            onPressed: _saving ? null : saveUser,
          ),
        ),
      ],
    ));
    // Nút đăng xuất
    children.add(SizedBox(height: 16));
    children.add(Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            icon: Icon(Icons.logout, color: Colors.white),
            label: Text('Đăng xuất',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Xác nhận đăng xuất'),
                  content: Text('Bạn có chắc chắn muốn đăng xuất?'),
                  actions: [
                    TextButton(
                      child: Text('Hủy'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text('Đăng xuất',
                          style: TextStyle(color: Colors.white)),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('token');
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ),
      ],
    ));
    return Scaffold(
      appBar: AppBar(title: Text('Hồ sơ người dùng')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
    );
  }
}
