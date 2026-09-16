import 'package:flutter/material.dart';
import 'package:canteen_app/services/firebase_service.dart';

class StoreOwnerInventoryScreen extends StatefulWidget {
  const StoreOwnerInventoryScreen({super.key});

  @override
  State<StoreOwnerInventoryScreen> createState() => _StoreOwnerInventoryScreenState();
}

class _StoreOwnerInventoryScreenState extends State<StoreOwnerInventoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon!')),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirebaseService().getFoodItems(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildInventoryItemCard(item);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFoodDialog(context),
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Your inventory is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some items to start selling!',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryItemCard(Map<String, dynamic> item) {
    final isAvailable = item['isAvailable'] as bool? ?? true;
    final imageUrl = item['networkImage'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Stack(
        children: [
          Row(
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
                          colorFilter: isAvailable
                              ? null
                              : ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
                        )
                      : null,
                ),
                child: imageUrl.isEmpty
                    ? Icon(Icons.fastfood, color: Theme.of(context).primaryColor)
                    : (!isAvailable
                        ? const Center(
                            child: Text(
                              'SOLD OUT',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          )
                        : null),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['category'] ?? 'Other',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['title'] ?? 'Item',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${(item['price'] as num).toDouble().toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          isAvailable ? 'Available' : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isAvailable ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: isAvailable,
                          activeColor: Colors.green,
                          onChanged: (value) {
                            FirebaseService().toggleFoodAvailability(item['id'], isAvailable);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Editing coming soon!')),
                    );
                  },
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: () {
                    _showDeleteConfirmation(item);
                  },
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete ${item['title']} from the menu?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              FirebaseService().deleteFoodItem(item['id']);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddFoodDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String selectedCategory = 'Meals';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Add Menu Item', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Food Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price (₱)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value ?? 'Meals';
                    });
                  },
                  items: ['Meals', 'Snacks', 'Drinks']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                    FirebaseService().addFoodItem({
                      'title': nameController.text,
                      'price': double.tryParse(priceController.text) ?? 0.0,
                      'category': selectedCategory,
                      'networkImage': '',
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}
