import 'package:flutter/material.dart';
import 'package:canteen_app/services/firebase_service.dart';
import 'package:canteen_app/widgets/wavy_progress_indicator.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                        _buildProfileCompletion(),
                        _buildSettingsSection(
                          context: context,
                          title: 'Account Settings',
                          items: [
                            _buildSettingsItem(
                              context: context,
                              icon: Icons.person,
                              label: 'Personal Information',
                              onTap: () => _showPersonalInfoDialog(context, user),
                            ),
                            _buildSettingsItem(
                              context: context,
                              icon: Icons.security,
                              label: 'Security & Password',
                              onTap: () => _showSecurityDialog(context),
                            ),
                            _buildSettingsItem(
                              context: context,
                              icon: Icons.notifications,
                              label: 'Notifications',
                              onTap: () => Navigator.pushNamed(context, '/notifications'),
                            ),
                            _buildSettingsItem(
                              context: context,
                              icon: Icons.language,
                              label: 'Language',
                              trailing: 'English (US)',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Language settings - English (US)'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        _buildSettingsSection(
                          context: context,
                          title: 'Support',
                          items: [
                            _buildSettingsItem(
                              context: context,
                              icon: Icons.help,
                              label: 'Help Center',
                              onTap: () => _showHelpDialog(context),
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
                              backgroundColor: Colors.red.withOpacity(0.1),
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
          const Text(
            'Student Profile',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF191d15)),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF4b652a).withOpacity(0.1), shape: BoxShape.circle),
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Settings'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: const Icon(Icons.settings, color: Color(0xFF4b652a), size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHero(BuildContext context, Map<String, dynamic>? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
                  color: const Color(0xFF4b652a).withOpacity(0.1),
                ),
                child: ClipOval(
                  child: user?['profilePic'] != null
                      ? Image.network(
                          user!['profilePic'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(user['name'] ?? 'S'),
                        )
                      : _buildInitialsAvatar(user?['name'] ?? 'S'),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4b652a),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?['name'] ?? 'Student',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0f172a), letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Student ID: ${user?['studentId'] ?? user?['id'] ?? 'N/A'}',
            style: const TextStyle(color: Color(0xFF4b652a), fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const Text('Phinma Saint Jude College Manila', style: TextStyle(color: Color(0xFF64748b), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildProfileCompletion() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFf1f5f9)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Profile Completion', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
                Text('85%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4b652a))),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: const WavyProgressIndicator(
                value: 0.85,
                height: 10,
                backgroundColor: Color(0xFFf1f5f9),
                color: Color(0xFF4b652a),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Almost there! Complete your details to unlock all features.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748b)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({required BuildContext context, required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 16, 12),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Column(children: items)),
      ],
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    String? trailing,
    Color color = const Color(0xFF4b652a),
    Color? backgroundColor,
    bool showChevron = true,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: backgroundColor ?? color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color == Colors.red ? Colors.red : const Color(0xFF1e293b)),
                ),
              ),
              if (trailing != null) Text(trailing, style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 14)),
              if (showChevron) const Icon(Icons.chevron_right, color: Color(0xFF94a3b8)),
            ],
          ),
        ),
      ),
    );
  }

  void _showPersonalInfoDialog(BuildContext context, Map<String, dynamic>? user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Name', user?['name'] ?? 'N/A'),
            _infoRow('Student ID', user?['studentId'] ?? user?['id'] ?? 'N/A'),
            _infoRow('Email', user?['email'] ?? 'N/A'),
            _infoRow('Role', (user?['role'] ?? 'N/A').toString().toUpperCase()),
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
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Security & Password', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.security, size: 48, color: Color(0xFF4b652a)),
            SizedBox(height: 16),
            Text('Your account is secured. You can reset your password using the "Forgot Password" link on the login screen.', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Help Center', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📧 lome.isidoro.sjc@phinmaed.com'),
            SizedBox(height: 8),
            Text('📞 09859808713'),
            SizedBox(height: 16),
            Text('For canteen-related concerns, please visit the canteen admin office.'),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant, size: 48, color: Color(0xFF4b652a)),
            const SizedBox(height: 16),
            const Text('Phinma Canteen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Text('Beta Version 5.0.0'),
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

  Widget _buildInitialsAvatar(String name) {
    String initials = 'S';
    final parts = name.trim().split(' ');
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      initials = parts[0][0].toUpperCase();
      if (parts.length > 1 && parts.last.isNotEmpty) {
        initials += parts.last[0].toUpperCase();
      }
    }
    return Container(
      color: const Color(0xFF4b652a),
      alignment: Alignment.center,
      child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
    );
  }
}
