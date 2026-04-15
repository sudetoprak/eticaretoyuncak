import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/models/models.dart';
import '../../services/cart_service.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback onCheckout;
  const CartScreen({super.key, required this.onCheckout});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _service = CartService();
  Cart? _cart;
  bool _loading = true;
  String? _removing;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await _service.get();
      if (mounted) setState(() => _cart = data);
    } catch (_) {
      if (mounted) _showError('Sepet yüklenemedi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(String productId) async {
    setState(() => _removing = productId);
    try {
      await _service.remove(productId);
      await _fetch();
    } catch (_) {
      if (mounted) _showError('Ürün kaldırılamadı.');
    } finally {
      if (mounted) setState(() => _removing = null);
    }
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sepeti Temizle',
            style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800)),
        content: const Text('Tüm ürünler silinecek, emin misiniz?',
            style: TextStyle(color: Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal',
                style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.clear();
                await _fetch();
              } catch (_) {
                if (mounted) _showError('Sepet temizlenemedi.');
              }
            },
            child: const Text('Temizle',
                style: TextStyle(
                    color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
    }

    final isEmpty = _cart == null || _cart!.items.isEmpty;

    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🛒', style: TextStyle(fontSize: 44)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Sepetiniz boş',
                style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Ürün eklemek için mağazaya göz atın',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart,
                      color: Color(0xFF3B82F6), size: 18),
                  const SizedBox(width: 8),
                  Text('${_cart!.items.length} ürün',
                      style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              GestureDetector(
                onTap: _clearCart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Temizle',
                      style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF3B82F6),
            onRefresh: _fetch,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _cart!.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _CartItemTile(
                item: _cart!.items[i],
                isRemoving: _removing == _cart!.items[i].productId,
                onRemove: () => _remove(_cart!.items[i].productId),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Toplam',
                      style: TextStyle(
                          color: Color(0xFF64748B), fontSize: 16)),
                  Text(
                    '${_cart!.total.toStringAsFixed(2)} TRY',
                    style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 22,
                        fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                    shadowColor:
                        const Color(0xFF3B82F6).withOpacity(0.4),
                  ),
                  child: const Text('Siparişi Tamamla →',
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
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final bool isRemoving;
  final VoidCallback onRemove;

  const _CartItemTile(
      {required this.item,
      required this.isRemoving,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            color: const Color(0xFFF1F5F9),
            child: item.image != null
                ? CachedNetworkImage(
                    imageUrl: item.image!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.directions_car,
                            color: Color(0xFFCBD5E1), size: 32)))
                : const Center(
                    child: Icon(Icons.directions_car,
                        color: Color(0xFFCBD5E1), size: 32)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name.tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${item.quantity} adet',
                      style: const TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('${item.subtotal.toStringAsFixed(2)} TRY',
                      style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: isRemoving ? null : onRemove,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: isRemoving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Color(0xFFEF4444), strokeWidth: 2))
                  : Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.close,
                            color: Color(0xFFEF4444), size: 14),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
