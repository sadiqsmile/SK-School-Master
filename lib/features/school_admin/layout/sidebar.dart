import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: const [
          DrawerHeader(child: Text('School Admin')),
          ListTile(title: Text('Dashboard')),
          ListTile(title: Text('Teachers')),
          ListTile(title: Text('Students')),
          ListTile(title: Text('Classes')),
        ],
      ),
    );
  }
}
