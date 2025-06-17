import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  static Future<bool> requestStoragePermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.manageExternalStorage,
        Permission.audio,
      ].request();

      return statuses.values.any((s) => s.isGranted);
    } else if (Platform.isIOS) {
      final status = await Permission.mediaLibrary.request();
      return status.isGranted;
    }
    return false;
  }

  static Future<void> handlePermanentDenial() async {
    if (Platform.isAndroid) {

      if (await Permission.manageExternalStorage.isPermanentlyDenied ||
          await Permission.audio.isPermanentlyDenied) {
        await openAppSettings();
      }
    } else if (Platform.isIOS) {
      if (await Permission.mediaLibrary.isPermanentlyDenied) {
        await openAppSettings();
      }
    }
  }


}

Future<void> requestNotificationPermission() async {
  if (Platform.isAndroid) {
    if (await Permission.notification.isDenied ||
        await Permission.notification.isPermanentlyDenied) {
      await Permission.notification.request();
    }
  }
}

