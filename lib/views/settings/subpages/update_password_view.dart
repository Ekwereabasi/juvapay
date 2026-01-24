import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:juvapay/services/supabase_auth_service.dart';

class UpdatePasswordView extends StatefulWidget {
  const UpdatePasswordView({super.key});

  @override
  State<UpdatePasswordView> createState() => _UpdatePasswordViewState();
}

class _UpdatePasswordViewState extends State<UpdatePasswordView> {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  /// Unified helper to show SnackBar at the top
  void _showTopSnackBar(String message, {required bool isSuccess}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isSuccess ? Colors.green.shade600 : theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 160,
          left: 20,
          right: 20,
        ),
      ),
    );
  }

  Future<void> _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if new passwords match
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showTopSnackBar("New passwords do not match", isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // First, check if current password is correct by trying to sign in
      final currentUser = _authService.getCurrentUser();
      if (currentUser?.email == null) {
        _showTopSnackBar("User not found", isSuccess: false);
        return;
      }

      final signInResult = await _authService.signIn(
        email: currentUser!.email!,
        password: _currentPasswordController.text,
      );

      if (signInResult['success'] == true) {
        // Now update the password using Supabase auth.updateUser
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: _newPasswordController.text),
        );

        if (mounted) {
          _showTopSnackBar("Password Updated Successfully", isSuccess: true);
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        }
      } else {
        _showTopSnackBar(
          signInResult['message'] ?? "Incorrect current password",
          isSuccess: false,
        );
      }
    } on AuthException catch (e) {
      // FIXED: Use class name to call static method
      _showTopSnackBar(
        SupabaseAuthService.getErrorMessage(e),
        isSuccess: false,
      );
    } catch (e) {
      _showTopSnackBar(
        "An error occurred. Please try again: ${e.toString()}",
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Update Your Password",
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Current Password"),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _currentPasswordController,
                hint: "Enter your current password",
                isVisible: _isCurrentPasswordVisible,
                onToggle:
                    () => setState(
                      () =>
                          _isCurrentPasswordVisible =
                              !_isCurrentPasswordVisible,
                    ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter current password";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 25),

              _buildLabel("New Password"),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _newPasswordController,
                hint: "Enter your new password",
                isVisible: _isNewPasswordVisible,
                onToggle:
                    () => setState(
                      () => _isNewPasswordVisible = !_isNewPasswordVisible,
                    ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return "Password must be at least 6 characters";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 25),

              _buildLabel("Confirm New Password"),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _confirmPasswordController,
                hint: "Confirm your new password",
                isVisible: _isConfirmPasswordVisible,
                onToggle:
                    () => setState(
                      () =>
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible,
                    ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please confirm your new password";
                  }
                  if (value != _newPasswordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),

              Padding(
                padding: const EdgeInsets.only(top: 10.0, left: 4),
                child: Text(
                  "Password must contain at least 6 characters",
                  style: TextStyle(color: theme.hintColor, fontSize: 13),
                ),
              ),

              const SizedBox(height: 40),

              // --- Change Password Button ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleUpdatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            "CHANGE PASSWORD",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        validator: validator,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          icon: const Icon(Icons.lock_outline),
          hintText: hint,
          hintStyle: TextStyle(color: theme.hintColor),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off_outlined,
              color: theme.hintColor,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}
