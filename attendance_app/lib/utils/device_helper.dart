import 'package:device_info_plus/device_info_plus.dart';

class DeviceHelper {
  static Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // unique for the device
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }
}
