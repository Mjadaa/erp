import 'package:auto_updater/auto_updater.dart';

// ← غيّر هذا الرابط لرابط الـ appcast.xml على GitHub الخاص بك
const _feedUrl =
    'https://raw.githubusercontent.com/Mjadaa/erp/main/appcast.xml';

Future<void> checkForUpdates() async {
  try {
    await autoUpdater.setFeedURL(_feedUrl);
    await autoUpdater.checkForUpdates();
  } catch (_) {}
}
