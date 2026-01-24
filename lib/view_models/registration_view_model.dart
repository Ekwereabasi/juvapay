import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_registration_model.dart';
import '../services/supabase_auth_service.dart';
import '../services/state_service.dart'; // Add this import
import '../models/location_models.dart';

class RegistrationViewModel extends ChangeNotifier {
  // Use the service classes
  final SupabaseAuthService _authService = SupabaseAuthService();
  final StateService _stateService = StateService(); // Add StateService
  final UserRegistrationModel _registrationData = UserRegistrationModel();

  bool _isLoading = false;
  String? _errorMessage;

  List<StateModel> _states = [];
  List<LgaModel> _lgas = [];

  // Getters
  UserRegistrationModel get registrationData => _registrationData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<StateModel> get states => _states;
  List<LgaModel> get lgas => _lgas;

  // Constructor
  RegistrationViewModel();

  // NEW METHOD: Explicitly initialize and load states
  Future<void> initializeData() async {
    // Only fetch if data is missing and we aren't already loading
    if (_states.isEmpty && !_isLoading) {
      await _loadStates();
    }
  }

  // Use StateService to load states
  Future<void> _loadStates() async {
    _isLoading = true;
    notifyListeners();

    try {
      _states = await _stateService.getStates();
      _errorMessage = null;
    } catch (e) {
      _errorMessage =
          'Could not load states: ${e.toString().replaceFirst('Exception: ', '')}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLgas(StateModel state) async {
    _registrationData.selectedState = state;
    _registrationData.selectedLga = null; // Reset LGA
    _lgas = []; // Clear old LGAs
    _isLoading = true;
    notifyListeners();

    try {
      _lgas = await _stateService.getLgasByState(state.id);
      _errorMessage = null;
    } catch (e) {
      _errorMessage =
          'Could not load LGAs: ${e.toString().replaceFirst('Exception: ', '')}';
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
    _registrationData.email = email;
    _registrationData.password = password;
    _registrationData.username = username;
    _registrationData.fullName = fullName;
    _errorMessage = null;
    notifyListeners();
  }

  void setProfileImage(File image) {
    _registrationData.profileImage = image;
    notifyListeners();
  }

  // Add phone number if needed
  void setPhone(String phone) {
    _registrationData.phone = phone;
    notifyListeners();
  }

  // --- MAIN SIGNUP LOGIC ---
  Future<Map<String, dynamic>> processSignup(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Validate required fields
    if (_registrationData.selectedState == null ||
        _registrationData.selectedLga == null) {
      _errorMessage = "Please select your State and LGA.";
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _errorMessage,
        'needs_confirmation': false,
      };
    }

    // Validate other required fields
    if (_registrationData.email.isEmpty ||
        _registrationData.password.isEmpty ||
        _registrationData.fullName.isEmpty) {
      _errorMessage = "Please fill in all required fields.";
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _errorMessage,
        'needs_confirmation': false,
      };
    }

    try {
      // 1. Sign Up using the auth service
      final signUpResult = await _authService.signUp(
        email: _registrationData.email,
        password: _registrationData.password,
        fullName: _registrationData.fullName,
        phone: _registrationData.phone, // Use phone if available
      );

      // Check if signup was successful
      if (!signUpResult['success']) {
        _errorMessage = signUpResult['message'];
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': _errorMessage,
          'needs_confirmation': false,
        };
      }

      // 2. Upload Profile Image if provided
      String? avatarUrl;
      if (_registrationData.profileImage != null) {
        final uploadResult = await _authService.uploadAvatar(
          _registrationData.profileImage!,
        );

        if (uploadResult['success']) {
          avatarUrl = uploadResult['url'];
        } else {
          debugPrint(
            "Profile picture upload failed: ${uploadResult['message']}",
          );
        }
      }

      // 3. Update User Profile with additional information
      final updateResult = await _authService.updateProfile(
        fullName: _registrationData.fullName,
        username: _registrationData.username,
        phone: _registrationData.phone,
        avatarUrl: avatarUrl,
        bio: null, // Add bio if you have it
        gender: null, // Add gender if you have it
        religion: null, // Add religion if you have it
        dobDay: null, // Add dobDay if you have it
        dobMonth: null, // Add dobMonth if you have it
        dobYear: null, // Add dobYear if you have it
        stateId: _registrationData.selectedState?.id,
        lgaId: _registrationData.selectedLga?.id,
      );

      if (!updateResult['success']) {
        debugPrint("Profile update failed: ${updateResult['message']}");
        // Continue anyway since auth was successful
      }

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'message': signUpResult['message'] ?? 'Registration successful',
        'needs_confirmation': signUpResult['needs_confirmation'] ?? false,
        'user_id': signUpResult['user_id'],
      };
    } on AuthException catch (e) {
      // Catch Auth errors
      _errorMessage = SupabaseAuthService.getErrorMessage(e);
    } on PostgrestException catch (e) {
      // Catch Database errors
      _errorMessage = 'Database Error: ${e.message}';
    } catch (e) {
      // Catch all other unexpected errors
      _errorMessage = 'Error: ${e.toString()}';
    }

    // Set loading to false and return failure state on any catch block
    _isLoading = false;
    notifyListeners();
    return {
      'success': false,
      'message': _errorMessage,
      'needs_confirmation': false,
    };
  }

  // Simplified signup method for basic registration
  Future<Map<String, dynamic>> signupUser() async {
    _isLoading = true;
    notifyListeners();

    // Basic validation
    if (!isReadyToSubmit) {
      _errorMessage = 'Please fill in all required fields';
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }

    try {
      // Call the auth service signUp method
      final result = await _authService.signUp(
        email: _registrationData.email,
        password: _registrationData.password,
        fullName: _registrationData.fullName,
        phone: _registrationData.phone,
      );

      _isLoading = false;
      notifyListeners();

      if (result['success'] == true) {
        // If registration successful, update profile with additional info
        await _updateUserProfileAfterSignup();
      }

      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = SupabaseAuthService.getErrorMessage(e);
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  Future<void> _updateUserProfileAfterSignup() async {
    try {
      String? avatarUrl;

      // Upload profile image if provided
      if (_registrationData.profileImage != null) {
        final uploadResult = await _authService.uploadAvatar(
          _registrationData.profileImage!,
        );
        if (uploadResult['success']) {
          avatarUrl = uploadResult['url'];
        }
      }

      // Update profile with location and other data
      await _authService.updateProfile(
        fullName: _registrationData.fullName,
        username: _registrationData.username,
        phone: _registrationData.phone,
        avatarUrl: avatarUrl,
        stateId: _registrationData.selectedState?.id,
        lgaId: _registrationData.selectedLga?.id,
      );
    } catch (e) {
      debugPrint("Error updating profile after signup: $e");
      // Don't throw here - profile update is secondary to registration
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Reset all registration data
  void reset() {
    _registrationData.reset();
    _lgas.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // Validate email format
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Validate password strength
  bool isValidPassword(String password) {
    // At least 8 characters, contains uppercase, lowercase, and number
    if (password.length < 8) return false;

    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);

    return hasUppercase && hasLowercase && hasNumber;
  }

  // Get password strength text
  String getPasswordStrengthText(String password) {
    if (password.isEmpty) return 'Enter a password';
    if (password.length < 8) return 'Too short';

    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);

    final score =
        [hasUppercase, hasLowercase, hasNumber].where((e) => e).length;

    switch (score) {
      case 3:
        return 'Strong';
      case 2:
        return 'Medium';
      case 1:
        return 'Weak';
      default:
        return 'Very weak';
    }
  }

  // Get password strength color
  Color getPasswordStrengthColor(String password) {
    if (password.isEmpty) return Colors.grey;
    if (password.length < 8) return Colors.red;

    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);

    final score =
        [hasUppercase, hasLowercase, hasNumber].where((e) => e).length;

    switch (score) {
      case 3:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.yellow;
      default:
        return Colors.red;
    }
  }

  // Validate username
  bool isValidUsername(String username) {
    // Username should be 3-20 characters, alphanumeric and underscores only
    if (username.length < 3 || username.length > 20) return false;
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    return usernameRegex.hasMatch(username);
  }

  // Validate full name
  bool isValidFullName(String fullName) {
    // Full name should be at least 2 characters
    if (fullName.length < 2) return false;

    // Should contain at least one space (first and last name)
    return fullName.contains(' ');
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

    return progress;
  }

  // Get state name by ID (helper method)
  Future<String?> getStateName(int stateId) async {
    final state = await _stateService.getStateById(stateId);
    return state?.name;
  }

  // Get LGA name by ID (helper method)
  Future<String?> getLgaName(int lgaId) async {
    final lga = await _stateService.getLgaById(lgaId);
    return lga?.name;
  }

  // Pre-populate location if user already selected before
  Future<void> preSelectLocation(int? stateId, int? lgaId) async {
    if (stateId != null) {
      final state = await _stateService.getStateById(stateId);
      if (state != null) {
        _registrationData.selectedState = state;
        await loadLgas(state);

        if (lgaId != null) {
          for (final lga in _lgas) {
            if (lga.id == lgaId) {
              _registrationData.selectedLga = lga;
              break;
            }
          }
        }
      }
    }
    notifyListeners();
  }
}
