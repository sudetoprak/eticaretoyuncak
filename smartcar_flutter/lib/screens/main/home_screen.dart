import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/models/models.dart';
import '../../services/products_service.dart';
import '../../services/cart_service.dart';
import '../../services/orders_service.dart';
import 'control_screen.dart';

const _categories = ['Tümü', 'araba', 'parca', 'batarya'];

enum _HomeView { dashboard, joystick, shop }

Color _catColor(String category) {
  switch (category.toLowerCase()) {
    case 'araba':
      return const Color(0xFFEF4444);
    case 'batarya':
      return const Color(0xFF10B981);
    case 'parca':
      return const Color(0xFF3B82F6);
    default:
      return const Color(0xFFF59E0B);
  }
}

String _catLabel(String category) {
  switch (category.toLowerCase()) {
    case 'araba':
      return 'Araba';
    case 'batarya':
      return 'Batarya';
    case 'parca':
      return ' Parça';
    default:
      return category;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _productsService = ProductsService();
  final _cartService = CartService();

  _HomeView _view = _HomeView.dashboard;

  List<Product> _products = [];
  bool _loading = false;
  String _search = '';
  String _category = 'Tümü';
  String? _addingId;

  void _openShop() {
    setState(() => _view = _HomeView.shop);
    _fetch();
  }

  void _openJoystick() {
    setState(() => _view = _HomeView.joystick);
  }

  void _back() {
    setState(() => _view = _HomeView.dashboard);
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await _productsService.list(
        category: _category == 'Tümü' ? null : _category,
        search: _search.isEmpty ? null : _search,
      );
      if (mounted) setState(() => _products = data);
    } catch (_) {
      if (mounted) _snack('Ürünler yüklenemedi.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addToCart(String productId, {int qty = 1}) async {
    setState(() => _addingId = productId);
    try {
      await _cartService.add(productId, qty);
      if (mounted) _snack('Sepete eklendi!');
    } catch (_) {
      if (mounted) _snack('Sepete eklenemedi.', error: true);
    } finally {
      if (mounted) setState(() => _addingId = null);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showDetail(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(
        product: product,
        onAddToCart: (qty) {
          Navigator.pop(context);
          _addToCart(product.id, qty: qty);
        },
        onBuyNow: (qty) {
          Navigator.pop(context);
          _addToCart(product.id, qty: qty).then((_) {
            if (mounted) _showCheckout();
          });
        },
      ),
    );
  }

  void _showCheckout() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheckoutSheet(
        onSuccess: () {
          Navigator.pop(context);
          _snack('Siparişiniz alındı!');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_view) {
      case _HomeView.dashboard:
        return _buildDashboard();
      case _HomeView.joystick:
        return _buildJoystick();
      case _HomeView.shop:
        return _buildShop();
    }
  }

  Widget _buildDashboard() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hoş geldiniz',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
            const SizedBox(height: 4),
            const Text('SmartCar',
                style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
            const SizedBox(height: 40),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _DashCard(
                      icon: Icons.sports_esports,
                      title: 'Joystick',
                      subtitle: 'Arabayı kontrol et',
                      color: const Color(0xFF3B82F6),
                      borderColor: const Color(0xFFBFDBFE),
                      iconBg: const Color(0xFFDBEAFE),
                      onTap: _openJoystick,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _DashCard(
                      icon: Icons.storefront,
                      title: 'Mağaza',
                      subtitle: 'Ürünler, parcalar ve daha fazlası',
                      color: const Color(0xFF10B981),
                      borderColor: const Color(0xFFA7F3D0),
                      iconBg: const Color(0xFFD1FAE5),
                      onTap: _openShop,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoystick() {
    return Column(
      children: [
        _backBar('Joystick'),
        const Expanded(child: ControlScreen()),
      ],
    );
  }

  Widget _buildShop() {
    return Column(
      children: [
        _backBar('Mağaza'),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: TextField(
            onChanged: (v) {
              _search = v;
              _fetch();
            },
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ürün ara...',
              hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFB0BEC5), size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final active = _category == cat;
              final color = cat == 'Tümü' ? const Color(0xFF3B82F6) : _catColor(cat);
              return GestureDetector(
                onTap: () {
                  setState(() => _category = cat);
                  _fetch();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? color : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: active ? color : const Color(0xFFE2E8F0), width: 1.5),
                    boxShadow: active
                        ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))]
                        : [],
                  ),
                  child: Text(cat == 'Tümü' ? 'Tümü' : _catLabel(cat),
                      style: TextStyle(
                          color: active ? Colors.white : const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
              : _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('Ürün bulunamadı',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF3B82F6),
                      onRefresh: _fetch,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (_, i) => _ProductGridCard(
                          product: _products[i],
                          isAdding: _addingId == _products[i].id,
                          onDetail: () => _showDetail(_products[i]),
                          onAddToCart: () => _addToCart(_products[i].id),
                          onBuyNow: () => _addToCart(_products[i].id)
                              .then((_) => mounted ? _showCheckout() : null),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _backBar(String title) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Color(0xFF64748B), size: 18),
            ),
            Text(title,
                style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

// ─── Dashboard Card ───────────────────────────────────────────────────────────

class _DashCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color borderColor;
  final Color iconBg;
  final VoidCallback onTap;

  const _DashCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.borderColor,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBg,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─── Joystick Placeholder ─────────────────────────────────────────────────────

class _JoystickPlaceholder extends StatelessWidget {
  const _JoystickPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF1F5F9),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 2, height: 80, color: const Color(0xFFCBD5E1)),
              Container(width: 80, height: 2, color: const Color(0xFFCBD5E1)),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
                  boxShadow: const [BoxShadow(color: Color(0x1A3B82F6), blurRadius: 8)],
                ),
                child: const Icon(Icons.gamepad_outlined,
                    color: Color(0xFF3B82F6), size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('Joystick',
            style: TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Yakında',
            style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 11)),
        const SizedBox(height: 24),
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            children: [
              _miniBtn('▲', top: 0, left: 35),
              _miniBtn('▼', bottom: 0, left: 35),
              _miniBtn('◀', top: 35, left: 0),
              _miniBtn('▶', top: 35, right: 0),
              Positioned(
                top: 38,
                left: 38,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFEE2E2),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Center(
                    child: Text('■',
                        style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniBtn(String icon,
          {double? top, double? bottom, double? left, double? right}) =>
      Positioned(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)],
          ),
          child: Center(
            child: Text(icon,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
          ),
        ),
      );
}

// ─── Product Grid Card ────────────────────────────────────────────────────────

class _ProductGridCard extends StatelessWidget {
  final Product product;
  final bool isAdding;
  final VoidCallback onDetail;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  const _ProductGridCard({
    required this.product,
    required this.isAdding,
    required this.onDetail,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final color = _catColor(product.category);

    return GestureDetector(
      onTap: onDetail,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              width: double.infinity,
              color: color.withOpacity(0.1),
              child: product.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.images[0],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Center(
                          child: CircularProgressIndicator(
                              color: color, strokeWidth: 2)),
                      errorWidget: (_, __, ___) => Center(
                          child: Icon(Icons.directions_car,
                              color: color.withOpacity(0.5), size: 40)),
                    )
                  : Center(
                      child: Icon(Icons.directions_car,
                          color: color.withOpacity(0.5), size: 40),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(_catLabel(product.category),
                          style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 5),
                    Text(product.name.tr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.3)),
                    const SizedBox(height: 4),
                    Text(
                      '${product.price.toStringAsFixed(2)} ${product.currency}',
                      style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 13,
                          fontWeight: FontWeight.w800),
                    ),
                    if (product.stock > 0 && product.stock <= 5)
                      Text('Son ${product.stock} ürün!',
                          style: const TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 9,
                              fontWeight: FontWeight.w600)),
                    if (product.stock == 0)
                      const Text('Stok Yok',
                          style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 9,
                              fontWeight: FontWeight.w600)),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: product.stock == 0
                            ? null
                            : (isAdding ? null : onAddToCart),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: product.stock == 0
                                ? const Color(0xFFE2E8F0)
                                : color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: isAdding
                              ? const Center(
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_shopping_cart,
                                        color: Colors.white, size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      product.stock == 0 ? 'Stok Yok' : 'Sepete Ekle',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Product Detail Bottom Sheet ──────────────────────────────────────────────

class _ProductDetailSheet extends StatefulWidget {
  final Product product;
  final void Function(int qty) onAddToCart;
  final void Function(int qty) onBuyNow;

  const _ProductDetailSheet({
    required this.product,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  int _qty = 1;
  int _imgIndex = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final color = _catColor(p.category);
    final screenW = MediaQuery.of(context).size.width;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.images.isNotEmpty)
                      SizedBox(
                        height: 220,
                        child: PageView.builder(
                          itemCount: p.images.length,
                          onPageChanged: (i) => setState(() => _imgIndex = i),
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: p.images[i],
                            fit: BoxFit.cover,
                            width: screenW,
                            placeholder: (_, __) => Center(
                                child: CircularProgressIndicator(color: color)),
                            errorWidget: (_, __, ___) => Container(
                              color: color.withOpacity(0.08),
                              child: Center(
                                  child: Icon(Icons.directions_car,
                                      color: color.withOpacity(0.4), size: 64)),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 180,
                        color: color.withOpacity(0.08),
                        child: Center(
                            child: Icon(Icons.directions_car,
                                color: color.withOpacity(0.4), size: 64)),
                      ),
                    if (p.images.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            p.images.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _imgIndex ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i == _imgIndex ? color : const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: color.withOpacity(0.3)),
                                ),
                                child: Text(_catLabel(p.category),
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: p.stock > 0
                                      ? const Color(0xFFD1FAE5)
                                      : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  p.stock > 0 ? 'Stok: ${p.stock}' : 'Stok Yok',
                                  style: TextStyle(
                                      color: p.stock > 0
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFEF4444),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(p.name.tr,
                              style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(p.name.en,
                              style: const TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 13)),
                          const SizedBox(height: 12),
                          Text(
                            '${p.price.toStringAsFixed(2)} ${p.currency}',
                            style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 26,
                                fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 16),
                          const Text('Açıklama',
                              style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(p.description.tr,
                              style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 14,
                                  height: 1.6)),
                          if (p.tags.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: p.tags
                                  .map((t) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                              color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Text('#$t',
                                            style: const TextStyle(
                                                color: Color(0xFF3B82F6),
                                                fontSize: 11)),
                                      ))
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (p.stock > 0)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          _qtyBtn('−',
                              () => setState(
                                  () => _qty = (_qty - 1).clamp(1, p.stock))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('$_qty',
                                style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                          ),
                          _qtyBtn('+',
                              () => setState(
                                  () => _qty = (_qty + 1).clamp(1, p.stock))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onAddToCart(_qty),
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: const Text('Sepete Ekle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onBuyNow(_qty),
                        icon: const Icon(Icons.payments_outlined, size: 16),
                        label: const Text('Satın Al'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 40,
          child: Center(
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      );
}

// ─── Checkout Bottom Sheet ────────────────────────────────────────────────────

class _CheckoutSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  const _CheckoutSheet({required this.onSuccess});

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'Türkiye');
  final _zipCtrl = TextEditingController();
  String _payment = 'credit_card';
  bool _loading = false;

  final _service = OrdersService();

  Future<void> _place() async {
    if (_streetCtrl.text.trim().isEmpty ||
        _cityCtrl.text.trim().isEmpty ||
        _zipCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adres bilgilerini doldurun.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _service.create(
        shippingAddress: Address(
          street: _streetCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          country: _countryCtrl.text.trim(),
          zip: _zipCtrl.text.trim(),
        ),
        paymentMethod: _payment,
      );
      widget.onSuccess();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sipariş verilemedi.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Teslimat & Ödeme',
                  style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _field('Sokak *', _streetCtrl, 'Atatürk Cad. No:5'),
              _field('Şehir *', _cityCtrl, 'İstanbul'),
              _field('Ülke', _countryCtrl, 'Türkiye'),
              _field('Posta Kodu *', _zipCtrl, '34000',
                  keyboard: TextInputType.number),
              const SizedBox(height: 16),
              const Text('Ödeme Yöntemi',
                  style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ...[
                ('credit_card', 'Kredi Kartı', Icons.credit_card),
                ('bank_transfer', 'Havale / EFT', Icons.account_balance),
                ('cash_on_delivery', 'Kapıda Ödeme', Icons.local_shipping),
              ].map((o) => _payOpt(o.$1, o.$2, o.$3)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _place,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    disabledBackgroundColor: const Color(0xFF3B82F6).withAlpha(100),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Siparişi Onayla',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint,
          {TextInputType keyboard = TextInputType.text}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          TextField(
            controller: ctrl,
            keyboardType: keyboard,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ],
      );

  Widget _payOpt(String id, String label, IconData icon) => GestureDetector(
        onTap: () => setState(() => _payment = id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _payment == id ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: _payment == id
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFE2E8F0),
                width: _payment == id ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: _payment == id
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF94A3B8)),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                      color: _payment == id
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_payment == id)
                const Icon(Icons.check_circle,
                    color: Color(0xFF3B82F6), size: 18),
            ],
          ),
        ),
      );

  @override
  void dispose() {
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }
}