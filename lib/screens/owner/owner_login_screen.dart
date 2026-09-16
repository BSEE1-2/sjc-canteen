import 'package:flutter/material.dart';
import 'package:canteen_app/services/firebase_service.dart';


class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _onLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Email and Password')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await FirebaseService().login(email, password);

    if (result != null) {
      final userData = await FirebaseService().getUserData(result.user!.uid);
      if (userData == null || userData['role'] != 'owner') {
        await FirebaseService().logout();
        if (mounted) {
          Navigator.pop(context); // Hide loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('This account is not registered as an Owner account.'),
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
      if (mounted) Navigator.pushReplacementNamed(context, '/owner_home');
    } else {
      if (mounted) {
        final errorMessage = FirebaseService().lastError ?? 'Invalid Owner Credentials';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1e293b)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Store Owner Login',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0f172a),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Manage your kitchen and serve happy students.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 48),
              _buildInputLabel('Email Address'),
              _buildTextField(
                controller: _emailController,
                hintText: 'e.g. tindera.sjc@phinma.com',
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 24),
              _buildInputLabel('Password'),
              _buildTextField(
                controller: _passwordController,
                hintText: 'Enter your password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4b652a),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Login as Owner',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No store yet? '),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/owner_create_account'),
                    child: const Text(
                      'Register your store',
                      style: TextStyle(
                        color: Color(0xFF4b652a),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1e293b),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}
