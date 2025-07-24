import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  bool _validate() {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if ([name, address, phone, email, password].any((e) => e.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin!')),
      );
      return false;
    }
    // Kiểm tra tên chỉ chứa chữ cái, không có số/ký tự đặc biệt, tối thiểu 3 ký tự
    if (!RegExp(r'^[a-zA-ZÀ-ỹ\s]{3,}$').hasMatch(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tên chỉ được nhập chữ cái và tối thiểu 3 ký tự!')),
      );
      return false;
    }
    if (!RegExp(r'^(0\d{9}|\+84\d{9})$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Số điện thoại phải bắt đầu bằng 0 (10 số) hoặc +84 (12 số)!')),
      );
      return false;
    }
    if (!email.endsWith('@gmail.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email phải đúng định dạng @gmail.com!')),
      );
      return false;
    }
    // Kiểm tra mật khẩu mạnh: >=6 ký tự, có chữ hoa, chữ thường, số, ký tự đặc biệt
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{6,}$')
        .hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Mật khẩu phải từ 6 ký tự, gồm chữ hoa, chữ thường, số và ký tự đặc biệt!')),
      );
      return false;
    }
    return true;
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    final isValid = _validate();
    if (!isValid) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    // Chuẩn hóa số điện thoại: chỉ nhận 09xxxxxxxx hoặc +849xxxxxxxx
    String inputPhone =
        _phoneController.text.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    String cleanPhone = '';
    if (RegExp(r'^09\d{8}').hasMatch(inputPhone)) {
      cleanPhone = '+84' + inputPhone.substring(1);
    } else if (RegExp(r'^\+849\d{8}').hasMatch(inputPhone)) {
      cleanPhone = inputPhone;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Số điện thoại phải bắt đầu bằng 09 (10 số) hoặc +849 (12 số)!')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    // Giữ nguyên tên đã validate, không loại bỏ ký tự hợp lệ
    final cleanName = _nameController.text.trim();
    final body = jsonEncode({
      'fullName': cleanName,
      'address': _addressController.text.trim(),
      'phone': cleanPhone,
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
    });
    debugPrint('Register body: ' + body);
    try {
      final response = await http.post(
        Uri.parse('https://food-app-cweu.onrender.com/api/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      debugPrint('Register response: ' + response.body);
      if (!mounted) return;
      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đăng ký thành công! Vui lòng đăng nhập.')),
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        String msg = 'Đăng ký thất bại!';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data.containsKey('message')) {
            msg = data['message'].toString();
          } else if (data is String) {
            msg = data;
          }
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
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
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Họ và Tên',
                prefixIcon: const Icon(Icons.person, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Địa chỉ',
                prefixIcon: const Icon(Icons.home, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: const Icon(Icons.phone, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Gmail',
                prefixIcon: const Icon(Icons.email, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.orange,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Đăng ký',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Đã có tài khoản?'),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Đăng nhập',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
