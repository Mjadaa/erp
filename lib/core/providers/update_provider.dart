import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:auto_updater/auto_updater.dart';

const _feedUrl =
    'https://raw.githubusercontent.com/Mjadaa/erp/main/appcast.xml';
const _currentVersion = '1.0.0';

class UpdateProvider extends ChangeNotifier {
  bool _updateAvailable = false;
  String _latestVersion = '';

  bool get updateAvailable => _updateAvailable;
  String get latestVersion => _latestVersion;

  Future<void> checkForUpdates() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(_feedUrl));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      final match =
          RegExp(r'<sparkle:shortVersionString>(.*?)<\/').firstMatch(body);
      if (match != null) {
        final latest = match.group(1)!.trim();
        if (_isNewer(latest, _currentVersion)) {
          _latestVersion = latest;
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
    try {
      await autoUpdater.setFeedURL(_feedUrl);
      await autoUpdater.checkForUpdates();
    } catch (_) {}
  }
}
