import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

const _feedUrl =
    'https://raw.githubusercontent.com/Mjadaa/erp/main/appcast.xml';
const _currentVersion = '1.0.0'; // TEST — revert to '1.2.1' after testing

class UpdateProvider extends ChangeNotifier {
  bool _updateAvailable = false;
  String _latestVersion = '';
  String _downloadUrl = '';
  bool _isDownloading = false;
  double _downloadProgress = 0;
  bool _downloadError = false;

  bool get updateAvailable => _updateAvailable;
  String get latestVersion => _latestVersion;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  bool get downloadError => _downloadError;

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
    if (_downloadUrl.isEmpty) return;

    _isDownloading = true;
    _downloadError = false;
    _downloadProgress = 0;
    notifyListeners();

    try {
      final tempDir = await getTemporaryDirectory();
      final zipPath = '${tempDir.path}\\erp_update.zip';
      final extractDir = '${tempDir.path}\\erp_update';
      final appExe = Platform.resolvedExecutable;
      final appDir = File(appExe).parent.path;

      // Download ZIP with progress
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(_downloadUrl));
      final response = await request.close();

      final totalBytes = response.contentLength;
      var receivedBytes = 0;
      final sink = File(zipPath).openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          _downloadProgress = receivedBytes / totalBytes;
          notifyListeners();
        }
      }
      await sink.close();
      client.close();

      // Batch file → launches PowerShell script detached
      final scriptPath = '${tempDir.path}\\erp_updater.ps1';
      final batchPath = '${tempDir.path}\\erp_updater.bat';

      final script = '''
Start-Sleep -Seconds 5
if (Test-Path "$extractDir") { Remove-Item -Path "$extractDir" -Recurse -Force }
Expand-Archive -Path "$zipPath" -DestinationPath "$extractDir" -Force
\$exe = Get-ChildItem -Path "$extractDir" -Filter "erp_system.exe" -Recurse | Select-Object -First 1
if (\$exe) {
  Copy-Item -Path "\$(\$exe.DirectoryName)\\*" -Destination "$appDir" -Recurse -Force
}
Start-Process -FilePath "$appExe"
Start-Sleep -Seconds 2
Remove-Item -Path "$zipPath" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$extractDir" -Recurse -Force -ErrorAction SilentlyContinue
''';

      final batch = '@echo off\r\n'
          'start "" /min powershell -ExecutionPolicy Bypass -File "$scriptPath"\r\n';

      await File(scriptPath).writeAsString(script);
      await File(batchPath).writeAsString(batch);

      await Process.start(
        'cmd',
        ['/c', batchPath],
        mode: ProcessStartMode.detached,
        runInShell: false,
      );

      exit(0);
    } catch (_) {
      _isDownloading = false;
      _downloadError = true;
      notifyListeners();
    }
  }

  void resetError() {
    _downloadError = false;
    notifyListeners();
  }
}
