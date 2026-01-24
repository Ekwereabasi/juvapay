import 'package:flutter/material.dart';
import 'dart:io'; // For File class
import 'package:supabase_flutter/supabase_flutter.dart'; // For User class
import '../services/supabase_auth_service.dart';
import '../services/theme_service.dart';
import '../views/auth/login_view.dart';

class MoreViewModel extends ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final ThemeService _themeService;

  bool _isLoading = false;
  String _fullName = 'Guest User';
  String _username = 'loading...';
  String? _profileUrl;

  bool get isLoading => _isLoading;
  String get fullName => _fullName;
  String get username => _username;
  String? get profileUrl => _profileUrl;

  MoreViewModel(this._themeService) {
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final profile = await _authService.getUserProfile();
      if (profile != null) {
        _fullName = profile['full_name'] ?? 'User';
        _username = profile['username'] ?? 'user';
        _profileUrl = profile['avatar_url'];
      }
    } catch (e) {
      debugPrint("Profile fetch error: $e");
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

      // If upload was successful, update local profile URL
      if (result['success'] == true && result['url'] != null) {
        _profileUrl = result['url'];
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
      return await _authService.getUserProfile();
    } catch (e) {
      debugPrint("Error getting user profile: $e");
      return null;
    }
  }

  // Get user email from current user
  String? getUserEmail() {
    final user = getCurrentUser();
    return user?.email;
  }

  // Get user phone number
  String? getUserPhone() {
    final user = getCurrentUser();
    return user?.phone;
  }

  // Get user creation date - FIXED: Parse string to DateTime
  DateTime? getUserCreatedAt() {
    final user = getCurrentUser();
    if (user?.createdAt == null) return null;

    try {
      // createdAt is a String, parse it to DateTime
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

  // Check if email is verified - FIXED: Check emailConfirmedAt as String
  bool isEmailVerified() {
    final user = getCurrentUser();
    if (user?.emailConfirmedAt == null) return false;

    try {
      // emailConfirmedAt is a String, if it's not null/empty, email is verified
      return user!.emailConfirmedAt!.isNotEmpty;
    } catch (e) {
      debugPrint("Error checking email verification: $e");
      return false;
    }
  }

  // Alternative: Get formatted date string
  String? getUserCreatedAtFormatted() {
    final date = getUserCreatedAt();
    if (date == null) return null;

    return "${date.day}/${date.month}/${date.year}";
  }

  // Alternative: Get relative time (e.g., "2 days ago")
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

  // Get last sign in date - FIXED: Parse lastSignInAt as String
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
      'email': user.email,
      'phone': user.phone,
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
      'lastSignInFormatted':
          getLastSignInAt() != null
              ? "${getLastSignInAt()!.day}/${getLastSignInAt()!.month}/${getLastSignInAt()!.year}"
              : null,
    };
  }
}
