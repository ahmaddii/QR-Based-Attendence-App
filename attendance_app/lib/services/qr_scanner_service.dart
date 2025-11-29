import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerService {
  // Singleton pattern
  static final QRScannerService _instance = QRScannerService._internal();
  factory QRScannerService() => _instance;
  QRScannerService._internal();

  MobileScannerController? _controller;

  // Set controller
  void setController(MobileScannerController controller) {
    _controller = controller;
  }

  // Start scanning
  void startScanning() {
    _controller?.start();
  }

  // Stop scanning
  void stopScanning() {
    _controller?.stop();
  }

  // Dispose controller
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }

  // Toggle flash
  Future<void> toggleFlash() async {
    await _controller?.toggleTorch();
  }

  // Flip camera
  Future<void> flipCamera() async {
    await _controller?.switchCamera();
  }
}
