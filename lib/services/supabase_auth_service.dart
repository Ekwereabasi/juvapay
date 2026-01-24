// supabase_auth_service.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================
  // AUTHENTICATION METHODS (Email Only)
  // ==========================================

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );

      if (response.user == null) throw Exception('Failed to create account');

      final needsConfirmation = response.session == null;

      return {
        'success': true,
        'user_id': response.user!.id,
        'needs_confirmation': needsConfirmation,
        'message':
            needsConfirmation
                ? 'Registration successful! Please check your email to verify your account.'
                : 'Account created successfully.',
      };
    } catch (e) {
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return {
        'success': true,
        'user_id': response.user?.id,
        'message': 'Signed in successfully',
      };
    } catch (e) {
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  Future<void> signOut() async => await _supabase.auth.signOut();

  // ==========================================
  // PROFILE & DEMOGRAPHICS
  // ==========================================

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
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // 1. Update Auth Metadata
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            if (fullName != null) 'full_name': fullName,
            if (phone != null) 'phone': phone,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          },
        ),
      );

      // 2. Update Profiles Table
      await _supabase
          .from('profiles')
          .update({
            if (fullName != null) 'full_name': fullName,
            if (username != null) 'username': username,
            if (phone != null) 'phone_number': phone,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
            if (bio != null) 'bio': bio,
            if (gender != null) 'gender': gender,
            if (religion != null) 'religion': religion,
            if (dobDay != null) 'dob_day': dobDay,
            if (dobMonth != null) 'dob_month': dobMonth,
            if (dobYear != null) 'dob_year': dobYear,
            if (stateId != null) 'state_id': stateId,
            if (lgaId != null) 'lga_id': lgaId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      return {'success': true, 'message': 'Profile updated successfully'};
    } catch (e) {
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // 1. Define the file path (Folder = User ID, Filename = profile.png)
      // Using a consistent filename like 'profile.png' ensures old ones are overwritten
      final String path = '${user.id}/profile.png';

      // 2. Upload the file to the 'avatars' bucket
      await _supabase.storage
          .from('avatars')
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(
              upsert: true,
            ), // Overwrites if exists
          );

      // 3. Get the Public URL
      final String publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(path);

      // 4. Update the 'profiles' table with the new URL
      await _supabase
          .from('profiles')
          .update({
            'avatar_url': publicUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      return {
        'success': true,
        'url': publicUrl,
        'message': 'Profile picture updated!',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  User? getCurrentUser() => _supabase.auth.currentUser;

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response =
          await _supabase.from('profiles').select().eq('id', user.id).single();

      return response;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // ==========================================
  // SESSION & UTILITIES
  // ==========================================

  bool isAuthenticated() => _supabase.auth.currentUser != null;

    Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  


  static String getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'User already registered':
          return 'This email is already in use.';
        case 'Invalid login credentials':
          return 'Incorrect email or password.';
        case 'Email not confirmed':
          return 'Please verify your email address.';
        default:
          return error.message;
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
