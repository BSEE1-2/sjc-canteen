import 'package:flutter/material.dart';
import 'package:canteen_app/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Orders', 'Promos'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredNotifications(List<Map<String, dynamic>> all, int tabIndex) {
    switch (tabIndex) {
      case 1:
        return all.where((n) => n['type'] == 'order_update' || n['type'] == 'order').toList();
      case 2:
        return all.where((n) => n['type'] == 'promo').toList();
      default:
        return all;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'order':
      case 'order_update':
        return Icons.receipt_long;
      case 'promo':
        return Icons.local_offer;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'order':
      case 'order_update':
        return const Color(0xFF4b652a);
      case 'promo':
        return Colors.orange;
      case 'system':
        return Colors.blue;
      default:
        return Colors.grey;
    }
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
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              // Mark all read in Firestore - would need a batch op
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Marking all as read...'),
                  duration: const Duration(milliseconds: 500),
                ),
              );
            },
            child: Text(
              'Mark all read',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirebaseService().getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final allNotifications = snapshot.data ?? [];
          
          return TabBarView(
            controller: _tabController,
            children: _tabs.asMap().entries.map((entry) {
              final notifications = _getFilteredNotifications(allNotifications, entry.key);
              if (notifications.isEmpty) {
                return _buildEmptyState(entry.value);
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return _buildNotificationCard(notif);
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No $category notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    final type = notif['type'] as String? ?? 'system';
    final isRead = notif['isRead'] as bool? ?? false;
    final color = _getColorForType(type);
    final icon = _getIconForType(type);
    final timestamp = notif['timestamp'];

    return Dismissible(
      key: Key(notif['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
         // Silently dismissed or could call delete in Firestore
      },
      child: GestureDetector(
        onTap: () {
          FirebaseService().markNotificationAsRead(notif['id']);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : color.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead ? Colors.grey.shade100 : color.withOpacity(0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  notif['title'] ?? 'Notification',
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatTime(timestamp),
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif['message'] ?? notif['body'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
