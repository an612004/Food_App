import 'package:flutter/material.dart';

class SidebarAdmin extends StatelessWidget {
  const SidebarAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Colors.blue.shade100,
      child: Column(
        children: [
          DrawerHeader(child: Text("Admin Panel")),
          ListTile(
            title: Text("Dashboard"),
            onTap: () => Navigator.pushNamed(context, '/admin'),
          ),
          ListTile(title: Text("Roles"), onTap: () {}),
          ListTile(title: Text("Products"), onTap: () {}),
        ],
      ),
    );
  }
}
