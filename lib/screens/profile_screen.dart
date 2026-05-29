import 'package:flutter/material.dart';

const _primary = Color(0xFF2E7D32);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            height: 200,
            color: _primary,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=User&background=fff&color=2E7D32'),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Guest User',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOption(Icons.history, 'Order History', () {}),
                _buildOption(Icons.location_on, 'Delivery Address', () {}),
                _buildOption(Icons.payment, 'Payment Methods', () {}),
                _buildOption(Icons.settings, 'Settings', () {}),
                _buildOption(Icons.help_outline, 'Help Center', () {}),
                const Divider(height: 30),
                _buildOption(Icons.logout, 'Log Out', () {}, Colors.red),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOption(IconData icon, String title, VoidCallback onTap, [Color? color]) {
    return ListTile(
      leading: Icon(icon, color: color ?? _primary),
      title: Text(title, style: TextStyle(color: color ?? Colors.black87)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}