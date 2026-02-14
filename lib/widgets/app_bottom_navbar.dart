import 'package:flutter/material.dart';
import '../views/home/home_view.dart';
import '../views/settings/more_view.dart';
import '../views/earn/earn_view.dart';
import '../views/advertise/advert_selection_dialog.dart';
import '../views/advertise/advert_payment_view.dart'; // Make sure this import is correct
import '../views/market/market_view.dart';

class AppBottomNavigationBar extends StatefulWidget {
  const AppBottomNavigationBar({super.key});

  @override
  State<AppBottomNavigationBar> createState() => _AppBottomNavigationBarState();
}

class _AppBottomNavigationBarState extends State<AppBottomNavigationBar> {
  int _selectedIndex = 0;

  // Lazily create pages so they don't run initState before a tab is selected.
  final List<Widget?> _pages = List<Widget?>.filled(5, null);

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HomeView();
      case 1:
        return const EarnView();
      case 2:
        return const AdvertPaymentView();
      case 3:
        return const MarketView();
      case 4:
        return const MoreView();
      default:
        return const HomeView();
    }
  }

  void _ensurePage(int index) {
    _pages[index] ??= _buildPage(index);
  }

  @override
  void initState() {
    super.initState();
    _ensurePage(_selectedIndex);
  }

  // 2. UPDATE: Intercept the tap for Index 2
  void _onItemTapped(int index) {
    if (index == 2) {
      // If "Advertise" is clicked, show the dialog overlay
      showDialog(
        context: context,
        barrierColor: Colors.black54, // Dims the background
        builder:
            (context) => AdvertSelectionDialog(
              onNavigateToMarket: () {
                // Close the dialog first
                Navigator.pop(context);
                // THEN switch the tab to show the AdvertPaymentView
                setState(() {
                  _selectedIndex = 2;
                  _ensurePage(_selectedIndex);
                });
              },
            ),
      );
    } else {
      // Normal navigation for all other tabs
      setState(() {
        _selectedIndex = index;
        _ensurePage(_selectedIndex);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensurePage(_selectedIndex);
    final pages = List<Widget>.generate(
      5,
      (index) => _pages[index] ?? const SizedBox.shrink(),
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final navBarColor =
        theme.bottomNavigationBarTheme.backgroundColor ??
        theme.scaffoldBackgroundColor;
    final selectedColor =
        theme.bottomNavigationBarTheme.selectedItemColor ?? theme.primaryColor;
    final unselectedColor =
        theme.bottomNavigationBarTheme.unselectedItemColor ?? Colors.grey;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBarColor,
          boxShadow: [
            BoxShadow(
              color:
                  isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
              blurRadius: 10.0,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped, // This now uses our modified logic
          selectedItemColor: selectedColor,
          unselectedItemColor: unselectedColor,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: [
            _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
            _buildNavItem(Icons.toll_outlined, Icons.toll, 'Earn', 1),
            _buildNavItem(
              Icons.add_circle_outline,
              Icons.add_circle,
              'Advertise',
              2,
              large: true,
            ),
            _buildNavItem(Icons.store_outlined, Icons.store, 'Market', 3),
            _buildNavItem(Icons.list_alt, Icons.list_alt, 'More', 4),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index, {
    bool large = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (large) {
      return BottomNavigationBarItem(
        icon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color:
                _selectedIndex == index
                    ? Colors.red.shade600
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade400),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_circle, size: 32, color: Colors.white),
        ),
        label: label,
      );
    }

    return BottomNavigationBarItem(
      icon: Icon(icon, size: 24),
      activeIcon: Icon(activeIcon, size: 24),
      label: label,
    );
  }
}
