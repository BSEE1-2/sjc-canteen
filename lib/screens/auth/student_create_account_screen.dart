import 'package:flutter/material.dart';
import 'package:canteen_app/services/firebase_service.dart';



class StudentCreateAccountScreen extends StatefulWidget {
  const StudentCreateAccountScreen({super.key});

  @override
  State<StudentCreateAccountScreen> createState() =>
      _StudentCreateAccountScreenState();
}

class _StudentCreateAccountScreenState extends State<StudentCreateAccountScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onCreateAccount() async {
    if (_nameController.text.isEmpty ||
        _idController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all required fields'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final email = _emailController.text.isEmpty
        ? '${_idController.text}@student.psjc.edu.ph'
        : _emailController.text;

    final result = await FirebaseService().signup(
      email: email,
      password: _passwordController.text,
      name: _nameController.text,
      role: 'student',
      studentId: _idController.text,
    );

    // Hide loading indicator
    if (mounted) Navigator.of(context, rootNavigator: true).maybePop();

    if (result != null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/student_home');
    } else {
      if (mounted) {
        final errorMessage = FirebaseService().lastError ?? 'Account creation failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildIllustration(context),
                      _buildWelcomeText(context),
                      _buildForm(context),
                      _buildActionButtons(context),
                    ],
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Image.asset(
              'assets/images/Saint-Jude-College.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'PHINMA SAINT JUDE COLLEGE MANILA',
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildIllustration(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/images/students.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(
              Icons.school,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hi Student!',
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join your school community and start ordering.',
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel(context, 'Full Name *'),
          const SizedBox(height: 8),
          _buildTextField(
            context: context,
            controller: _nameController,
            hintText: 'e.g. Juan Dela Cruz',
            leadingIcon: Icons.person,
          ),
          const SizedBox(height: 16),
          _buildInputLabel(context, 'Student ID *'),
          const SizedBox(height: 8),
          _buildTextField(
            context: context,
            controller: _idController,
            hintText: 'e.g. 06-2425-000000',
            leadingIcon: Icons.badge,
          ),
          const SizedBox(height: 16),
          _buildInputLabel(context, 'Email (Optional)'),
          const SizedBox(height: 8),
          _buildTextField(
            context: context,
            controller: _emailController,
            hintText: 'e.g. juan.dela.cruz.sjc@phinma.com',
            leadingIcon: Icons.email,
          ),
          const SizedBox(height: 16),
          _buildInputLabel(context, 'Password *'),
          const SizedBox(height: 8),
          _buildTextField(
            context: context,
            controller: _passwordController,
            hintText: 'Create a strong password',
            leadingIcon: Icons.lock,
            isPassword: true,
            obscureText: _obscurePassword,
            onToggleObscure: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildInputLabel(context, 'Confirm Password *'),
          const SizedBox(height: 8),
          _buildTextField(
            context: context,
            controller: _confirmPasswordController,
            hintText: 'Repeat password',
            leadingIcon: Icons.lock_reset,
            isPassword: true,
            obscureText: _obscureConfirmPassword,
            onToggleObscure: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    required IconData leadingIcon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        prefixIcon: Icon(leadingIcon, color: Colors.grey.shade400),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade400,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: _onCreateAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
            ),
            child: const Text(
              'CREATE ACCOUNT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Log In',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            '© 2026 Phinma Saint Jude College Manila',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
