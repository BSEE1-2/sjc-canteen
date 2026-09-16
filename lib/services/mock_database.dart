import 'dart:async';
import 'package:canteen_app/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockDatabase {
  static final MockDatabase _instance = MockDatabase._internal();
  factory MockDatabase() => _instance;
  MockDatabase._internal() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _firebase.getUserData(user.uid).then((profile) {
          _profile = profile;
          _notify();
        });
      } else {
        _profile = null;
      }
      _notify();
    });
  }

  final FirebaseService _firebase = FirebaseService();
  Map<String, dynamic>? _profile;

  final _stateController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stateStream => _stateController.stream;

  Map<String, dynamic>? get currentUser {
    final user = _firebase.currentUser;
    if (user == null) return null;
    return {
      'uid': user.uid,
      'email': user.email,
      'name': _profile?['name'] ?? user.displayName ?? user.email?.split('@')[0] ?? 'User',
      'role': _profile?['role'] ?? 'student',
      ...?_profile,
    };
  }

  final List<Map<String, dynamic>> _foodItems = [
    {
      'id': '1',
      'title': 'Chicken Adobo',
      'price': 85.00,
      'category': 'Meals',
      'networkImage': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBcxVPH0bG8D6zJKiYsSJDRruWZXinVcef7FxvCyX6FRqwSOoqyJ24QgNxoUqkl-uUwf9BxioDYTVQAAzqzZTy2KFdfQsB2EbL2lKT80EjsPis-SZwL45tlBbw8AnYabszmh7HDYm2rxhMt7xp3vs1GRbEqiMfv5LmAztDnnr3YBxCwLm-b3Jr5I1KtAjs_IiSiyINd3vft-jrCuaeFJF_VHitYb-eJzsGCvic0duoWaSTxBwSXuwaGX2WtrXmAT6yx3ZL-WzStYG4',
      'isAvailable': true,
    },
    {
      'id': '2',
      'title': 'Pork Sisig Rice',
      'price': 95.00,
      'category': 'Meals',
      'networkImage': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDdgV_IVX8_XRIbzb6wKJ1T78o8zQ1GxE3zwLOAee_viLMWAe8t1Scz64AZ8zgaUkQ4K6bjgmK2dBdak3uJE5kw-dNPRhzfyvtEFShk6c9O62VP6pFB7k1_xGpt-syBkGEw3jY29wAGeOV8V9U2lYqYrE-TvlCyZYdxK99jTPo1hyYxHd96IGon7WCvzXDmrsYeFrdti37ZVn3aY7X7ICnm5DOfKhYNH_XIhiYwj3cL2jeKwYBUv6WYUvwXIof9jSGV10OxaxsRP_U',
      'isAvailable': true,
    },
    {
      'id': '3',
      'title': 'Garden Salad',
      'price': 65.00,
      'category': 'Meals',
      'networkImage': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAINQzvJeg21YG9TFplmEaXktGiH50UxWsr4f_SOmJ8A9jb2_VNGpU32_RrNU9Ibb1xj_h8BJe6oJB3bP5queSvLfzwQcS_C8AKJj7IifinmiyeMZvS0MQo77HVTMrVJxv53vtrbit8pwV46Y-UmLnmizsaNM2IP9O9DdQ9GtxHMnshvaoESemw6w2vQpMQwmWUoOM_SEgumexdTw_6EqW055o7HHSAQjxT69ll0Rph8AjBL7OgxZnGGE9btmNSawW5e8zC5PvPt9I',
      'isAvailable': true,
    },
    {
      'id': '6',
      'title': 'House Iced Tea',
      'price': 35.00,
      'category': 'Drinks',
      'networkImage': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCZcs0lbtFpGTutHNql_8957KXM7LVMSl7gb-UJgEDhKY-tk0ohk4u6Dk-XyHOqNTNxPPwXc_h9TcePfOtu0f0_jwbd6LJw_xqzv5sd8-fg-6p7f0HOPectExAxJ0gc-rShwj5n4H1dx6xjeQ6XhKaXXEyiQHcZJzcnNLrbGHVruomRwIj6Ct8l1jVnTIky9YgXLTKme4o4WjdVLbMxvjl2i7OJBNaVGGMOQ5jqLjRZZAUVeRaC1-q8M_WhHn8cPT27m9n4pNPdM7M',
      'isAvailable': true,
    },
  ];

  List<Map<String, dynamic>> get foodItems => _foodItems;

  final List<Map<String, dynamic>> _cart = [];
  List<Map<String, dynamic>> get cart => _cart;

  int get cartItemCount => _cart.fold(0, (sum, item) => sum + (item['quantity'] as int));
  double get cartTotal => _cart.fold(0.0, (sum, item) => sum + ((item['price'] as num).toDouble()) * (item['quantity'] as int));

  final List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> get orders => _orders;

  final List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  int get unreadNotificationCount => _notifications.where((n) => n['isRead'] == false).length;

  bool login(String email, String password) => false;
  void signup({required String id, required String name, required String email, required String password, required String role, String? storeName}) {}
  
  void logout() {
    _firebase.logout();
    _cart.clear();
    _notify();
  }

  void addToCart(Map<String, dynamic> foodItem) {
    final existingIndex = _cart.indexWhere((item) => item['id'] == foodItem['id']);
    if (existingIndex >= 0) {
      _cart[existingIndex]['quantity'] = (_cart[existingIndex]['quantity'] as int) + 1;
    } else {
      _cart.add({...foodItem, 'quantity': 1});
    }
    _notify();
  }

  void updateCartQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      _cart.removeWhere((item) => item['id'] == itemId);
    } else {
      final index = _cart.indexWhere((item) => item['id'] == itemId);
      if (index >= 0) {
        _cart[index]['quantity'] = quantity;
      }
    }
    _notify();
  }

  void removeFromCart(String itemId) {
    _cart.removeWhere((item) => item['id'] == itemId);
    _notify();
  }

  void clearCart() {
    _cart.clear();
    _notify();
  }

  Future<bool> placeOrder() async {
    if (_cart.isEmpty || currentUser == null) return false;
    String studentName = currentUser!['name'] ?? 'Student';
    String studentId = '';
    try {
      final userDoc = await _firebase.getUserData(currentUser!['uid']);
      if (userDoc != null) {
        studentName = userDoc['name'] ?? studentName;
        studentId = userDoc['studentId'] ?? '';
      }
    } catch (_) {}

    await _firebase.placeOrder(
      cartItems: List.from(_cart),
      total: cartTotal,
      studentName: studentName,
      studentId: studentId,
    );
    _cart.clear();
    _notify();
    return true;
  }

  void updateOrderStatus(String orderId, String newStatus) {
    final index = _orders.indexWhere((o) => o['id'] == orderId);
    if (index >= 0) {
      _orders[index]['status'] = newStatus;
      _notify();
    }
  }

  List<Map<String, dynamic>> getOrdersForCurrentUser() => _orders;
  List<Map<String, dynamic>> getAllOrders() => _orders;

  void addFoodItem(Map<String, dynamic> item) {
    _foodItems.add({...item, 'id': DateTime.now().toString(), 'isAvailable': true});
    _notify();
  }

  void toggleFoodAvailability(String id) {
    final index = _foodItems.indexWhere((item) => item['id'] == id);
    if (index >= 0) {
      _foodItems[index]['isAvailable'] = !(_foodItems[index]['isAvailable'] as bool);
      _notify();
    }
  }

  void markAllNotificationsRead() {
    for (var n in _notifications) {
      n['isRead'] = true;
    }
    _notify();
  }

  void markNotificationRead(String id) {
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index >= 0) {
      _notifications[index]['isRead'] = true;
      _notify();
    }
  }

  double get totalRevenue => _orders.fold(0.0, (sum, o) => sum + (o['total'] as double));
  int get totalOrderCount => _orders.length;
  double get averageOrderValue => _orders.isEmpty ? 0 : totalRevenue / totalOrderCount;
  int get uniqueCustomerCount => _orders.map((o) => o['studentId']).toSet().length;
  Map<String, int> get popularItems => {};

  void _notify() {
    _stateController.add({'currentUser': currentUser, 'cart': _cart});
  }
}
