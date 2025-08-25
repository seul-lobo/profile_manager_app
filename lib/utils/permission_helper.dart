import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionHelper {
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Camera Permission',
          'Camera access is needed to take profile pictures. Please grant permission in settings.',
        );
      }
      return false;
    }

    return status.isGranted;
  }

  static Future<bool> requestGalleryPermission(BuildContext context) async {
    Permission permission;

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      permission = Permission.photos;
    } else {
      // For Android 13+
      permission = Permission.photos; // or Permission.mediaLibrary
    }

    final status = await permission.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Gallery Permission',
          'Gallery access is needed to select and save images. Please grant permission in settings.',
        );
      }
      return false;
    }

    return status.isGranted;
  }

  static Future<bool> requestStoragePermission(BuildContext context) async {
    final status = await Permission.storage.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Storage Permission',
          'Storage access is needed to save and upload files. Please grant permission in settings.',
        );
      }
      return false;
    }

    return status.isGranted;
  }

  static void _showPermissionDeniedDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }
}
