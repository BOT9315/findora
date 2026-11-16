import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AppLockService {
  AppLockService._internal();
  static final AppLockService instance = AppLockService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _keyAppLockEnabled = 'app_lock_enabled';
  static const String _keyEncryptionKey = 'vault_master_key';

  /// Check whether biometric hardware is available
  Future<bool> canCheckBiometrics() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometrics: $e');
      return false;
    }
  }

  /// Check if user has enabled App Lock
  Future<bool> isAppLockEnabled() async {
    try {
      final val = await _secureStorage.read(key: _keyAppLockEnabled);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Toggle App Lock status
  Future<bool> setAppLockEnabled(bool enabled) async {
    try {
      if (enabled) {
        final authenticated = await authenticate(
          reason:
              'Please authenticate to enable App Lock for FindMyStuff AI',
        );
        if (!authenticated) return false;
      }
      await _secureStorage.write(
          key: _keyAppLockEnabled, value: enabled ? 'true' : 'false');
      return true;
    } catch (e) {
      debugPrint('Error setting app lock enabled: $e');
      return false;
    }
  }

  /// Authenticate user via fingerprint, face, or device PIN
  Future<bool> authenticate({required String reason}) async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) {
        // Bypass on devices without biometric support (e.g. emulators)
        return true;
      }

      return await _auth.authenticate(
        localizedReason: reason,
      );
    } on PlatformException catch (e) {
      debugPrint('Authentication platform error: $e');
      return false;
    } catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    }
  }

  /// Get or create master secure key stored in platform secure keystore
  Future<String> getOrCreateMasterKey() async {
    var key = await _secureStorage.read(key: _keyEncryptionKey);
    if (key == null || key.isEmpty) {
      final randomBytes = List<int>.generate(
          32, (i) => (DateTime.now().microsecondsSinceEpoch + i * 37) % 256);
      key = randomBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      await _secureStorage.write(key: _keyEncryptionKey, value: key);
    }
    return key;
  }
}
