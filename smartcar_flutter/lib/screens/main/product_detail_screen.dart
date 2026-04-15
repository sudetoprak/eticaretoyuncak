import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/models/models.dart';
import '../../services/products_service.dart';
import '../../services/cart_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final VoidCallback onBack;

  const ProductDetailScreen({super.key, required this.productId, required this.onBack});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _productsService = ProductsService();
  final _cartService = CartService();

  Product? _product;
  bool _loading = true;
  bool _adding = false;
  int _qty = 1;
  int _imgIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _productsService.get(widget.productId);
      if (mounted) setState(() => _product = p);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Ürün yüklenemedi.'), backgroundColor: Color(0xFFF87171)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addToCart() async {
    if (_product == null) return;
    setState(() => _adding = true);
    try {
      await _cartService.add(_product!.id, _qty);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_qty adet sepete eklendi.'),
            backgroundColor: const Color(0xFF34D399),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Sepete eklenemedi.'), backgroundColor: Color(0xFFF87171)),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }
    if (_product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ürün bulunamadı.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16)),
              TextButton(onPressed: widget.onBack, child: const Text('Geri')),
            ],
          ),
        ),
      );
    }

    final p = _product!;
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      if (p.images.isNotEmpty)
                        SizedBox(
                          height: 280,
                          child: PageView.builder(
                            itemCount: p.images.length,
                            onPageChanged: (i) => setState(() => _imgIndex = i),
                            itemBuilder: (_, i) => CachedNetworkImage(
                              imageUrl: p.images[i],
                              fit: BoxFit.cover,
                              width: screenW,
                              placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
                              errorWidget: (_, __, ___) => const Center(
                                  child: Text('🚗', style: TextStyle(fontSize: 80))),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 280,
                          width: double.infinity,
                          color: const Color(0xFF1E293B),
                          child: const Center(
                              child: Text('🚗', style: TextStyle(fontSize: 80))),
                        ),
                      Positioned(
                        top: 48,
                        left: 16,
                        child: GestureDetector(
                          onTap: widget.onBack,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('← Geri',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ],
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
                            width: i == _imgIndex ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _imgIndex
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A5F),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(p.category,
                                  style: const TextStyle(
                                      color: Color(0xFF60A5FA),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ),
                            Text(
                              p.stock > 0 ? 'Stok: ${p.stock}' : 'Stok Yok',
                              style: TextStyle(
                                  color: p.stock > 0
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFFF87171),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(p.name.tr,
                            style: const TextStyle(
                                color: Color(0xFFF1F5F9),
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(p.name.en,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                        const SizedBox(height: 16),
                        Text(
                          '${p.price.toStringAsFixed(2)} ${p.currency}',
                          style: const TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 28,
                              fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 20),
                        const Text('Açıklama',
                            style: TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(p.description.tr,
                            style: const TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 15, height: 1.6)),
                        if (p.tags.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: p.tags
                                .map((tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF334155)),
                                      ),
                                      child: Text('#$tag',
                                          style: const TextStyle(
                                              color: Color(0xFF60A5FA), fontSize: 12)),
                                    ))
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (p.stock > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(top: BorderSide(color: Color(0xFF334155))),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      children: [
                        _qtyBtn('−', () => setState(() => _qty = (_qty - 1).clamp(1, p.stock))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('$_qty',
                              style: const TextStyle(
                                  color: Color(0xFFF1F5F9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                        ),
                        _qtyBtn('+', () => setState(() => _qty = (_qty + 1).clamp(1, p.stock))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _adding ? null : _addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        disabledBackgroundColor: const Color(0xFF3B82F6).withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _adding
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Sepete Ekle',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _qtyBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 44,
          child: Center(
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFFF1F5F9), fontSize: 20, fontWeight: FontWeight.w700)),
          ),
        ),
      );
}
