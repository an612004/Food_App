import 'package:flutter/material.dart';
import 'home.dart';
import 'trang_mon_an.dart';
import 'don_hang.dart';
import 'ho_so.dart' hide Icon;
import 'cart_page.dart';

class HomeUser extends StatefulWidget {
  const HomeUser({super.key});

  @override
  State<HomeUser> createState() => _HomeUserState();
}

class _HomeUserState extends State<HomeUser> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TrangHome(),
    const TrangMonAn(),
    const MonAnYeuThich(),
    const HoSo(),
  ];

  final List<String> _titles = [
    'Trang Chủ',
    'Món Ăn',
    'Đơn hàng',
    'Hồ Sơ',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.deepOrange),
              tooltip: 'Giỏ hàng',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
            ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _screens[_selectedIndex],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.shade100,
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.deepOrange,
            unselectedItemColor: Colors.orange.shade300,
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            showUnselectedLabels: true,
            iconSize: 32,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: _selectedIndex == 0
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.orange.shade200, blurRadius: 8)
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.home, color: Colors.deepOrange),
                      )
                    : const Icon(Icons.home),
                label: 'Trang Chủ',
              ),
              BottomNavigationBarItem(
                icon: _selectedIndex == 1
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.orange.shade200, blurRadius: 8)
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.restaurant,
                            color: Colors.deepOrange),
                      )
                    : const Icon(Icons.restaurant),
                label: 'Món Ăn',
              ),
              BottomNavigationBarItem(
                icon: _selectedIndex == 2
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.orange.shade200, blurRadius: 8)
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.receipt_long,
                            color: Colors.deepOrange),
                      )
                    : const Icon(Icons.receipt_long),
                label: 'Đơn hàng',
              ),
              BottomNavigationBarItem(
                icon: _selectedIndex == 3
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.orange.shade200, blurRadius: 8)
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child:
                            const Icon(Icons.person, color: Colors.deepOrange),
                      )
                    : const Icon(Icons.person),
                label: 'Hồ Sơ',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
