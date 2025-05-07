import 'package:local_auth/local_auth.dart';

class BiometricHelper {
  static final _auth = LocalAuthentication();

  static Future<bool> authenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isDeviceSupported) return false;

      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint to login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }
}
