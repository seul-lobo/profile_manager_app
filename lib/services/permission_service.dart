import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  static const String _permissionsRequestedKey = 'permissions_requested';

  static Future<bool> hasRequestedPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_permissionsRequestedKey) ?? false;
    } catch (e) {
      print('Error checking permissions requested: $e');
      return false;
    }
  }

  static Future<void> setPermissionsRequested() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_permissionsRequestedKey, true);
    } catch (e) {
      print('Error setting permissions requested: $e');
    }
  }

  static Future<bool> requestAllPermissions(BuildContext context) async {
    try {
      //check if we've already requested permissions
      if (await hasRequestedPermissions()) {
        return true;
      }

      if (!context.mounted) return false;

      //show explanation dialog first
      final shouldRequest = await _showPermissionExplanationDialog(context);
      if (!shouldRequest) return false;

      //request all necessary permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.photos,
        Permission.storage,
      ].request();

      //mark that we've requested permissions
      await setPermissionsRequested();

      //check if all critical permissions are granted
      bool allGranted = true;
      List<String> deniedPermissions = [];

      statuses.forEach((permission, status) {
        if (status.isDenied || status.isPermanentlyDenied) {
          allGranted = false;
          String permissionName = _getPermissionName(permission);
          deniedPermissions.add(permissionName);
        }
      });

      if (!allGranted && context.mounted) {
        await _showPermissionsDeniedDialog(context, deniedPermissions);
      }

      return allGranted;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  static Future<bool> _showPermissionExplanationDialog(
      BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.security, color: Colors.blue),
                SizedBox(width: 8),
                Text('Permissions Required'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Manager needs the following permissions to work properly:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.camera_alt, size: 20, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(child: Text('Camera - Take profile pictures')),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.photo_library, size: 20, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text('Photos - Select images from gallery')),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.folder, size: 20, color: Colors.purple),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text('Storage - Upload and save documents')),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'You can change these permissions later in your device settings.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Grant Permissions'),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<void> _showPermissionsDeniedDialog(
    BuildContext context,
    List<String> deniedPermissions,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Permissions Denied'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The following permissions were denied:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...deniedPermissions.map(
              (permission) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• $permission'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Some features may not work properly. You can enable these permissions later in your device settings.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  static String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera';
      case Permission.photos:
        return 'Photos';
      case Permission.storage:
        return 'Storage';
      default:
        return 'Unknown';
    }
  }

  //individual permission check methods for specific use cases
  static Future<bool> checkCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  static Future<bool> checkPhotosPermission() async {
    return await Permission.photos.isGranted;
  }

  static Future<bool> checkStoragePermission() async {
    return await Permission.storage.isGranted;
  }

  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      if (context.mounted) {
        _showSinglePermissionDialog(
          context,
          'Camera Permission',
          'Camera access is needed to take profile pictures.',
          Icons.camera_alt,
        );
      }
      return false;
    }

    return status.isGranted;
  }

  static Future<bool> requestPhotosPermission(BuildContext context) async {
    final status = await Permission.photos.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      if (context.mounted) {
        _showSinglePermissionDialog(
          context,
          'Photos Permission',
          'Photos access is needed to select images from your gallery.',
          Icons.photo_library,
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
        _showSinglePermissionDialog(
          context,
          'Storage Permission',
          'Storage access is needed to save and upload documents.',
          Icons.folder,
        );
      }
      return false;
    }

    return status.isGranted;
  }

  static void _showSinglePermissionDialog(
    BuildContext context,
    String title,
    String message,
    IconData icon,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: Colors.orange),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }
}
