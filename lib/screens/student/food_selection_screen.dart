import 'package:flutter/material.dart';
import 'package:canteen_app/services/mock_database.dart';
import 'package:canteen_app/services/firebase_service.dart';

class FoodSelectionScreen extends StatefulWidget {
  const FoodSelectionScreen({super.key});

  @override
  State<FoodSelectionScreen> createState() => _FoodSelectionScreenState();
}

class _FoodSelectionScreenState extends State<FoodSelectionScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['All', 'Meals', 'Snacks', 'Drinks'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: StreamBuilder<Map<String, dynamic>>(
                stream: MockDatabase().stateStream,
                builder: (context, databaseSnapshot) {
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirebaseService().getFoodItems(),
                    builder: (context, foodSnapshot) {
                      if (foodSnapshot.hasError) {
                        return Center(child: Text('Error: ${foodSnapshot.error}'));
                      }
                      if (foodSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final foodItems = foodSnapshot.data ?? [];
                      
                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 160.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildGreetingText(context),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildPromoCard(context),
                              ),
                              _buildCategories(context),
                              _buildFoodGrid(context, foodItems),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingCartActionWidget(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final unreadCount = MockDatabase().unreadNotificationCount;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2), width: 2),
                ),
                child: ClipOval(
                  child: MockDatabase().currentUser?['profilePic'] != null
                      ? Image.network(
                          MockDatabase().currentUser!['profilePic'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(MockDatabase().currentUser?['name'] ?? 'S'),
                        )
                      : _buildInitialsAvatar(MockDatabase().currentUser?['name'] ?? 'S'),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.school, color: Colors.white, size: 10),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'PHINMA SAINT JUDE COLLEGE MANILA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Hi, ${MockDatabase().currentUser?['name'] ?? 'Friend'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.notifications, color: Theme.of(context).primaryColor),
                  onPressed: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick Food',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Healthy meals for a productive day',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -20,
              child: Opacity(
                opacity: 0.1,
                child: Icon(Icons.restaurant, size: 180, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Featured Today',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Up to 20% OFF\non Healthy Meals',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Order Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: _categories.asMap().entries.map((entry) {
          int idx = entry.key;
          String category = entry.value;
          bool isSelected = _selectedCategoryIndex == idx;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategoryIndex = idx;
                });
              },
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFoodGrid(BuildContext context, List<Map<String, dynamic>> allItems) {
    final items = allItems.where((f) => f['isAvailable'] == true).toList();
    final filteredItems = _selectedCategoryIndex == 0 
        ? items 
        : items.where((f) => f['category'] == _categories[_selectedCategoryIndex]).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          return _buildFoodItem(context, item);
        },
      ),
    );
  }

  Widget _buildFoodItem(BuildContext context, Map<String, dynamic> item) {
    final String title = item['title'];
    final double price = (item['price'] as num).toDouble();
    final String networkImage = item['networkImage'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    image: networkImage.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(networkImage),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: networkImage.isEmpty
                      ? Center(child: Icon(Icons.fastfood, size: 48, color: Theme.of(context).primaryColor))
                      : null,
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.favorite_border, size: 20, color: Theme.of(context).primaryColor),
                      onPressed: () {},
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₱${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    Material(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          MockDatabase().addToCart(item);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$title added to cart!'),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.add, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCartActionWidget(BuildContext context) {
    final cartCount = MockDatabase().cartItemCount;
    final cartTotal = MockDatabase().cartTotal;

    if (cartCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 100), // More space from navbar
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        height: 54, // Thinner button
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            elevation: 8,
            shadowColor: Theme.of(context).primaryColor.withOpacity(0.6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('$cartCount', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                   const Text(
                    'VIEW CART',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('₱${cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String name) {
    String initials = '';
    final parts = name.trim().split(' ');
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      initials = parts[0][0].toUpperCase();
      if (parts.length > 1 && parts[parts.length - 1].isNotEmpty) {
        initials += parts[parts.length - 1][0].toUpperCase();
      }
    } else {
      initials = 'S';
    }

    return Container(
      color: Theme.of(context).primaryColor,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
