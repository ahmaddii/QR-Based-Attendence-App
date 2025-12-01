import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';

class QRScannerService {
  // Singleton pattern
  static final QRScannerService _instance = QRScannerService._internal();
  factory QRScannerService() => _instance;
  QRScannerService._internal();

  MobileScannerController? _controller;

  // ------------------- SZABIST CAMPUS GEOFENCE -------------------
  static const double campusLat = 33.6772392337357;
  static const double campusLng = 73.06810471533771;
  static const double campusRadiusMeters = 250; // adjust as needed

  // ------------------- LOCATION CHECK -------------------
  Future<bool> _isInsideCampus() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return false;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied.');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print(
            'Location permission permanently denied. Please enable it from settings.');
        return false;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        campusLat,
        campusLng,
      );

      return distance <= campusRadiusMeters;
    } catch (e) {
      print('Error fetching location: $e');
      return false;
    }
  }

  // ------------------- CONTROLLER METHODS -------------------
  void setController(MobileScannerController controller) {
    _controller = controller;
  }

  Future<void> startScanning({Function(String)? onError}) async {
    bool onCampus = await _isInsideCampus();
    if (!onCampus) {
      if (onError != null) {
        onError(
            'Cannot start scanning: You must enable location and be on campus.');
      } else {
        print(
            'Cannot start scanning: You must enable location and be on campus.');
      }
      return;
    }
    _controller?.start();
  }

  void stopScanning() {
    _controller?.stop();
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
  }

  Future<void> toggleFlash() async {
    await _controller?.toggleTorch();
  }

  Future<void> flipCamera() async {
    await _controller?.switchCamera();
  }

  // ------------------- SCAN HANDLER -------------------
  Future<void> handleScan(String qrData, Function(String) onSuccess,
      {Function(String)? onError}) async {
    bool onCampus = await _isInsideCampus();
    if (!onCampus) {
      if (onError != null) {
        onError(
            'You must enable location and be on campus to mark attendance.');
      }
      return;
    }

    // If inside campus, allow scan processing
    onSuccess(qrData);
  }
}
