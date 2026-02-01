import 'package:flutter/material.dart';
import 'dart:async';
import 'package:juvapay/services/cache_service.dart';

enum DeepLinkType {
  passwordReset,
  emailVerification,
  payment,
  invitation,
  unknown,
}

class DeepLink {
  final DeepLinkType type;
  final Map<String, String> parameters;
  final Uri originalUri;

  DeepLink({
    required this.type,
    required this.parameters,
    required this.originalUri,
  });
}

class DeepLinkService {
  final GlobalKey<NavigatorState> navigatorKey;
  final CacheService cacheService;
  final Map<String, DeepLinkType> _linkPatterns = {
    r'reset-password': DeepLinkType.passwordReset,
    r'verify-email': DeepLinkType.emailVerification,
    r'payment': DeepLinkType.payment,
    r'invite': DeepLinkType.invitation,
  };

  DeepLinkService({required this.navigatorKey, required this.cacheService});

  Future<DeepLink> parseDeepLink(Uri uri) async {
    try {
      // Extract host/path
      final host = uri.host;
      final path = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : '';

      // Determine link type
      DeepLinkType type = DeepLinkType.unknown;

      for (final pattern in _linkPatterns.entries) {
        if (host.contains(pattern.key) || path.contains(pattern.key)) {
          type = pattern.value;
          break;
        }
      }

      // Parse query parameters
      final parameters = <String, String>{};
      uri.queryParameters.forEach((key, value) {
        parameters[key] = value;
      });

      return DeepLink(type: type, parameters: parameters, originalUri: uri);
    } catch (error) {
      return DeepLink(
        type: DeepLinkType.unknown,
        parameters: {},
        originalUri: uri,
      );
    }
  }

  Future<bool> validateDeepLink(DeepLink deepLink) async {
    // Validate token expiration, signature, etc.
    switch (deepLink.type) {
      case DeepLinkType.passwordReset:
        return _validatePasswordResetLink(deepLink);
      case DeepLinkType.emailVerification:
        return _validateEmailVerificationLink(deepLink);
      default:
        return true;
    }
  }

  Future<bool> _validatePasswordResetLink(DeepLink deepLink) async {
    final token = deepLink.parameters['token'];
    if (token == null || token.length < 20) return false;

    // Additional validation logic here

    return true;
  }

  Future<bool> _validateEmailVerificationLink(DeepLink deepLink) async {
    final token = deepLink.parameters['token'];
    final type = deepLink.parameters['type'];

    if (token == null || type == null) return false;

    // Additional validation logic here

    return true;
  }
}
