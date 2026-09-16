import 'package:flutter/material.dart';
import 'package:canteen_app/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerOrdersScreen extends StatefulWidget {
  const OwnerOrdersScreen({super.key});

  @override
  State<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends State<OwnerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getOrdersByStatus(List<Map<String, dynamic>> all, String status) {
    if (status == 'All') return all;
    if (status == 'Ready' || status == 'Ready for Pickup') {
      return all.where((o) => o['status'] == 'Ready for Pickup').toList();
    }
    if (status == 'Completed' || status == 'Done') {
      return all.where((o) => o['status'] == 'Completed' || o['status'] == 'Done').toList();
    }
    return all.where((o) => o['status'] == status).toList();
  }

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
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf7f7f6),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirebaseService().getOrders(),
          builder: (context, snapshot) {
            final orders = snapshot.data ?? [];
            
            return Column(
              children: [
                _buildHeader(context, orders.length),
                _buildTabs(context),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrderList(orders, 'All'),
                      _buildOrderList(orders, 'Pending'),
                      _buildOrderList(orders, 'Preparing'),
                      _buildOrderList(orders, 'Ready'),
                      _buildOrderList(orders, 'Completed'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int totalCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Orders',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191d15),
                ),
              ),
              Text(
                '$totalCount total orders',
                style: const TextStyle(color: Color(0xFF64748b), fontSize: 14),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4b652a).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Color(0xFF4b652a),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() {}),
        labelColor: const Color(0xFF4b652a),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF4b652a),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Pending'),
          Tab(text: 'Preparing'),
          Tab(text: 'Ready'),
          Tab(text: 'Done'),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> allOrders, String status) {
    final filteredOrders = _getOrdersByStatus(allOrders, status);

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              status == 'All' ? 'No orders yet' : 'No $status orders',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders will appear here when students order.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(context, order);
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'Pending';
    final statusColor = _getStatusColor(status);
    final timestamp = order['timestamp'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4b652a).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF4b652a), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['studentName'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        order['id'] ?? '',
                        style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12),
                      ),
                    ],
                  ),
                ],
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
                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // Items
          Text(
            order['itemsDescription'] ?? '',
            style: const TextStyle(color: Color(0xFF64748b), fontSize: 14),
          ),
          const SizedBox(height: 12),
          // Footer
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
                _formatTime(timestamp),
                style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12),
              ),
            ],
          ),
          // Action buttons based on status
          if (status == 'Pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      FirebaseService().updateOrderStatus(order['id'], 'Declined');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      FirebaseService().updateOrderStatus(order['id'], 'Preparing');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4b652a),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
          if (status == 'Preparing') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  FirebaseService().updateOrderStatus(order['id'], 'Ready for Pickup');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Mark Ready for Pickup'),
              ),
            ),
          ],
          if (status == 'Ready for Pickup') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  FirebaseService().updateOrderStatus(order['id'], 'Completed');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Mark Completed'),
              ),
            ),
          ],
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
      case 'Done':
        return Colors.green;
      case 'Declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
