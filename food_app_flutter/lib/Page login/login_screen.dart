import 'package:flutter/material.dart';
import 'package:food_app_flutter/services/auth_service.dart';
import 'register_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages_user/home_user.dart';
import '../admin/admin_home.dart';
// import '../admin/quan_ly_nguoi_dung.dart';
import '../admin/quan_ly_thong_ke.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Trạng thái hiển thị form reset password trên giao diện
  bool _showForgotPassword = false;
  int _forgotStep = 0; // 0: nhập email, 1: nhập mã, 2: nhập mật khẩu mới
  String _resetEmail = '';
  final TextEditingController _forgotEmailController = TextEditingController();
  final TextEditingController _resetCodeController = TextEditingController();
  final TextEditingController _resetPasswordController =
      TextEditingController();
  final TextEditingController _resetConfirmController = TextEditingController();

  Future<void> _sendForgotPasswordEmail() async {
    final email = _forgotEmailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email!')),
      );
      return;
    }
    try {
      final response = await http.post(
        Uri.parse(
            'https://food-app-cweu.onrender.com/api/v1/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _forgotStep = 1;
          _resetEmail = email;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Đã gửi email đặt lại mật khẩu! Vui lòng kiểm tra email để lấy mã xác thực.')),
        );
      } else {
        String errorMsg = 'Lỗi: ${response.statusCode}';
        try {
          final err = jsonDecode(response.body);
          if (err is Map && err['message'] != null) {
            errorMsg = err['message'].toString();
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _verifyCode() async {
    final code = _resetCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã xác thực!')),
      );
      return;
    }
    try {
      final response = await http.post(
        Uri.parse(
            'https://food-app-cweu.onrender.com/api/v1/auth/verify-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _resetEmail, 'code': code}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _forgotStep = 2;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Mã xác thực đúng. Vui lòng nhập mật khẩu mới!')),
        );
      } else {
        String errorMsg = 'Mã xác thực không đúng!';
        try {
          final err = jsonDecode(response.body);
          if (err is Map && err['message'] != null) {
            errorMsg = err['message'].toString();
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _resetPassword() async {
    final pass = _resetPasswordController.text.trim();
    final confirm = _resetConfirmController.text.trim();
    if (pass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ thông tin!')),
      );
      return;
    }
    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu nhập lại không khớp!')),
      );
      return;
    }
    try {
      final response = await http.post(
        Uri.parse(
            'https://food-app-cweu.onrender.com/api/v1/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _resetEmail,
          'code': _resetCodeController.text.trim(),
          'newPassword': pass,
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt lại mật khẩu thành công!')),
        );
        setState(() {
          _showForgotPassword = false;
          _forgotStep = 0;
        });
      } else {
        String errorMsg = 'Lỗi: ${response.statusCode}';
        try {
          final err = jsonDecode(response.body);
          if (err is Map && err['message'] != null) {
            errorMsg = err['message'].toString();
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _showResetPasswordDialog(String email) async {
    final codeController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    String? snackMessage;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Đặt lại mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration:
                  const InputDecoration(labelText: 'Mã xác thực (code)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Nhập lại mật khẩu mới'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Đặt lại'),
            onPressed: () async {
              final code = codeController.text.trim();
              final pass = passwordController.text.trim();
              final confirm = confirmController.text.trim();
              if (code.isEmpty || pass.isEmpty || confirm.isEmpty) {
                snackMessage = 'Vui lòng nhập đủ thông tin!';
                Navigator.pop(context);
                return;
              }
              if (pass != confirm) {
                snackMessage = 'Mật khẩu nhập lại không khớp!';
                Navigator.pop(context);
                return;
              }
              try {
                final response = await http.post(
                  Uri.parse(
                      'https://food-app-cweu.onrender.com/api/v1/auth/reset-password'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'email': email,
                    'code': code,
                    'newPassword': pass,
                  }),
                );
                if (response.statusCode == 200) {
                  snackMessage = 'Đặt lại mật khẩu thành công!';
                } else {
                  String errorMsg = 'Lỗi: ${response.statusCode}';
                  try {
                    final err = jsonDecode(response.body);
                    if (err is Map && err['message'] != null) {
                      errorMsg = err['message'].toString();
                    }
                  } catch (_) {}
                  snackMessage = errorMsg;
                }
              } catch (e) {
                snackMessage = 'Lỗi: $e';
              }
              Navigator.pop(context);
            },
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

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng nhập đầy đủ email và mật khẩu!')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('https://food-app-cweu.onrender.com/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Login response: ${response.body}');
        // In ra toàn bộ data để kiểm tra cấu trúc
        debugPrint('Login data: $data');
        var user = data['data'];
        // Thử lấy token từ nhiều trường phổ biến
        String? accessToken = '';
        if (data['accessToken'] != null)
          accessToken = data['accessToken'];
        else if (data['token'] != null)
          accessToken = data['token'];
        else if (user?['accessToken'] != null)
          accessToken = user?['accessToken'];
        else if (user?['token'] != null) accessToken = user?['token'];
        debugPrint('AccessToken to save: $accessToken');
        if (accessToken != null && accessToken.toString().isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', accessToken.toString());
        }
        if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng nhập thành công!')),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          // Lấy role từ user object, có thể là 'role', 'userRole', hoặc 'type'
          final role =
              user['role'] ?? user['userRole'] ?? user['type'] ?? 'user';
          // ...existing code...
          if (role == 'admin') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const QuanLyThongKe()));
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeUser()),
            );
          }
// ...existing code...
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Không tìm thấy thông tin người dùng!')),
          );
        }
      } else {
        String errorMessage = 'Đăng nhập thất bại: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          } else if (response.statusCode == 401) {
            errorMessage = 'Sai email hoặc mật khẩu.';
          } else if (response.statusCode == 404) {
            errorMessage = 'Tài khoản không tồn tại hoặc chưa đăng ký.';
          }
        } catch (_) {
          // Nếu không parse được JSON thì giữ nguyên errorMessage
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 60),
        child: !_showForgotPassword
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Đăng Nhập KFC FOOD',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Email Field
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email, color: Colors.orange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật Khẩu',
                      prefixIcon: const Icon(Icons.lock, color: Colors.orange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
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
                  const SizedBox(height: 20),
                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _showForgotPassword = true;
                                _forgotStep = 0;
                                _forgotEmailController.clear();
                                _resetCodeController.clear();
                                _resetPasswordController.clear();
                                _resetConfirmController.clear();
                              });
                            },
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Login Button
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
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Đăng Nhập',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Google Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/4/4a/Logo_2013_Google.png',
                        height: 24,
                      ),
                      label: const Text(
                        'Đăng nhập bằng Google',
                        style: TextStyle(
                            color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final user = await AuthService().signInWithGoogle();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HomeUser()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Bạn chưa có tài khoản?'),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Đăng ký',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Quên mật khẩu',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_forgotStep == 0) ...[
                    TextField(
                      controller: _forgotEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Nhập email đã đăng ký',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange),
                        child: const Text('Gửi mã xác thực'),
                        onPressed: _sendForgotPasswordEmail,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showForgotPassword = false;
                          _forgotStep = 0;
                        });
                      },
                      child: const Text('Quay lại đăng nhập'),
                    ),
                  ] else if (_forgotStep == 1) ...[
                    Text('Nhập mã xác thực đã gửi về email: $_resetEmail',
                        style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _resetCodeController,
                      decoration: const InputDecoration(
                          labelText: 'Mã xác thực (code)',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange),
                        child: const Text('Xác thực mã'),
                        onPressed: _verifyCode,
                      ),
                    ),
                    const SizedBox(height: 12), // Spacing added
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton(
                        onPressed: () {
                          // Gửi lại mã xác thực về email đã nhập
                          _forgotEmailController.text = _resetEmail;
                          _sendForgotPasswordEmail();
                        },
                        child: const Text('Gửi lại mã',
                            style: TextStyle(color: Colors.orange)),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showForgotPassword = false;
                          _forgotStep = 0;
                        });
                      },
                      child: const Text('Quay lại đăng nhập'),
                    ),
                  ] else if (_forgotStep == 2) ...[
                    Text('Nhập mật khẩu mới cho tài khoản: $_resetEmail',
                        style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _resetPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Mật khẩu mới',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _resetConfirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Nhập lại mật khẩu mới',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange),
                            child: const Text('Đặt lại mật khẩu'),
                            onPressed: _resetPassword,
                          ),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showForgotPassword = false;
                              _forgotStep = 0;
                            });
                          },
                          child: const Text('Quay lại đăng nhập'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
