import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_auth_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/app_constants.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;
  final String type;

  const ResetPasswordPage({super.key, required this.token, required this.type});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _supabase = Supabase.instance.client;

  // State
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isTokenValid = false;
  bool _isValidating = true;
  String? _errorMessage;
  String? _successMessage;
  Timer? _sessionTimer;
  int _validationAttempts = 0;

  // Password validation regex
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  @override
  void initState() {
    super.initState();
    _validateToken();
    _setupSessionTimer();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _sessionTimer?.cancel();
    super.dispose();
  }

  Future<void> _validateToken() async {
    try {
      setState(() {
        _isValidating = true;
        _errorMessage = null;
      });

      // Check token format
      if (widget.token.isEmpty || widget.token.length < 10) {
        throw Exception('Invalid token format');
      }

      // Check validation attempts
      if (_validationAttempts >= 3) {
        throw Exception('Too many validation attempts');
      }

      _validationAttempts++;

      // Check if we have a valid session (Supabase creates session from reset link)
      final session = _supabase.auth.currentSession;

      if (session != null) {
        // Token is valid (Supabase automatically validates via redirect)
        setState(() {
          _isTokenValid = true;
          _isValidating = false;
        });

        // Log successful token validation
        AppLogger.i('Token validated successfully');
      } else {
        // No session - token might be invalid
        throw Exception('Invalid or expired reset token');
      }
    } catch (error, stackTrace) {
      AppLogger.e(
        'Token validation failed',
        error: error,
        stackTrace: stackTrace,
      );

      setState(() {
        _isTokenValid = false;
        _isValidating = false;
        _errorMessage = _getErrorMessage(error);
      });
    }
  }

  void _setupSessionTimer() {
    // Set a timer to check session validity every minute
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final session = _supabase.auth.currentSession;
      if (session == null && mounted) {
        setState(() {
          _isTokenValid = false;
          _errorMessage = 'Session expired. Please request a new reset link.';
        });
        timer.cancel();
      }
    });
  }

  String _getErrorMessage(dynamic error) {
    if (error is PlatformException) {
      return 'Platform error: ${error.message}';
    }

    final errorStr = error.toString();

    if (errorStr.contains('invalid') || errorStr.contains('expired')) {
      return 'This reset link is invalid or has expired.';
    }

    if (errorStr.contains('network')) {
      return 'Network error. Please check your connection.';
    }

    if (errorStr.contains('too many attempts')) {
      return 'Too many attempts. Please try again later.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  Future<void> _resetPassword() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check password strength
    if (!_isPasswordStrong(_passwordController.text)) {
      _showPasswordStrengthDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authService = SupabaseAuthService();

      // Update password
      final result = await authService.updatePassword(
        newPassword: _passwordController.text,
      );

      if (result['success'] == true) {
        // Success
        setState(() {
          _isLoading = false;
          _successMessage =
              result['message'] ?? 'Password updated successfully!';
        });

        // Log successful password reset
        AppLogger.i('Password reset successful');

        // Clear sensitive data
        _passwordController.clear();
        _confirmPasswordController.clear();

        // Show success dialog
        _showSuccessDialog();
      } else {
        // Failure
        throw Exception(result['message'] ?? 'Failed to update password');
      }
    } catch (error, stackTrace) {
      AppLogger.e(
        'Password reset failed',
        error: error,
        stackTrace: stackTrace,
      );

      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(error);
      });
    }
  }

  bool _isPasswordStrong(String password) {
    if (password.length < AppConstants.minPasswordLength) return false;
    if (!_passwordRegex.hasMatch(password)) return false;

    // Additional checks
    if (password.contains(' ')) return false;
    if (RegExp(r'(.)\1{3,}').hasMatch(password))
      return false; // No repeating chars

    return true;
  }

  void _showPasswordStrengthDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Password Requirements'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your password must meet the following requirements:',
                ),
                const SizedBox(height: 16),
                _buildRequirement(
                  'At least 8 characters',
                  _passwordController.text.length >= 8,
                ),
                _buildRequirement(
                  'One uppercase letter',
                  RegExp(r'[A-Z]').hasMatch(_passwordController.text),
                ),
                _buildRequirement(
                  'One lowercase letter',
                  RegExp(r'[a-z]').hasMatch(_passwordController.text),
                ),
                _buildRequirement(
                  'One number',
                  RegExp(r'\d').hasMatch(_passwordController.text),
                ),
                _buildRequirement(
                  'One special character',
                  RegExp(r'[@$!%*?&]').hasMatch(_passwordController.text),
                ),
                _buildRequirement(
                  'No spaces',
                  !_passwordController.text.contains(' '),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildRequirement(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle,
            color: met ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: met ? Colors.green : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Password Updated'),
            content: const Text(
              'Your password has been updated successfully. You will now be redirected to login.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _redirectToLogin();
                },
                child: const Text('Continue'),
              ),
            ],
          ),
    );
  }

  void _redirectToLogin() {
    // Sign out to clear any residual session
    _supabase.auth.signOut();

    // Navigate to onboarding/login
    Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (route) => false);
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggleVisibility,
        ),
      ),
      style: Theme.of(context).textTheme.bodyLarge,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (_) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isValidating) {
      return _buildLoadingScreen(theme);
    }

    if (!_isTokenValid) {
      return _buildErrorScreen(theme);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Set New Password'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                margin: const EdgeInsets.only(bottom: 30),
                child: Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: theme.primaryColor,
                ),
              ),

              // Title
              Text(
                'Create New Password',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                'Choose a strong password to secure your account.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Password Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // New Password
                    _buildPasswordField(
                      label: 'New Password',
                      controller: _passwordController,
                      isVisible: _isPasswordVisible,
                      onToggleVisibility: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < AppConstants.minPasswordLength) {
                          return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                        }
                        if (!_passwordRegex.hasMatch(value)) {
                          return 'Password does not meet requirements';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    _buildPasswordField(
                      label: 'Confirm Password',
                      controller: _confirmPasswordController,
                      isVisible: _isConfirmPasswordVisible,
                      onToggleVisibility: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    // Password Strength Indicator
                    const SizedBox(height: 12),
                    if (_passwordController.text.isNotEmpty)
                      LinearProgressIndicator(
                        value: _calculatePasswordStrength(
                          _passwordController.text,
                        ),
                        backgroundColor: Colors.grey.shade200,
                        color: _getPasswordStrengthColor(
                          _passwordController.text,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Requirements Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Password must contain:',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildRequirement(
                              'Minimum 8 characters',
                              _passwordController.text.length >= 8,
                            ),
                            _buildRequirement(
                              'One uppercase letter (A-Z)',
                              RegExp(
                                r'[A-Z]',
                              ).hasMatch(_passwordController.text),
                            ),
                            _buildRequirement(
                              'One lowercase letter (a-z)',
                              RegExp(
                                r'[a-z]',
                              ).hasMatch(_passwordController.text),
                            ),
                            _buildRequirement(
                              'One number (0-9)',
                              RegExp(r'\d').hasMatch(_passwordController.text),
                            ),
                            _buildRequirement(
                              'One special character (@\$!%*?&)',
                              RegExp(
                                r'[@$!%*?&]',
                              ).hasMatch(_passwordController.text),
                            ),
                            _buildRequirement(
                              'No spaces',
                              !_passwordController.text.contains(' '),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text(
                                  'Reset Password',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                      ),
                    ),

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Success Message
                    if (_successMessage != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: TextStyle(color: Colors.green.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Cancel Button
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.primaryColor),
            const SizedBox(height: 20),
            Text('Validating reset link...', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 10),
            Text(
              'This may take a moment',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Invalid Link'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'Invalid Reset Link',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ??
                  'This password reset link is invalid or has expired.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please request a new password reset email from the login screen.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/onboarding',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Return to Login'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _isValidating = true;
                  _errorMessage = null;
                });
                _validateToken();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  double _calculatePasswordStrength(String password) {
    double strength = 0;

    if (password.length >= 8) strength += 0.2;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'\d').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[@$!%*?&]').hasMatch(password)) strength += 0.2;

    return strength;
  }

  Color _getPasswordStrengthColor(String password) {
    final strength = _calculatePasswordStrength(password);

    if (strength < 0.4) return Colors.red;
    if (strength < 0.8) return Colors.orange;
    return Colors.green;
  }
}
