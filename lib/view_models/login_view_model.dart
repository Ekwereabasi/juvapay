// lib/view_models/login_view_model.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart'; // Adjust path if needed
import '../views/home/home_view.dart'; // Adjust path if needed

class LoginViewModel extends ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // The View calls this function to start the sign-in process
  Future<void> signIn(String emailOrUsername, String password, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Assuming SupabaseAuthService has a signIn method that takes email/password
      await _authService.signIn(email: emailOrUsername, password: password);

      // If sign-in is successful, navigate to the home screen
      if (context.mounted) {
         // Use pushAndRemoveUntil to clear the login history
         Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
             MaterialPageRoute(builder: (_) => const HomeView()), 
             (Route<dynamic> route) => false,
         );
      }

    } on AuthException catch (e) {
      // Catch specific Supabase authentication errors
      _errorMessage = e.message;
      
    } catch (e) {
      // Catch other unexpected errors
      _errorMessage = 'An unexpected error occurred. Please try again.';
      
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}