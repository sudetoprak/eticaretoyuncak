import 'package:flutter/material.dart';
import '../../providers/models/models.dart';
import '../../services/orders_service.dart';

class CheckoutScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSuccess;

  const CheckoutScreen({super.key, required this.onBack, required this.onSuccess});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _streetCtrl = TextEditingController(text: '');
  final _cityCtrl = TextEditingController(text: '');
  final _countryCtrl = TextEditingController(text: 'Türkiye');
  final _zipCtrl = TextEditingController(text: '');
  String _paymentMethod = 'credit_card';
  bool _loading = false;

  final _service = OrdersService();

  Future<void> _placeOrder() async {
    if (_streetCtrl.text.trim().isEmpty ||
        _cityCtrl.text.trim().isEmpty ||
        _zipCtrl.text.trim().isEmpty) {
      _showError('Adres bilgilerini eksiksiz doldurun.');
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
        paymentMethod: _paymentMethod,
      );
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('Sipariş Verildi!',
                style: TextStyle(color: Color(0xFFF1F5F9))),
            content: const Text('Siparişiniz başarıyla alındı.',
                style: TextStyle(color: Color(0xFF94A3B8))),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onSuccess();
                },
                child: const Text('Tamam', style: TextStyle(color: Color(0xFF3B82F6))),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      if (mounted) _showError('Sipariş verilemedi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Hata', style: TextStyle(color: Color(0xFFF1F5F9))),
        content: Text(msg, style: const TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam', style: TextStyle(color: Color(0xFF3B82F6))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, color: Color(0xFF60A5FA), size: 18),
                label: const Text('Geri', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 15)),
              ),
              const SizedBox(height: 8),
              const Text('Teslimat Adresi',
                  style: TextStyle(
                      color: Color(0xFFF1F5F9), fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _field('Sokak / Mahalle *', _streetCtrl, 'Atatürk Cad. No:5 D:3'),
              _field('Şehir *', _cityCtrl, 'İstanbul'),
              _field('Ülke', _countryCtrl, 'Türkiye'),
              _field('Posta Kodu *', _zipCtrl, '34000',
                  keyboard: TextInputType.number),
              const SizedBox(height: 24),
              const Text('Ödeme Yöntemi',
                  style: TextStyle(
                      color: Color(0xFFF1F5F9), fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...[
                ('credit_card', 'Kredi Kartı'),
                ('bank_transfer', 'Havale / EFT'),
                ('cash_on_delivery', 'Kapıda Ödeme'),
              ].map((opt) => _payOption(opt.$1, opt.$2)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    disabledBackgroundColor: const Color(0xFF3B82F6).withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Siparişi Onayla',
                          style: TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 20),
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
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          TextField(
            controller: ctrl,
            keyboardType: keyboard,
            style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF64748B)),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6))),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      );

  Widget _payOption(String id, String label) => GestureDetector(
        onTap: () => setState(() => _paymentMethod = id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _paymentMethod == id
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF334155)),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _paymentMethod == id
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF64748B),
                      width: 2),
                  color: _paymentMethod == id ? const Color(0xFF3B82F6) : Colors.transparent,
                ),
              ),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                      color: _paymentMethod == id
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF94A3B8),
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
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
