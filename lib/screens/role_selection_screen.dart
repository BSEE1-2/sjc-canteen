import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildWelcomeText(context),
                    const SizedBox(height: 40),
                    _buildRoleCard(
                      context: context,
                      title: 'Student',
                      description:
                          'Browse daily menus, pre-order your favorite meals, and track your wallet balance in real-time.',
                      imagePath: 'assets/images/students.jpg',
                      icon: Icons.person,
                      buttonText: 'I am a Student',
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildRoleCard(
                      context: context,
                      title: 'Canteen Owner',
                      description:
                          'Manage inventory, update daily specials, process student orders, and access detailed sales analytics.',
                      imagePath: 'assets/images/canteen.jpg',
                      icon: Icons.storefront,
                      buttonText: 'I am an Owner',
                      onPressed: () {
                        Navigator.pushNamed(context, '/owner_login');
                      },
                    ),
                    const SizedBox(height: 48),
                    Text(
                      '© 2026 Phinma Saint Jude College Education Network. All rights reserved.',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Image.asset(
                  'assets/images/Saint-Jude-College.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Phinma Saint Jude',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/images/info_24dp_4C6649_FILL0_wght400_GRAD0_opsz24.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeText(BuildContext context) {
    return Column(
      children: [
        Text(
          'Welcome!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose your role to get started with our school canteen services.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String description,
    required String imagePath,
    required IconData icon,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                child: Icon(Icons.image, color: Colors.grey.shade400),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        buttonText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
