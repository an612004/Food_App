import 'package:flutter/material.dart';
import 'quan_ly_nguoi_dung.dart';
import 'quan_ly_don_hang.dart';
import 'quan_ly_mon_an.dart';
import 'quan_ly_voucher.dart';
import 'quan_ly_thong_ke.dart';
import 'quan_ly_phan_quyen.dart';
import '../Page login/login_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    QuanLyNguoiDung(),
    QuanLyDonHang(),
    QuanLyMonAn(),
    QuanLyVoucher(),
    QuanLyThongKe(),
    QuanLyPhanQuyen(),
  ];

  final List<String> _titles = [
    'Quản lý Người Dùng',
    'Quản lý Đơn Hàng',
    'Quản lý Món Ăn',
    'Quản lý Voucher',
    'Thống Kê',
    'Phân Quyền',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          Row(
            children: [
              Text(
                'Admin',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 10),
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Đăng xuất',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Xác nhận đăng xuất'),
                      content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Hủy'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Đăng xuất'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  }
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Người Dùng'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Đơn Hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: 'Món Ăn'),
          BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard), label: 'Voucher'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Thống Kê'),
          BottomNavigationBarItem(
              icon: Icon(Icons.security), label: 'Phân Quyền'),
        ],
      ),
    );
  }
}
