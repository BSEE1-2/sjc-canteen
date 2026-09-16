import 'package:flutter/material.dart';
import 'package:canteen_app/services/firebase_service.dart';


class OwnerCreateAccountScreen extends StatefulWidget {
  const OwnerCreateAccountScreen({super.key});

  @override
  State<OwnerCreateAccountScreen> createState() => _OwnerCreateAccountScreenState();
}

class _OwnerCreateAccountScreenState extends State<OwnerCreateAccountScreen> {
  final _storeNameController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _onCreateAccount() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await FirebaseService().signup(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _adminNameController.text.trim(),
      role: 'owner',
      storeName: _storeNameController.text.trim(),
    );

    // Hide loading indicator
    if (mounted) Navigator.of(context, rootNavigator: true).maybePop();

    if (result != null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/owner_home');
    } else {
      if (mounted) {
        final errorMessage = FirebaseService().lastError ?? 'Registration failed. Please try again.';
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
                'Register Store',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0f172a),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Create your store profile to start selling.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 48),
              _buildInputLabel('Store Name'),
              _buildTextField(
                controller: _storeNameController,
                hintText: 'e.g. Lola\'s Kitchen',
                prefixIcon: Icons.store_outlined,
              ),
              const SizedBox(height: 24),
              _buildInputLabel('Store Admin Name'),
              _buildTextField(
                controller: _adminNameController,
                hintText: 'Full Name',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 24),
              _buildInputLabel('Work Email'),
              _buildTextField(
                controller: _emailController,
                hintText: 'admin@store.com',
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 24),
              _buildInputLabel('Password'),
              _buildTextField(
                controller: _passwordController,
                hintText: 'Minimum 8 characters',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onCreateAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4b652a),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Create Store Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
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
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1e293b)),
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
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon),
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
