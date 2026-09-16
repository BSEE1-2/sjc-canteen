import 'package:flutter/material.dart';
import 'package:canteen_app/services/mock_database.dart';

class CartPaymentScreen extends StatefulWidget {
  const CartPaymentScreen({super.key});

  @override
  State<CartPaymentScreen> createState() => _CartPaymentScreenState();
}

class _CartPaymentScreenState extends State<CartPaymentScreen> {
  int _selectedPaymentMethod = 0;
  final List<String> _paymentMethods = ['Cash on Pickup', 'GCash'];

  double get _subtotal => MockDatabase().cartTotal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>>(
          stream: MockDatabase().stateStream,
          builder: (context, snapshot) {
            final cart = MockDatabase().cart;
            if (cart.isEmpty) {
              return _buildEmptyCart();
            }
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCartItems(cart),
                        const SizedBox(height: 24),
                        _buildPaymentMethods(),
                        const SizedBox(height: 24),
                        _buildOrderSummary(),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some delicious food!',
            style: TextStyle(color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Browse Menu'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(List<Map<String, dynamic>> cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Items',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...cart.map((item) => _buildCartItemCard(item)),
      ],
    );
  }

  Widget _buildCartItemCard(Map<String, dynamic> item) {
    final imageUrl = item['networkImage'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              image: imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl.isEmpty
                ? Icon(Icons.fastfood, color: Theme.of(context).primaryColor)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                      onPressed: () {
                        MockDatabase().removeFromCart(item['id']);
                        setState(() {});
                      },
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '₱${(item['price'] as double).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildQuantityButton(Icons.remove, () {
                      final qty = item['quantity'] as int;
                      if (qty > 1) {
                        MockDatabase().updateCartQuantity(item['id'], qty - 1);
                        setState(() {});
                      }
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${item['quantity']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    _buildQuantityButton(Icons.add, () {
                      final qty = item['quantity'] as int;
                      MockDatabase().updateCartQuantity(item['id'], qty + 1);
                      setState(() {});
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: Theme.of(context).primaryColor),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(_paymentMethods.length, (index) {
            final isSelected = _selectedPaymentMethod == index;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = index;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: index == 0 ? 12 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.2),
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _paymentMethods[index],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal', _subtotal),
          const SizedBox(height: 8),
          _buildSummaryRow('Fee', 0.0),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                '₱${(_subtotal).toStringAsFixed(2)}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        onPressed: () async {
          final placed = await MockDatabase().placeOrder();
          if (!mounted) return;
          if (!placed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please sign in before placing an order.')),
            );
            return;
          }
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Icon(Icons.check_circle, color: Colors.green, size: 64),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Order Placed!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your order has been placed successfully and will be ready for pickup soon.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Go back to food selection
                  },
                  child: Text(
                    'Back to Home',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        child: const Text(
          'Place Order',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
