import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerService {
  // Singleton pattern
  static final QRScannerService _instance = QRScannerService._internal();
  factory QRScannerService() => _instance;
  QRScannerService._internal();

  MobileScannerController? _controller;

  // ------------------- CONTROLLER METHODS -------------------
  void setController(MobileScannerController controller) {
    _controller = controller;
  }

  void startScanning() {
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
  Future<void> handleScan(
    String qrData,
    Function(String) onSuccess, {
    Function(String)? onError,
  }) async {
    try {
      // Simply pass scanned QR data
      onSuccess(qrData);
    } catch (e) {
      if (onError != null) {
        onError('Error scanning QR: $e');
      }
    }
  }
}
