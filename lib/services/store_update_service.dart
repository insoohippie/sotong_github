import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 앱스토어 / 플레이스토어 업데이트 페이지 이동
class StoreUpdateService {
  StoreUpdateService._();

  /// App Store Connect 앱 ID (출시 후 설정, 예: '1234567890')
  /// 비어 있으면 bundleId로 iTunes Lookup API에서 자동 조회합니다.
  static const iosAppStoreId = '';

  static const _iosBundleId = 'io.sotong.app';
  static const _lookupCountry = 'kr';

  static Future<String> currentVersionLabel() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  static Future<void> openStoreListing() async {
    final uri = await _resolveStoreUri();
    if (uri == null) {
      throw StoreListingUnavailableException(
        '스토어 페이지를 찾을 수 없습니다. 앱 출시 후 다시 시도해주세요.',
      );
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      throw StoreListingUnavailableException('스토어를 열 수 없습니다.');
    }
  }

  static Future<Uri?> _resolveStoreUri() async {
    if (Platform.isAndroid) {
      return _androidStoreUri();
    }
    if (Platform.isIOS) {
      return _iosStoreUri();
    }
    return null;
  }

  static Future<Uri?> _androidStoreUri() async {
    final info = await PackageInfo.fromPlatform();
    final packageName = info.packageName;

    final marketUri = Uri.parse('market://details?id=$packageName');
    if (await canLaunchUrl(marketUri)) {
      return marketUri;
    }

    return Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName',
    );
  }

  static Future<Uri?> _iosStoreUri() async {
    if (iosAppStoreId.isNotEmpty) {
      return Uri.parse('https://apps.apple.com/app/id$iosAppStoreId');
    }

    final appStoreId = await _lookupIosAppStoreId(_iosBundleId);
    if (appStoreId == null) return null;

    return Uri.parse('https://apps.apple.com/app/id$appStoreId');
  }

  static Future<String?> _lookupIosAppStoreId(String bundleId) async {
    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.getUrl(
        Uri.parse(
          'https://itunes.apple.com/lookup?bundleId=$bundleId&country=$_lookupCountry',
        ),
      );
      final response = await request.close();
      if (response.statusCode != 200) return null;

      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final results = decoded['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final trackId = results.first['trackId'];
      if (trackId == null) return null;

      return trackId.toString();
    } catch (e, stackTrace) {
      debugPrint('StoreUpdateService lookup failed: $e\n$stackTrace');
      return null;
    } finally {
      client?.close(force: true);
    }
  }
}

class StoreListingUnavailableException implements Exception {
  StoreListingUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}
