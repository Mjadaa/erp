import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

const _feedUrl =
    'https://raw.githubusercontent.com/Mjadaa/erp/main/appcast.xml';
const _currentVersion = '1.2.3';

class UpdateProvider extends ChangeNotifier {
  bool _updateAvailable = false;
  String _latestVersion = '';
  String _downloadUrl = '';
  bool _isDownloading = false;
  double _downloadProgress = 0;
  bool _downloadError = false;
  bool _readyToInstall = false;

  bool get updateAvailable => _updateAvailable;
  String get latestVersion => _latestVersion;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  bool get downloadError => _downloadError;
  bool get readyToInstall => _readyToInstall;

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
          _downloadAndInstall(); // auto-start silently, intentionally unawaited
        }
      }
    } catch (_) {}
  }

  Future<void> _downloadAndInstall() async {
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

      // Show "restarting" message for 2 seconds
      _isDownloading = false;
      _readyToInstall = true;
      notifyListeners();

      await Future.delayed(const Duration(seconds: 2));

      final scriptPath = '${tempDir.path}\\erp_updater.ps1';
      final batchPath = '${tempDir.path}\\erp_updater.bat';

      final script = '''
\$ErrorActionPreference = "SilentlyContinue"
Start-Sleep -Seconds 5
\$zip = [System.IO.Path]::GetFullPath("$zipPath")
\$ext = [System.IO.Path]::GetFullPath("$extractDir")
\$app = [System.IO.Path]::GetFullPath("$appDir")
\$exe = [System.IO.Path]::GetFullPath("$appExe")
try { Remove-Item -Path \$ext -Recurse -Force } catch {}
Expand-Archive -Path \$zip -DestinationPath \$ext -Force
\$found = Get-ChildItem -Path \$ext -Filter "erp_system.exe" -Recurse | Select-Object -First 1
if (\$found) {
  Copy-Item -Path ("\$(\$found.DirectoryName)\\*") -Destination \$app -Recurse -Force
}
Start-Process -FilePath \$exe
Start-Sleep -Seconds 2
try { Remove-Item -Path \$zip -Force } catch {}
try { Remove-Item -Path \$ext -Recurse -Force } catch {}
''';

      final batch = '@echo off\r\n'
          'start "" /b powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "$scriptPath"\r\n';

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
      _readyToInstall = false;
      _downloadError = true;
      notifyListeners();
    }
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

  void retryUpdate() {
    _downloadError = false;
    notifyListeners();
    _downloadAndInstall();
  }
}
