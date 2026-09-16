import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:canteen_app/screens/auth/forgot_password_screen.dart';
import 'package:canteen_app/screens/owner/owner_login_screen.dart';
import 'package:canteen_app/screens/owner/owner_create_account_screen.dart';
import 'package:canteen_app/screens/owner/owner_navigation_wrapper.dart';
import 'package:canteen_app/screens/owner/owner_orders_screen.dart';
import 'package:canteen_app/screens/owner/owner_analytics_screen.dart';
import 'package:canteen_app/screens/owner/owner_profile_screen.dart';
import 'package:canteen_app/screens/owner/store_owner_inventory_screen.dart';
import 'package:canteen_app/screens/student/notifications_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/auth/student_login_screen.dart';
import 'screens/auth/student_create_account_screen.dart';
import 'screens/student/food_selection_screen.dart';
import 'screens/student/cart_payment_screen.dart';
import 'screens/student/active_orders_screen.dart';
import 'screens/student/order_history_screen.dart';
import 'screens/student/profile_screen.dart';
import 'screens/student/student_navigation_wrapper.dart';
import 'screens/owner/store_owner_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const CanteenApp());
}

class AppColors {
  static const primary = Color(0xFFffa600);
  static const backgroundLight = Color(0xFFf7f7f6);
  static const backgroundDark = Color(0xFF191d15);
}

class CanteenApp extends StatelessWidget {
  const CanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phinma Canteen',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          surface: AppColors.backgroundLight,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          bodyMedium: GoogleFonts.notoSans(
            textStyle: Theme.of(context).textTheme.bodyMedium,
          ),
          bodyLarge: GoogleFonts.notoSans(
            textStyle: Theme.of(context).textTheme.bodyLarge,
          ),
          bodySmall: GoogleFonts.notoSans(
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6,
          backgroundColor: AppColors.backgroundDark, // M3 dark snackbar for light theme
          contentTextStyle: const TextStyle(color: Colors.white),
        ),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.backgroundDark,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ).copyWith(
          bodyMedium: GoogleFonts.notoSans(
            textStyle: ThemeData(brightness: Brightness.dark).textTheme.bodyMedium,
          ),
          bodyLarge: GoogleFonts.notoSans(
            textStyle: ThemeData(brightness: Brightness.dark).textTheme.bodyLarge,
          ),
          bodySmall: GoogleFonts.notoSans(
            textStyle: ThemeData(brightness: Brightness.dark).textTheme.bodySmall,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6,
          backgroundColor: AppColors.backgroundLight,
          contentTextStyle: const TextStyle(color: Colors.black),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/role_selection': (context) => const RoleSelectionScreen(),
        '/login': (context) => const StudentLoginScreen(),
        '/create_account': (context) => const StudentCreateAccountScreen(),
        '/student_home': (context) => const StudentNavigationWrapper(),
        '/food_selection': (context) => const FoodSelectionScreen(),
        '/active_orders': (context) => const ActiveOrdersScreen(),
        '/order_history': (context) => const OrderHistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/cart': (context) => const CartPaymentScreen(),
        '/owner_dashboard': (context) => const StoreOwnerDashboardScreen(),
        '/owner_orders': (context) => const OwnerOrdersScreen(),
        '/owner_analytics': (context) => const OwnerAnalyticsScreen(),
        '/owner_inventory': (context) => const StoreOwnerInventoryScreen(),
        '/owner_profile': (context) => const OwnerProfileScreen(),
        '/owner_login': (context) => const OwnerLoginScreen(),
        '/owner_create_account': (context) => const OwnerCreateAccountScreen(),
        '/owner_home': (context) => const OwnerNavigationWrapper(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}
