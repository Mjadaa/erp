import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

const _feedUrl =
    'https://raw.githubusercontent.com/Mjadaa/erp/main/appcast.xml';
const _currentVersion = '1.2.1';

class UpdateProvider extends ChangeNotifier {
  bool _updateAvailable = false;
  String _latestVersion = '';
  String _downloadUrl = '';

  bool get updateAvailable => _updateAvailable;
  String get latestVersion => _latestVersion;

  Future<void> checkForUpdates() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(_feedUrl));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      final versionMatch =
          RegExp(r'<sparkle:shortVersionString>(.*?)<\/').firstMatch(body);
      final urlMatch =
          RegExp(r'url="(https://github\.com/[^"]+\.zip)"').firstMatch(body);

      if (versionMatch != null) {
        final latest = versionMatch.group(1)!.trim();
        if (_isNewer(latest, _currentVersion)) {
          _latestVersion = latest;
          _downloadUrl = urlMatch?.group(1) ?? '';
          _updateAvailable = true;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  bool _isNewer(String latest, String current) {
    final l = latest.split('.').map(int.tryParse).whereType<int>().toList();
    final c = current.split('.').map(int.tryParse).whereType<int>().toList();
    for (int i = 0; i < 3; i++) {
      final lv = i < l.length ? l[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
  }

  Future<void> installUpdate() async {
    final url = _downloadUrl.isNotEmpty
        ? _downloadUrl
        : 'https://github.com/Mjadaa/erp/releases/latest';
    await Process.run('cmd', ['/c', 'start', '', url]);
  }
}
