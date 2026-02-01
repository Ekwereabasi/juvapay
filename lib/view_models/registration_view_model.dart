import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_registration_model.dart';
import '../services/supabase_auth_service.dart';
import '../services/state_service.dart';
import '../models/location_models.dart';
import 'dart:async';


class RegistrationViewModel extends ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final StateService _stateService = StateService();
  final UserRegistrationModel _registrationData = UserRegistrationModel();

  bool _isLoading = false;
  String? _errorMessage;
  String? _errorType;

  List<StateModel> _states = [];
  List<LgaModel> _lgas = [];

  // Getters
  UserRegistrationModel get registrationData => _registrationData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get errorType => _errorType;
  List<StateModel> get states => _states;
  List<LgaModel> get lgas => _lgas;

  // Constructor
  RegistrationViewModel();

  // Initialize and load states with error handling
  Future<void> initializeData() async {
    if (_states.isEmpty && !_isLoading) {
      await _loadStates();
    }
  }

  Future<void> _loadStates() async {
    _isLoading = true;
    notifyListeners();

    try {
      _states = await _stateService.getStates().timeout(
        const Duration(seconds: 15),
      );
      _errorMessage = null;
      _errorType = null;
    } on TimeoutException catch (_) {
      _errorMessage = 'Loading states timed out. Please check your connection.';
      _errorType = 'timeout_error';
    } on SocketException catch (_) {
      _errorMessage = 'Network error. Please check your internet connection.';
      _errorType = 'network_error';
    } catch (e) {
      _errorMessage = 'Could not load states. Please try again.';
      _errorType = 'data_error';
      debugPrint('Error loading states: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLgas(StateModel state) async {
    _registrationData.selectedState = state;
    _registrationData.selectedLga = null;
    _lgas = [];
    _isLoading = true;
    notifyListeners();

    try {
      _lgas = await _stateService
          .getLgasByState(state.id)
          .timeout(const Duration(seconds: 15));
      _errorMessage = null;
      _errorType = null;
    } on TimeoutException catch (_) {
      _errorMessage = 'Loading LGAs timed out. Please check your connection.';
      _errorType = 'timeout_error';
    } on SocketException catch (_) {
      _errorMessage = 'Network error. Please check your internet connection.';
      _errorType = 'network_error';
    } catch (e) {
      _errorMessage = 'Could not load LGAs. Please try again.';
      _errorType = 'data_error';
      debugPrint('Error loading LGAs: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void setLGA(LgaModel lga) {
    _registrationData.selectedLga = lga;
    notifyListeners();
  }

  void setBasicDetails({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) {
    _registrationData.email = email.trim().toLowerCase();
    _registrationData.password = password;
    _registrationData.username = username.trim();
    _registrationData.fullName = fullName.trim();
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }

  void setProfileImage(File image) {
    _registrationData.profileImage = image;
    notifyListeners();
  }

  void setPhone(String phone) {
    _registrationData.phone = phone.trim();
    notifyListeners();
  }

  // --- MAIN SIGNUP LOGIC WITH COMPREHENSIVE ERROR HANDLING ---
  Future<Map<String, dynamic>> processSignup(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    _errorType = null;
    notifyListeners();

    // Client-side validation before making network calls
    final validationResult = _validateRegistrationData();
    if (!validationResult['valid']) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': validationResult['message'],
        'error_type': 'validation_error',
      };
    }

    try {
      debugPrint('📝 Starting registration process...');

      // 1. Sign Up using the auth service
      final signUpResult = await _authService.signUp(
        email: _registrationData.email,
        password: _registrationData.password,
        fullName: _registrationData.fullName,
        phone: _registrationData.phone,
      );

      debugPrint(
        '📝 Signup result: ${signUpResult['success']} - ${signUpResult['message']}',
      );

      // Check if signup was successful
      if (!signUpResult['success']) {
        _errorMessage = signUpResult['message'];
        _errorType = signUpResult['error_type'];
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': _errorMessage,
          'error_type': _errorType,
        };
      }

      // 2. Upload Profile Image if provided (non-critical operation)
      await _handleProfileImageUpload();

      // 3. Update User Profile with additional information (non-critical)
      await _updateProfileWithLocation();

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'message': signUpResult['message'] ?? 'Account created successfully!',
        'user_id': signUpResult['user_id'],
        'warning': signUpResult['warning'],
      };
    } on TimeoutException catch (e) {
      _handleError(
        'Request timed out. Please check your connection and try again.',
        'timeout_error',
      );
    } on SocketException catch (e) {
      _handleError(
        'Network error. Please check your internet connection and try again.',
        'network_error',
      );
    } on AuthException catch (e) {
      _handleError(SupabaseAuthService.getErrorMessage(e), 'auth_error');
    } on PostgrestException catch (e) {
      _handleError('Database error: ${e.message}', 'database_error');
    } catch (e) {
      _handleError(
        'An unexpected error occurred. Please try again.',
        'unknown_error',
      );
      debugPrint('Unexpected registration error: $e');
    }

    return {
      'success': false,
      'message': _errorMessage,
      'error_type': _errorType,
    };
  }

  Map<String, dynamic> _validateRegistrationData() {
    // Validate email
    if (_registrationData.email.isEmpty) {
      return {'valid': false, 'message': 'Email address is required.'};
    }

    if (!isValidEmail(_registrationData.email)) {
      return {'valid': false, 'message': 'Please enter a valid email address.'};
    }

    // Validate password
    if (_registrationData.password.isEmpty) {
      return {'valid': false, 'message': 'Password is required.'};
    }

    if (_registrationData.password.length < 6) {
      return {
        'valid': false,
        'message': 'Password must be at least 6 characters.',
      };
    }

    // Validate full name
    if (_registrationData.fullName.isEmpty) {
      return {'valid': false, 'message': 'Full name is required.'};
    }

    if (_registrationData.fullName.length < 2) {
      return {'valid': false, 'message': 'Please enter your full name.'};
    }

    // Validate username
    if (_registrationData.username.isEmpty) {
      return {'valid': false, 'message': 'Username is required.'};
    }

    if (_registrationData.username.length < 3) {
      return {
        'valid': false,
        'message': 'Username must be at least 3 characters.',
      };
    }

    if (!isValidUsername(_registrationData.username)) {
      return {
        'valid': false,
        'message':
            'Username can only contain letters, numbers, and underscores.',
      };
    }

    // Validate location
    if (_registrationData.selectedState == null) {
      return {'valid': false, 'message': 'Please select your state.'};
    }

    if (_registrationData.selectedLga == null) {
      return {'valid': false, 'message': 'Please select your LGA.'};
    }

    return {'valid': true, 'message': 'All validations passed'};
  }

  Future<void> _handleProfileImageUpload() async {
    if (_registrationData.profileImage != null) {
      try {
        final uploadResult = await _authService.uploadAvatar(
          _registrationData.profileImage!,
        );

        if (uploadResult['success']) {
          debugPrint('✅ Profile image uploaded successfully');
        } else {
          debugPrint(
            "⚠️ Profile picture upload failed: ${uploadResult['message']}",
          );
        }
      } catch (e) {
        debugPrint("⚠️ Error uploading profile image: $e");
        // Don't throw - image upload is non-critical
      }
    }
  }

  Future<void> _updateProfileWithLocation() async {
    try {
      await _authService.updateProfile(
        fullName: _registrationData.fullName,
        username: _registrationData.username,
        phone: _registrationData.phone,
        avatarUrl: null, // Already handled in separate step
        stateId: _registrationData.selectedState?.id,
        lgaId: _registrationData.selectedLga?.id,
      );
      debugPrint('✅ Profile updated with location data');
    } catch (e) {
      debugPrint("⚠️ Profile update error (non-critical): $e");
      // Continue even if profile update fails
    }
  }

  void _handleError(String message, String type) {
    _errorMessage = message;
    _errorType = type;
    _isLoading = false;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }

  // Reset all registration data
  void reset() {
    _registrationData.reset();
    _lgas.clear();
    _errorMessage = null;
    _errorType = null;
    _isLoading = false;
    notifyListeners();
  }

  // Validate email format
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  // Validate username
  bool isValidUsername(String username) {
    if (username.length < 3 || username.length > 30) return false;
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    return usernameRegex.hasMatch(username);
  }

  // Check if all required fields are filled
  bool get isBasicInfoComplete {
    return _registrationData.email.isNotEmpty &&
        _registrationData.password.isNotEmpty &&
        _registrationData.username.isNotEmpty &&
        _registrationData.fullName.isNotEmpty;
  }

  // Check if location info is complete
  bool get isLocationInfoComplete {
    return _registrationData.selectedState != null &&
        _registrationData.selectedLga != null;
  }

  // Check if registration is ready to submit
  bool get isReadyToSubmit {
    return isBasicInfoComplete && isLocationInfoComplete;
  }

  // Get registration progress (0.0 to 1.0)
  double get registrationProgress {
    double progress = 0.0;

    // Basic info (50%)
    if (_registrationData.email.isNotEmpty) progress += 0.125;
    if (_registrationData.password.isNotEmpty) progress += 0.125;
    if (_registrationData.username.isNotEmpty) progress += 0.125;
    if (_registrationData.fullName.isNotEmpty) progress += 0.125;

    // Location info (50%)
    if (_registrationData.selectedState != null) progress += 0.25;
    if (_registrationData.selectedLga != null) progress += 0.25;

    return progress.clamp(0.0, 1.0);
  }

  // Check network connectivity status
  Future<bool> checkNetworkConnectivity() async {
    try {
      // Simple check by attempting to connect
      await _stateService.getStates().timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }
}
