import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  static Future<bool> requestAllPermissions() async {
    if (Platform.isAndroid) {
      final requiredPermissions = [
        Permission.manageExternalStorage,
        Permission.audio,
        Permission.notification,
      ];

      // Filter out already granted permissions
      final toRequest = <Permission>[];
      for (final perm in requiredPermissions) {
        if (!await perm.isGranted) {
          toRequest.add(perm);
        }
      }

      // If everything is already granted
      if (toRequest.isEmpty) return true;

      // Request only the missing ones
      final statuses = await toRequest.request();

      // If any permission is permanently denied
      if (statuses.values.any((s) => s.isPermanentlyDenied)) {
        await openAppSettings();
        return false;
      }

      // Return true if all requested are granted
      return statuses.values.every((s) => s.isGranted);
    }

    if (Platform.isIOS) {
      final mediaLib = Permission.mediaLibrary;

      if (await mediaLib.isGranted) return true;

      final status = await mediaLib.request();
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }

      return status.isGranted;
    }

    return false;
  }
}


