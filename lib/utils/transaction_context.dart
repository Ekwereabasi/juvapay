import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;

class TransactionContext {
  TransactionContext({
    this.ipAddress,
    this.userAgent,
    this.deviceId,
    this.location,
  });

  final String? ipAddress;
  final String? userAgent;
  final String? deviceId;
  final Map<String, dynamic>? location;

  static Future<TransactionContext> fetch() async {
    final ip = await _getPublicIpAddress();
    final userAgent = await _getUserAgent();
    final deviceId = await _getDeviceId();
    final location = await _getLocationFromIp(ip);

    return TransactionContext(
      ipAddress: ip,
      userAgent: userAgent,
      deviceId: deviceId,
      location: location,
    );
  }

  static Future<String?> _getPublicIpAddress() async {
    final fallbackUrls = [
      'https://api.ipify.org',
      'https://api64.ipify.org',
      'https://ipinfo.io/ip',
      'https://ifconfig.me/ip',
      'https://icanhazip.com',
    ];

    for (final url in fallbackUrls) {
      try {
        final response = await http
            .get(Uri.parse(url), headers: {'Accept': 'text/plain'})
            .timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final ip = response.body.trim();
          if (ip.isNotEmpty) {
            return ip;
          }
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  static Future<Map<String, dynamic>?> _getLocationFromIp(String? ip) async {
    if (ip == null || ip.isEmpty) return null;

    final urls = [
      'https://ipinfo.io/$ip/json',
      'https://ipapi.co/$ip/json/',
    ];

    for (final url in urls) {
      try {
        final response = await http
            .get(Uri.parse(url), headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            return data;
          }
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  static Future<String?> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        return null;
      }
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      }
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor;
      }
      if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return windowsInfo.deviceId;
      }
      if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return macInfo.systemGUID;
      }
      if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        return linuxInfo.machineId;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<String> _getUserAgent() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appName = packageInfo.appName;
      final appVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      String deviceInfo = 'Unknown';
      final devicePlugin = DeviceInfoPlugin();

      if (kIsWeb) {
        deviceInfo = 'Web';
      } else if (Platform.isAndroid) {
        final androidInfo = await devicePlugin.androidInfo;
        deviceInfo =
            'Android ${androidInfo.version.release} (${androidInfo.model})';
      } else if (Platform.isIOS) {
        final iosInfo = await devicePlugin.iosInfo;
        deviceInfo = 'iOS ${iosInfo.systemVersion} (${iosInfo.model})';
      } else if (Platform.isWindows) {
        final windowsInfo = await devicePlugin.windowsInfo;
        deviceInfo = 'Windows ${windowsInfo.displayVersion}';
      } else if (Platform.isMacOS) {
        final macInfo = await devicePlugin.macOsInfo;
        deviceInfo = 'macOS ${macInfo.kernelVersion} (${macInfo.model})';
      } else if (Platform.isLinux) {
        final linuxInfo = await devicePlugin.linuxInfo;
        deviceInfo = 'Linux ${linuxInfo.prettyName}';
      }

      return '$appName/$appVersion ($buildNumber) $deviceInfo';
    } catch (_) {
      return 'JuvaPay/${DateTime.now().year}';
    }
  }
}
