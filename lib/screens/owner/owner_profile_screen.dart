import 'package:flutter/material.dart';
import 'package:canteen_app/services/firebase_service.dart';
import 'package:canteen_app/widgets/wavy_progress_indicator.dart';

class OwnerProfileScreen extends StatelessWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf7f7f6),
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>?>(
          stream: FirebaseService().profileStream,
          builder: (context, snapshot) {
            final user = snapshot.data;
            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      children: [
                        _buildProfileHero(context, user),
                        _buildStoreCompletion(),
                        _buildSettingsSection(
                          context: context,
                          title: 'Store Settings',
                          items: [
                            _buildSettingsItem(
                              context: context,
                              icon: Icons.store,
                              label: 'Edit Store Info',
                              onTap: () => _showEditStoreDialog(context, user),
                            ),
                            _buildSettingsItem(
                              context: context,
                              icon: Icons.restaurant_menu,
                              label: 'Menu Management',
                              onTap: () => Navigator.pushNamed(context, '/owner_inventory'),
                            ),
                            _buildSettingsItem(
                              context: context,
                              icon: Icons.schedule,
                              label: 'Operating Hours',
                              trailing: '7AM - 5PM',
                              onTap: () => _showOperatingHoursDialog(context),
                            ),
                          ],
                        ),
                        _buildSettingsSection(
                          context: context,
                          title: 'Account',
                          items: [
                            _buildSettingsItem(
                              context: context,
                              icon: Icons.notifications,
                              label: 'Push Notifications',
                              trailing: 'On',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Push notifications are enabled',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildSettingsItem(
                              context: context,
                              icon: Icons.security,
                              label: 'Privacy & Security',
                              onTap: () => _showPrivacyDialog(context),
                            ),
                          ],
                        ),
                        _buildSettingsSection(
                          context: context,
                          title: 'Support',
                          items: [
                            _buildSettingsItem(
                              context: context,
                              icon: Icons.help_outline,
                              label: 'Help & Support',
                              onTap: () => _showSupportDialog(context),
                            ),
                            _buildSettingsItem(
                              context: context,
                              icon: Icons.info_outline,
                              label: 'About',
                              onTap: () => _showAboutDialog(context),
                            ),
                            _buildSettingsItem(
                              context: context,
                              icon: Icons.logout,
                              label: 'Logout',
                              color: Colors.red,
                              showChevron: false,
                              onTap: () => _confirmLogout(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4b652a),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 10),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'PHINMA SAINT JUDE COLLEGE MANILA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4b652a),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Store Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191d15),
                ),
              ),
            ],
          ),
          const Icon(Icons.settings, color: Color(0xFF4b652a), size: 24),
        ],
      ),
    );
  }

  Widget _buildProfileHero(BuildContext context, Map<String, dynamic>? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              color: const Color(0xFF4b652a).withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const ClipOval(
              child: Icon(Icons.storefront, size: 48, color: Color(0xFF4b652a)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?['storeName'] ?? 'Your Store',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0f172a),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Admin: ${user?['name'] ?? 'Owner'}',
            style: const TextStyle(
              color: Color(0xFF4b652a),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Text(
            user?['email'] ?? 'owner@psjc.edu.ph',
            style: const TextStyle(color: Color(0xFF64748b), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCompletion() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFf1f5f9)),
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Store Setup',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0f172a),
                  ),
                ),
                Text(
                  '90%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4b652a),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: const WavyProgressIndicator(
                value: 0.9,
                height: 8,
                backgroundColor: Color(0xFFf1f5f9),
                color: Color(0xFF4b652a),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add operating hours to complete your store setup.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748b)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required BuildContext context,
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 16, 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0f172a),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    String? trailing,
    Color color = const Color(0xFF4b652a),
    bool showChevron = true,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (color == Colors.red ? Colors.red : const Color(0xFF4b652a)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color == Colors.red ? Colors.red : const Color(0xFF1e293b),
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing,
                  style: const TextStyle(
                    color: Color(0xFF94a3b8),
                    fontSize: 14,
                  ),
                ),
              if (showChevron)
                const Icon(Icons.chevron_right, color: Color(0xFF94a3b8)),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditStoreDialog(BuildContext context, Map<String, dynamic>? user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Store Information', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Store Name', user?['storeName'] ?? 'N/A'),
            _infoRow('Admin', user?['name'] ?? 'N/A'),
            _infoRow('Email', user?['email'] ?? 'N/A'),
            _infoRow('Location', 'PSJC Campus, Manila'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showOperatingHoursDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Operating Hours', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monday - Friday', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('7:00 AM - 5:00 PM', style: TextStyle(color: Color(0xFF4b652a))),
            SizedBox(height: 12),
            Text('Saturday', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('8:00 AM - 12:00 PM', style: TextStyle(color: Color(0xFF4b652a))),
            SizedBox(height: 12),
            Text('Sunday', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Closed', style: TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Privacy & Security', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.security, size: 48, color: Color(0xFF4b652a)),
            SizedBox(height: 16),
            Text(
              'Your store data is protected. All transactions are logged and stored securely.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📧 lome.isidoro.sjc@phinmaed.com'),
            SizedBox(height: 8),
            Text('📞 09859808713'),
            SizedBox(height: 16),
            Text('For technical issues, please contact the developer.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront, size: 48, color: Color(0xFF4b652a)),
            SizedBox(height: 16),
            Text('Phinma Canteen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Beta Version 5.0.0'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              FirebaseService().logout();
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/role_selection', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
