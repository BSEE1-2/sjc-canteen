import 'package:flutter/material.dart';
import 'package:canteen_app/services/firebase_service.dart';



class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final input = _idController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both ID/Email and Password')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // If input doesn't look like an email, assume it's a student ID and append the domain
    final email = input.contains('@') ? input : '$input@student.psjc.edu.ph';

    final result = await FirebaseService().login(email, password);

    if (result != null) {
      final userData = await FirebaseService().getUserData(result.user!.uid);
      if (userData == null || userData['role'] != 'student') {
        await FirebaseService().logout();
        if (mounted) {
          Navigator.pop(context); // Hide loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('This account is not registered as a Student account.'),
              backgroundColor: Colors.orange.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }
    }

    // Hide loading indicator
    if (mounted) Navigator.pop(context);

    if (result != null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/student_home');
    } else {
      if (mounted) {
        final errorMessage = FirebaseService().lastError ?? 'Invalid Credentials or User does not exist';
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
              Navigator.pop(context);
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
              'Phinma Saint Jude College Manila',
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 48), // To balance the back button
        ],
      ),
    );
  }

  Widget _buildIllustration(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                width: 4,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Center(
              child: Icon(
                Icons.account_circle,
                size: 180,
                color: Theme.of(context).primaryColor,
              ),
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
        children: [
          Text(
            'Welcome Back!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Log in to your school ordering account',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel(context, 'Student ID'),
          const SizedBox(height: 6),
          _buildTextField(
            context: context,
            controller: _idController,
            hintText: 'e.g. 06-2425-000000',
            leadingIcon: Icons.person,
          ),
          const SizedBox(height: 20),
          _buildInputLabel(context, 'Password'),
          const SizedBox(height: 6),
          _buildTextField(
            context: context,
            controller: _passwordController,
            hintText: 'Enter your password',
            leadingIcon: Icons.lock,
            isPassword: true,
            obscureText: _obscurePassword,
            onToggleObscure: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
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
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor.withOpacity(0.5),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: _onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'LOG IN',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(width: 8),
                Icon(Icons.login),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/forgot_password');
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/create_account');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              side: BorderSide.none,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Create Account',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '© 2026 PHINMA SAINT JUDE COLLEGE MANILA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
