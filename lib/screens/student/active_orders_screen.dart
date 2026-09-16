import 'package:flutter/material.dart';
import 'package:canteen_app/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveOrdersScreen extends StatelessWidget {
  const ActiveOrdersScreen({super.key});

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return 'N/A';
    }
    
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseService().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFf7f7f6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: currentUser == null
                  ? _buildEmptyState(context)
                  : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: FirebaseService().getOrdersForUser(currentUser.uid),
                      builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final userOrders = snapshot.data ?? [];
                  final activeOrders = userOrders.where((o) =>
                      o['status'] == 'Pending' || o['status'] == 'Preparing' || o['status'] == 'Ready for Pickup').toList();
                  final pastOrders = userOrders.where((o) =>
                      o['status'] == 'Completed' || o['status'] == 'Declined').toList();

                  if (userOrders.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (activeOrders.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Text(
                              'Ongoing Orders',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0f172a)),
                            ),
                          ),
                          ...activeOrders.map((order) => _buildOrderCard(context, order)),
                        ],
                        if (pastOrders.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Past Orders',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0f172a)),
                            ),
                          ),
                          ...pastOrders.map((order) => _buildOrderCard(context, order)),
                        ],
                        // Suggestion
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32.0),
                            child: Column(
                              children: [
                                const Text(
                                  'Need something else?',
                                  style: TextStyle(color: Color(0xFF94a3b8), fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                TextButton(
                                  onPressed: () {
                                    // Navigate to food selection (tab 0 in nav wrapper)
                                    Navigator.pushNamedAndRemoveUntil(context, '/student_home', (route) => false);
                                  },
                                  child: const Text(
                                    'Order more snacks',
                                    style: TextStyle(
                                      color: Color(0xFF4b652a),
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'My Orders',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191d15),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4b652a).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/notifications'),
              child: const Icon(
                Icons.notifications_none,
                color: Color(0xFF4b652a),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 8),
          Text(
            'Place your first order from the menu!',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final status = order['status'] as String;
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4b652a).withOpacity(0.05)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order['id'] ?? 'Order',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order['itemsDescription'] ?? 'Assorted Items',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₱${(order['total'] as num).toDouble().toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF4b652a),
                ),
              ),
              Text(
                _formatTime(order['timestamp']),
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Preparing':
        return Colors.blue;
      case 'Ready for Pickup':
        return const Color(0xFF4b652a);
      case 'Completed':
        return Colors.green;
      case 'Declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
