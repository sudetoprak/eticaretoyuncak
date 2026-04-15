import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main/home_screen.dart';
import 'screens/main/cart_screen.dart';
import 'screens/main/checkout_screen.dart';
import 'screens/main/profile_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const SmartCarApp(),
    ),
  );
}

class SmartCarApp extends StatelessWidget {
  const SmartCarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartCar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF3B82F6),
          surface: Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Roboto',
      ),
      home: const _RootWidget(),
    );
  }
}

// ─── Root ─────────────────────────────────────────────────────────────────────

class _RootWidget extends StatelessWidget {
  const _RootWidget();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }

    return auth.isAuthenticated ? const _MainTabs() : const _AuthFlow();
  }
}

// ─── Auth Flow ────────────────────────────────────────────────────────────────

class _AuthFlow extends StatefulWidget {
  const _AuthFlow();

  @override
  State<_AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<_AuthFlow> {
  bool _showRegister = false;

  @override
  Widget build(BuildContext context) {
    if (_showRegister) {
      return RegisterScreen(onGoLogin: () => setState(() => _showRegister = false));
    }
    return LoginScreen(onGoRegister: () => setState(() => _showRegister = true));
  }
}

// ─── Main Tabs ────────────────────────────────────────────────────────────────

class _MainTabs extends StatefulWidget {
  const _MainTabs();

  @override
  State<_MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<_MainTabs> {
  int _tabIndex = 0;
  Key _cartKey = UniqueKey();

  static const _titles = ['Ana Sayfa', 'Sepet', 'Profil'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0xFFE2E8F0),
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_car, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              _titles[_tabIndex],
              style: const TextStyle(
                  color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _ShopFlow(),
          _CartFlow(key: _cartKey),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (i) => setState(() {
            if (i == 1) _cartKey = UniqueKey(); // Sepete her geçişte yenile
            _tabIndex = i;
          }),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF3B82F6),
          unselectedItemColor: const Color(0xFFB0BEC5),
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Ana Sayfa'),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined),
                activeIcon: Icon(Icons.shopping_cart),
                label: 'Sepet'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

// ─── Shop Flow ────────────────────────────────────────────────────────────────

class _ShopFlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const HomeScreen();
}

// ─── Cart Flow ────────────────────────────────────────────────────────────────

class _CartFlow extends StatefulWidget {
  const _CartFlow({super.key});
  @override
  State<_CartFlow> createState() => _CartFlowState();
}

class _CartFlowState extends State<_CartFlow> {
  bool _checkout = false;

  @override
  Widget build(BuildContext context) {
    if (_checkout) {
      return CheckoutScreen(
        onBack: () => setState(() => _checkout = false),
        onSuccess: () => setState(() => _checkout = false),
      );
    }
    return CartScreen(onCheckout: () => setState(() => _checkout = true));
  }
}
