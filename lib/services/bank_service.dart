// bank_service.dart - Complete updated version
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class BankModel {
  final String name;
  final String code;

  BankModel({required this.name, required this.code});

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(name: json['name'] ?? '', code: json['code'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'code': code};
  }
}

class UserBankDetails {
  final String userId;
  final String bankName;
  final String bankCode;
  final String accountNumber;
  final String accountName;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserBankDetails({
    required this.userId,
    required this.bankName,
    required this.bankCode,
    required this.accountNumber,
    required this.accountName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserBankDetails.fromJson(Map<String, dynamic> json) {
    return UserBankDetails(
      userId: json['user_id']?.toString() ?? '',
      bankName: json['bank_name']?.toString() ?? '',
      bankCode: json['bank_code']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      accountName: json['account_name']?.toString() ?? '',
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'bank_name': bankName,
      'bank_code': bankCode,
      'account_number': accountNumber,
      'account_name': accountName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    return '****${accountNumber.substring(accountNumber.length - 4)}';
  }
}

class BankService {
  final SupabaseClient _supabase = Supabase.instance.client;
  

  // Flutterwave Configuration - USE ENVIRONMENT VARIABLE IN PRODUCTION
  static final String _flutterwaveBaseUrl = dotenv.get('FLUTTERWAVE_BASE_URL');
  static final String _flutterwaveSecretKey =
       dotenv.get('FLUTTERWAVE_SECRET_KEY'); // Replace with env var

  // Get list of Nigerian banks from Flutterwave API
  Future<List<BankModel>> getBanks() async {
    try {
      final url = Uri.parse('$_flutterwaveBaseUrl/banks/NG');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_flutterwaveSecretKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final banks =
              (data['data'] as List)
                  .map((bank) => BankModel.fromJson(bank))
                  .toList();

          // Sort banks alphabetically
          banks.sort((a, b) => a.name.compareTo(b.name));
          return banks;
        } else {
          developer.log('Failed to fetch banks: ${data['message']}');
          return _getLocalBanks(); // Fallback to local list
        }
      } else {
        developer.log('Bank API failed with status: ${response.statusCode}');
        return _getLocalBanks(); // Fallback to local list
      }
    } catch (e) {
      developer.log('Error fetching banks: $e');
      return _getLocalBanks(); // Fallback to local list
    }
  }

  // Local fallback bank list
  List<BankModel> _getLocalBanks() {
    return [
      BankModel(name: 'Access Bank', code: '044'),
      BankModel(name: 'First Bank of Nigeria', code: '011'),
      BankModel(name: 'Guaranty Trust Bank', code: '058'),
      BankModel(name: 'Zenith Bank', code: '057'),
      BankModel(name: 'United Bank for Africa', code: '033'),
      BankModel(name: 'Sterling Bank', code: '232'),
      BankModel(name: 'Fidelity Bank', code: '070'),
      BankModel(name: 'Union Bank of Nigeria', code: '032'),
      BankModel(name: 'Wema Bank', code: '035'),
      BankModel(name: 'Ecobank Nigeria', code: '050'),
    ];
  }

  // Get user's bank details from database
  Future<UserBankDetails?> getUserBankDetails() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response =
          await _supabase
              .from('user_bank_details')
              .select()
              .eq('user_id', user.id)
              .maybeSingle();

      if (response != null) {
        // Ensure response is a Map
        final data =
            response is Map<String, dynamic>
                ? response
                : Map<String, dynamic>.from(response as Map);
        return UserBankDetails.fromJson(data);
      }
      return null;
    } catch (e) {
      developer.log('Error getting bank details: $e');
      return null;
    }
  }

  // Verify account number with Flutterwave API
  Future<Map<String, dynamic>> verifyAccountNumber({
    required String bankCode,
    required String accountNumber,
  }) async {
    try {
      // Validate input
      if (accountNumber.length != 10) {
        return {
          'success': false,
          'message': 'Account number must be exactly 10 digits',
          'account_name': null,
          'bank_name': null,
        };
      }

      // Validate numeric
      if (double.tryParse(accountNumber) == null) {
        return {
          'success': false,
          'message': 'Account number must contain only numbers',
          'account_name': null,
          'bank_name': null,
        };
      }

      // Call Flutterwave Account Verification API
      final url = Uri.parse('$_flutterwaveBaseUrl/accounts/resolve');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_flutterwaveSecretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'account_number': accountNumber,
          'account_bank': bankCode,
        }),
      );

      final data = jsonDecode(response.body);
      developer.log('Flutterwave verification response: $data');

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'] ?? 'Account verified successfully',
          'account_name': data['data']['account_name'],
          'bank_name': data['data']['bank_name'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Account verification failed',
          'account_name': null,
          'bank_name': null,
        };
      }
    } catch (e) {
      developer.log('Error verifying account: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your internet connection',
        'account_name': null,
        'bank_name': null,
      };
    }
  }

  // Save/Update bank details to database
  Future<Map<String, dynamic>> saveBankDetails({
    required String bankCode,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return {'success': false, 'message': 'User not authenticated'};
    }

    try {
      // Validate input
      if (accountNumber.length != 10) {
        return {
          'success': false,
          'message': 'Account number must be 10 digits',
        };
      }

      if (double.tryParse(accountNumber) == null) {
        return {'success': false, 'message': 'Invalid account number'};
      }

      // Check for duplicates (prevent multiple users with same account number)
      final existingAccount =
          await _supabase
              .from('user_bank_details')
              .select()
              .eq('account_number', accountNumber)
              .neq('user_id', user.id)
              .maybeSingle();

      if (existingAccount != null) {
        return {
          'success': false,
          'message':
              'This account number is already registered by another user',
        };
      }

      // Prepare data
      final data = {
        'user_id': user.id,
        'bank_name': bankName,
        'bank_code': bankCode,
        'account_number': accountNumber,
        'account_name': accountName,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Check if record exists
      final existingRecord =
          await _supabase
              .from('user_bank_details')
              .select()
              .eq('user_id', user.id)
              .maybeSingle();

      List<dynamic> response;

      if (existingRecord != null) {
        // Update existing
        response =
            await _supabase
                .from('user_bank_details')
                .update(data)
                .eq('user_id', user.id)
                .select();
      } else {
        // Insert new
        response =
            await _supabase.from('user_bank_details').insert(data).select();
      }

      // Success if we got a response
      if (response.isNotEmpty) {
        final bankDetails = UserBankDetails.fromJson(
          response.first as Map<String, dynamic>,
        );

        return {
          'success': true,
          'message':
              existingRecord != null
                  ? 'Bank details updated successfully'
                  : 'Bank details saved successfully',
          'data': bankDetails,
        };
      } else {
        return {'success': false, 'message': 'Failed to save bank details'};
      }
    } catch (e) {
      developer.log('Error saving bank details: $e');
      return {'success': false, 'message': 'Failed to save bank details: $e'};
    }
  }

  // Delete bank details
  Future<Map<String, dynamic>> deleteBankDetails() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return {'success': false, 'message': 'User not authenticated'};
    }

    try {
      await _supabase.from('user_bank_details').delete().eq('user_id', user.id);

      return {'success': true, 'message': 'Bank details deleted successfully'};
    } catch (e) {
      developer.log('Error deleting bank details: $e');
      return {'success': false, 'message': 'Failed to delete bank details: $e'};
    }
  }
}
