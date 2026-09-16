import 'package:flutter/material.dart';
import 'package:canteen_app/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  String _formatDate(dynamic timestamp) {
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return 'N/A';
    }
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseService().currentUser == null) return const Scaffold(body: Center(child: Text('Please login')));
    
    return Scaffold(
      backgroundColor: const Color(0xFFf7f7f6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirebaseService().getOrdersForUser(FirebaseService().currentUser!.uid),
                builder: (context, snapshot) {
                  final orders = snapshot.data ?? [];
                  // Only show completed/settled orders in history? 
                  // For now show all that aren't Pending/Preparing if we want strict "history"
                  // But usually students want to see everything they ever did.
                  
                  if (orders.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _buildHistoryCard(context, order);
                    },
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
            'Order History',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF191d15)),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF4b652a).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long, color: Color(0xFF4b652a), size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No order history', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
          const SizedBox(height: 8),
          Text('Your past orders will appear here.', style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order['id']?.toString().substring(0, 8) ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: _getStatusColor(status), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(order['itemsDescription'] ?? 'Items', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₱${(order['total'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4b652a)),
              ),
              Text(
                _formatDate(order['timestamp']),
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
      case 'Pending': return Colors.orange;
      case 'Preparing': return Colors.blue;
      case 'Ready for Pickup': return const Color(0xFF4b652a);
      case 'Completed': return Colors.green;
      case 'Declined': return Colors.red;
      default: return Colors.grey;
    }
  }
}
