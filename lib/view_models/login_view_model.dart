import 'package:flutter/material.dart';
import '../services/supabase_auth_service.dart';
import '../../widgets/app_bottom_navbar.dart';


class LoginViewModel extends ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // The View calls this function to start the sign-in process
  Future<void> signIn(
    String emailOrUsername,
    String password,
    BuildContext context,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Call the auth service signIn method
      final result = await _authService.signIn(
        email: emailOrUsername,
        password: password,
      );

      // Check if sign-in was successful
      if (result['success'] == true) {
        _errorMessage = null;

        // If sign-in is successful, navigate to the home screen
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const AppBottomNavigationBar(),
            ),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        // Show error from the result
        _errorMessage = result['message'] ?? 'Login failed. Please try again.';
      }
    } catch (e) {
      // Catch unexpected errors
      _errorMessage = 'An unexpected error occurred. Please try again.';
      debugPrint('Login error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if user is already logged in
  bool isUserLoggedIn() {
    return _authService.isAuthenticated();
  }

  // Sign out method
  Future<void> signOut() async {
    await _authService.signOut();
    notifyListeners();
  }
}
