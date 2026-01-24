import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/login_view_model.dart';
import '../../widgets/app_bottom_navbar.dart';
import 'signup_view_single_page.dart';

// ----------------------------------------------------------------------
// 1. The Provider Wrapper
// ----------------------------------------------------------------------

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginViewModel>(
      create: (_) => LoginViewModel(),
      // ✅ FIXED: Added safe padding for the dialog content
      child: const Padding(
        padding: EdgeInsets.all(24.0),
        child: LoginScreenContent(),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 2. The Stateful Content
// ----------------------------------------------------------------------

class LoginScreenContent extends StatefulWidget {
  const LoginScreenContent({super.key});

  @override
  State<LoginScreenContent> createState() => _LoginScreenContentState();
}

class _LoginScreenContentState extends State<LoginScreenContent> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ HELPER: Consistent Input Decoration (Same as Signup Page)
  InputDecoration _inputDecoration(
    String labelText, {
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Theme.of(context).hintColor),
      prefixIcon:
          prefixIcon != null
              ? IconTheme(
                data: IconThemeData(color: Theme.of(context).hintColor),
                child: prefixIcon,
              )
              : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2.0,
        ),
      ),
    );
  }

  // --- Submission Logic ---
  void handleLogin(LoginViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Attempt to sign in
    await viewModel.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      context,
    );

    // ✅ Navigation Logic
    if (context.mounted && viewModel.errorMessage == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AppBottomNavigationBar()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<LoginViewModel>(context);
    final theme = Theme.of(context); // Cache theme for cleaner code

    return Material(
      borderRadius: BorderRadius.circular(15.0),
      elevation: 16,
      // ✅ FIXED: Dynamic background color (Dark/Light compatible)
      color: theme.cardColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Close Button ---
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close, color: theme.iconTheme.color),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                // --- Header Text ---
                Text(
                  'Log in to JuvaPay',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Login to enjoy all amazing features on JuvaPay.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // --- Email Input ---
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  // ✅ FIXED: Using unified decoration
                  decoration: _inputDecoration(
                    'Username or Email',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator:
                      (v) => v!.isEmpty ? 'Enter email or username' : null,
                ),
                const SizedBox(height: 16),

                // --- Password Input ---
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  // ✅ FIXED: Using unified decoration & Theme colors
                  decoration: _inputDecoration(
                    'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: theme.hintColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Enter your password' : null,
                ),

                const SizedBox(height: 24),

                // --- Error Message ---
                if (viewModel.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      viewModel.errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // --- Login Button (Primary) ---
                ElevatedButton(
                  onPressed:
                      viewModel.isLoading ? null : () => handleLogin(viewModel),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      viewModel.isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            'LOG IN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                ),

                const SizedBox(height: 12),

                // --- Forgot Password ---
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                Divider(color: theme.dividerColor),

                const SizedBox(height: 12),
                Text(
                  "Don't have an account on JuvaPay?",
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // --- Sign Up Button (Secondary) ---
                // ✅ FIXED: Switched to OutlinedButton for better hierarchy
                // and used PrimaryColor instead of random Blue.
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SignupViewSinglePage(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      side: BorderSide(color: theme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'SIGN UP NOW',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
