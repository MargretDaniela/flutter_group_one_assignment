import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'cart_screen.dart';
import 'wishlist_screen.dart';
import 'profile_screen.dart';
import '../providers/app_provider.dart';

const _primary = Color(0xFF2E7D32);

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // List of screens
  final List<Widget> _screens = [
    const HomeScreen(),
    const WishlistScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    // Sync provider-driven navigation changes (e.g. from "Continue Shopping")
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (appProvider.currentIndex != _currentIndex) {
        setState(() {
          _currentIndex = appProvider.currentIndex;
        });
      }
    });

    return Scaffold(
      // IndexedStack keeps the state of screens alive
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          appProvider.changeIndex(index);
        },
        selectedItemColor: _primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: appProvider.wishlistCount > 0,
              label: Text('${appProvider.wishlistCount}'),
              child: const Icon(Icons.favorite_border),
            ),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: appProvider.cartCount > 0,
              label: Text('${appProvider.cartCount}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}