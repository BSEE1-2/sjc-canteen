import 'package:flutter/material.dart';
import 'package:canteen_app/services/firebase_service.dart';
import 'package:canteen_app/widgets/wavy_progress_indicator.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _studentIdController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _animateToNextStep(int step) {
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() => _currentStep = step);
        _animController.forward();
      }
    });
  }

  Future<void> _onSendCode() async {
    if (_studentIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your Student ID'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    try {
      await FirebaseService().sendPasswordResetForStudentId(_studentIdController.text.trim());
      if (mounted) {
        _animateToNextStep(4);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
        );
      }
    }
  }

  void _onVerifyCode() {
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the verification code'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    _animateToNextStep(3);
  }

  void _onResetPassword() async {
    if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a new password'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    await FirebaseService().sendPasswordResetForStudentId(_studentIdController.text.trim());
    _animateToNextStep(4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            if (_currentStep > 0 && _currentStep < 4) {
              _animateToNextStep(_currentStep - 1);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'Reset Password',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _buildCurrentStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildEnterIdStep();
      case 1:
        return _buildCodeSentStep();
      case 2:
        return _buildEnterCodeStep();
      case 3:
        return _buildNewPasswordStep();
      case 4:
        return _buildSuccessStep();
      default:
        return _buildEnterIdStep();
    }
  }

  Widget _buildEnterIdStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressBar(0.25),
        const SizedBox(height: 32),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_reset, size: 40, color: Theme.of(context).primaryColor),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Forgot Password?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter your Student ID and we will send a password reset link to your registered email.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                height: 1.5,
              ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Student ID',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _studentIdController,
          decoration: InputDecoration(
            hintText: 'e.g. 2023-00123',
            prefixIcon: const Icon(Icons.badge_outlined),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _onSendCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Send Reset Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeSentStep() {
    return Column(
      children: [
        _buildProgressBar(0.5),
        const SizedBox(height: 48),
        Icon(Icons.mark_email_read, size: 80, color: Theme.of(context).primaryColor),
        const SizedBox(height: 24),
        const Text('Code Sent!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent a password reset link to your registered email for ID: ${_studentIdController.text}',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),
        const CircularProgressIndicator(),
      ],
    );
  }

  Widget _buildEnterCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressBar(0.5),
        const SizedBox(height: 32),
        const Text('Enter Verification Code', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '000000',
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _onVerifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Verify Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressBar(0.75),
        const SizedBox(height: 32),
        const Text('Create New Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'New Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            hintText: 'Confirm Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _onResetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Reset Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      children: [
        _buildProgressBar(1.0),
        const SizedBox(height: 48),
        const Icon(Icons.check_circle, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text('Success!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'Check your email to choose a new password.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Back to Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: WavyProgressIndicator(
            value: progress,
            height: 8,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}
