import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'Order from anywhere',
      'description':
          'Skip the line and order your favorite meals right from your classroom.',
      'image': 'assets/images/onboarding_1.png',
      'isIllustration': true,
      'illustrationUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCZERqRzw-reIWwumbbx-Zr2fQRuRs56e8EaT6Ls3gIzS_dNrG6CMdjZ9JjEWLzUbYknhbRxAT__2H2TJ98iTeGZl4z6AlLM6nn-fXFGY16Rq5gznpaHc0QiFJifh7y624t6G5eJ7IR0J2goznarbDOGcGZrfyabtR9qfKuj9OuW_VuBMQDcXqLEjWc1CkXOLWyYaCSnFJr6d5Ph3eI8aQLRZP7UhgP07qtqF18FHPEc-34VyRUemHAbZWs2b3ZOqekFc-myFgIRJU',
    },
    {
      'title': 'Track in Real-time',
      'description':
          'Get notified as soon as your order is being prepared and ready for pickup.',
      'isIconLayout': true,
    },
    {
      'title': 'Empowering Canteens',
      'description':
          'A powerful dashboard for owners to manage orders and inventory with ease.',
      'stepText': 'Step 3 of 3 • Management Overview',
      'isDashboardLayout': true,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage == _onboardingData.length - 1) {
      Navigator.pushReplacementNamed(context, '/role_selection');
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void _onSkip() {
    Navigator.pushReplacementNamed(context, '/role_selection');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_onboardingData[index]);
                },
              ),
            ),
            _buildPagination(),
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Hero(
            tag: 'app_logo',
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Phinma Canteen',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          if (_currentPage < _onboardingData.length - 1)
            TextButton(
              onPressed: _onSkip,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Skip'),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Center(child: _buildIllustration(data))),
          const SizedBox(height: 32),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              data['title'],
              key: ValueKey(data['title']),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              data['description'],
              key: ValueKey(data['description']),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildIllustration(Map<String, dynamic> data) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey(_currentPage),
        child: _getDataIllustration(data),
      ),
    );
  }

  Widget _getDataIllustration(Map<String, dynamic> data) {
    if (data['isIllustration'] == true) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(24),
            child: ClipOval(
              child: Image.network(
                data['illustrationUrl'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported,
                  size: 100,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ),
      );
    } else if (data['isIconLayout'] == true) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.speed, size: 200, color: Color(0x334b652a)),
                Transform.rotate(
                  angle: -0.05,
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_active,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Ready!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Pickup at Station A',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (data['isDashboardLayout'] == true) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dashboard',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.more_horiz),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Expanded(
                          child: _StatCard(label: 'Sales', value: '₱2.4k'),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(label: 'Orders', value: '142'),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(
                          5,
                          (index) => Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: (index + 1) * 12.0,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.5 + (index * 0.1)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _onboardingData.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 10,
            width: _currentPage == index ? 32 : 10,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 4,
                shadowColor: Theme.of(context).primaryColor.withOpacity(0.5),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Row(
                  key: ValueKey(_currentPage),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentPage == _onboardingData.length - 1
                          ? 'Get Started'
                          : 'Next',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
