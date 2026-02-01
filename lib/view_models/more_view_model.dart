// view_models/more_view_model.dart - Complete fixed version

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart';
import '../services/theme_service.dart';
import '../views/auth/login_view.dart';

class MoreViewModel extends ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final ThemeService _themeService;

  bool _isLoading = false;
  String _fullName = 'Guest User';
  String _username = 'loading...';
  String _email = '';
  String? _profileUrl;
  bool _isMember = false;

  bool get isLoading => _isLoading;
  String get fullName => _fullName;
  String get username => _username;
  String get email => _email;
  String? get profileUrl => _profileUrl;
  bool get isMember => _isMember;
  
  // Theme related
  ThemeMode get themeMode => _themeService.themeMode;

  MoreViewModel(this._themeService) {
    fetchProfileData();
    _setupAuthListener();
  }

  // Listen to auth state changes
  void _setupAuthListener() {
    _authService.authStateChanges.listen((authState) {
      final session = authState.session;
      if (session != null) {
        // Refresh profile when auth state changes
        fetchProfileData();
      } else {
        // Clear data when logged out
        clearProfileData();
      }
    });
  }

  // Updated to use consistent method
  Future<void> fetchProfileData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Use the consistent method from auth service
      final profile = await _authService.getUserProfileConsistent();
      
      if (profile != null && profile.isNotEmpty) {
        _fullName = profile['full_name']?.toString() ?? 'User';
        _username = profile['username']?.toString() ?? 'user';
        _email = profile['email']?.toString() ?? '';
        _profileUrl = profile['avatar_url'];
        _isMember = profile['is_member'] == true;
        
        debugPrint('MoreViewModel - Profile loaded successfully');
        debugPrint('Full Name: $_fullName, Email: $_email, Is Member: $_isMember');
      } else {
        debugPrint('MoreViewModel - Profile is empty or null');
        
        // Fallback: try without email
        final basicProfile = await _authService.getUserProfile();
        if (basicProfile != null) {
          _fullName = basicProfile['full_name']?.toString() ?? 'User';
          _username = basicProfile['username']?.toString() ?? 'user';
          _profileUrl = basicProfile['avatar_url'];
          _isMember = basicProfile['is_member'] == true;
          
          // Get email from auth user
          final user = getCurrentUser();
          _email = user?.email ?? '';
        } else {
          // Last resort: get from auth user
          final user = getCurrentUser();
          if (user != null) {
            _fullName = user.userMetadata?['full_name']?.toString() ?? 
                       user.email?.split('@').first ?? 'User';
            _email = user.email ?? '';
            _username = _fullName.toLowerCase().replaceAll(' ', '_');
          }
        }
      }
    } catch (e) {
      debugPrint("MoreViewModel - Profile fetch error: $e");
      
      // Emergency fallback
      final user = getCurrentUser();
      if (user != null) {
        _fullName = user.email?.split('@').first ?? 'User';
        _email = user.email ?? '';
        _username = _fullName.toLowerCase().replaceAll(' ', '_');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Sign out from Supabase
      await _authService.signOut();
      clearProfileData();

      // 2. Clear stack and navigate to Login
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log out: ${e.toString()}')),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get current user from auth service
  User? getCurrentUser() {
    return _authService.getCurrentUser();
  }

  bool isAuthenticated() {
    return _authService.isAuthenticated();
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? username,
    String? phone,
    String? avatarUrl,
    String? bio,
    String? gender,
    String? religion,
    int? dobDay,
    String? dobMonth,
    int? dobYear,
    int? stateId,
    int? lgaId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.updateProfile(
        fullName: fullName,
        username: username,
        phone: phone,
        avatarUrl: avatarUrl,
        bio: bio,
        gender: gender,
        religion: religion,
        dobDay: dobDay,
        dobMonth: dobMonth,
        dobYear: dobYear,
        stateId: stateId,
        lgaId: lgaId,
      );

      // If update was successful, refresh local data
      if (result['success'] == true) {
        if (fullName != null) _fullName = fullName;
        if (username != null) _username = username;
        if (avatarUrl != null) _profileUrl = avatarUrl;
        
        // Refresh all data
        await fetchProfileData();
      }

      return result;
    } catch (e) {
      debugPrint("Profile update error: $e");
      return {'success': false, 'message': 'Failed to update profile: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.uploadAvatar(imageFile);

      // If upload was successful, update local profile URL and refresh
      if (result['success'] == true && result['url'] != null) {
        _profileUrl = result['url'];
        await fetchProfileData(); // Refresh all data
      }

      return result;
    } catch (e) {
      debugPrint("Profile picture upload error: $e");
      return {
        'success': false,
        'message': 'Failed to upload profile picture: $e',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    await fetchProfileData();
  }

  // Helper method to get user profile data
  Future<Map<String, dynamic>?> getUserProfileData() async {
    try {
      return await _authService.getUserProfileConsistent();
    } catch (e) {
      debugPrint("Error getting user profile: $e");
      return null;
    }
  }

  // Get user email
  String? getUserEmail() {
    return _email.isNotEmpty ? _email : getCurrentUser()?.email;
  }

  // Get user phone number
  String? getUserPhone() {
    final user = getCurrentUser();
    return user?.phone;
  }

  // Get user creation date
  DateTime? getUserCreatedAt() {
    final user = getCurrentUser();
    if (user?.createdAt == null) return null;

    try {
      return DateTime.tryParse(user!.createdAt);
    } catch (e) {
      debugPrint("Error parsing user createdAt: $e");
      return null;
    }
  }

  // Get user metadata
  Map<String, dynamic>? getUserMetadata() {
    final user = getCurrentUser();
    return user?.userMetadata;
  }

  // Get user app metadata
  Map<String, dynamic>? getUserAppMetadata() {
    final user = getCurrentUser();
    return user?.appMetadata;
  }

  // Check if email is verified
  bool isEmailVerified() {
    final user = getCurrentUser();
    if (user?.emailConfirmedAt == null) return false;

    try {
      return user!.emailConfirmedAt!.isNotEmpty;
    } catch (e) {
      debugPrint("Error checking email verification: $e");
      return false;
    }
  }

  // Get formatted date string
  String? getUserCreatedAtFormatted() {
    final date = getUserCreatedAt();
    if (date == null) return null;

    return "${date.day}/${date.month}/${date.year}";
  }

  // Get relative time
  String? getUserCreatedAtRelative() {
    final date = getUserCreatedAt();
    if (date == null) return null;

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Get user ID
  String? getUserId() {
    final user = getCurrentUser();
    return user?.id;
  }

  // Get last sign in date
  DateTime? getLastSignInAt() {
    final user = getCurrentUser();
    if (user?.lastSignInAt == null) return null;

    try {
      return DateTime.tryParse(user!.lastSignInAt!);
    } catch (e) {
      debugPrint("Error parsing lastSignInAt: $e");
      return null;
    }
  }

  // Check if user has confirmed phone
  bool isPhoneConfirmed() {
    final user = getCurrentUser();
    if (user?.phoneConfirmedAt == null) return false;
    return user!.phoneConfirmedAt!.isNotEmpty;
  }

  // Get user role from app metadata
  String? getUserRole() {
    final metadata = getUserAppMetadata();
    return metadata?['role']?.toString();
  }

  // Check if user is admin
  bool isAdmin() {
    final role = getUserRole();
    return role?.toLowerCase() == 'admin';
  }

  // Get all user data as a map
  Map<String, dynamic> getAllUserData() {
    final user = getCurrentUser();
    if (user == null) return {};

    return {
      'id': user.id,
      'email': _email.isNotEmpty ? _email : user.email,
      'phone': user.phone,
      'fullName': _fullName,
      'username': _username,
      'profileUrl': _profileUrl,
      'isMember': _isMember,
      'createdAt': user.createdAt,
      'emailConfirmedAt': user.emailConfirmedAt,
      'phoneConfirmedAt': user.phoneConfirmedAt,
      'lastSignInAt': user.lastSignInAt,
      'userMetadata': user.userMetadata,
      'appMetadata': user.appMetadata,
      'isEmailVerified': isEmailVerified(),
      'isPhoneConfirmed': isPhoneConfirmed(),
      'formattedCreatedAt': getUserCreatedAtFormatted(),
      'relativeCreatedAt': getUserCreatedAtRelative(),
      'lastSignInFormatted': getLastSignInAt() != null
          ? "${getLastSignInAt()!.day}/${getLastSignInAt()!.month}/${getLastSignInAt()!.year}"
          : null,
    };
  }

  // Theme mode setter
  void setThemeMode(ThemeMode mode) {
    _themeService.setThemeMode(mode);
    notifyListeners();
  }

  // Update email display
  void updateEmailDisplay(String email) {
    _email = email;
    notifyListeners();
  }

  // Check if profile is complete
  bool get isProfileComplete {
    return _fullName.isNotEmpty && _username.isNotEmpty && _email.isNotEmpty;
  }

  // Get profile completion percentage
  double get profileCompletionPercentage {
    int totalFields = 3;
    int completedFields = 0;

    if (_fullName.isNotEmpty) completedFields++;
    if (_username.isNotEmpty) completedFields++;
    if (_email.isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }

  // Clear all profile data
  void clearProfileData() {
    _fullName = 'Guest User';
    _username = 'loading...';
    _email = '';
    _profileUrl = null;
    _isMember = false;
    notifyListeners();
  }

  // Load profile data with retry
  Future<void> fetchProfileDataWithRetry({int maxRetries = 3}) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        await fetchProfileData();
        return;
      } catch (e) {
        retryCount++;
        debugPrint("Profile fetch retry $retryCount failed: $e");

        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
      }
    }

    debugPrint("Failed to fetch profile after $maxRetries attempts");
  }
}