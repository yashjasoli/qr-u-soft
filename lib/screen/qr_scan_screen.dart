import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../service/scan_history_service.dart';
import 'result_screen.dart';
import 'scan_history_screen.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen>
    with TickerProviderStateMixin {
  bool isScanned = false;
  bool isTorchOn = false;

  final MobileScannerController controller =
  MobileScannerController(torchEnabled: false);

  final ImagePicker _picker = ImagePicker();

  // Focus indicator
  Offset? _focusPoint;
  bool _showFocus = false;

  // Laser animation
  late AnimationController laserController;
  late Animation<double> laserAnimation;

  @override
  void initState() {
    super.initState();

    laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    laserAnimation =
        Tween<double>(begin: 0, end: 1).animate(laserController);
  }

  @override
  void dispose() {
    controller.dispose();
    laserController.dispose();
    super.dispose();
  }

  // 🔔 Scan vibration
  void _scanVibration() {
    HapticFeedback.mediumImpact();
  }

  // 🖼 Pick image & scan
  Future<void> _pickImageAndScan() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final capture = await controller.analyzeImage(image.path);

    if (capture == null || capture.barcodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No QR code found')),
      );
      return;
    }

    _handleResult(capture.barcodes.first.rawValue ?? '');
  }

  // 🔎 HANDLE RESULT (URL + PAYMENT)
  Future<void> _handleResult(String value) async {
    if (isScanned) return;
    isScanned = true;

    _scanVibration();
    await ScanHistoryService().saveScan(value);

    final v = value.trim();
    Uri? uri;

    // 💳 PAYMENT GATEWAYS
    if (v.startsWith('upi://') ||
        v.startsWith('paytm://') ||
        v.startsWith('phonepe://') ||
        v.startsWith('tez://') ||
        v.startsWith('bhim://')) {
      uri = Uri.parse(v);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        setState(() => isScanned = false);
        return;
      }
    }

    // 🌐 WEBSITE / APP LINKS
    if (!v.startsWith('http') && v.contains('.')) {
      uri = Uri.parse('https://$v');
    } else {
      uri = Uri.tryParse(v);
    }

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() => isScanned = false);
      return;
    }

    // 📝 NORMAL TEXT
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultScreen(text: value)),
    ).then((_) {
      setState(() => isScanned = false);
    });
  }

  void _toggleTorch() {
    setState(() => isTorchOn = !isTorchOn);
    controller.toggleTorch();
  }

  // 🎯 Focus indicator UI
  Widget _focusIndicator() {
    if (!_showFocus || _focusPoint == null) return const SizedBox();

    return Positioned(
      left: _focusPoint!.dx - 30,
      top: _focusPoint!.dy - 30,
      child: AnimatedScale(
        scale: 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // 🧱 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          setState(() {
            _focusPoint = details.localPosition;
            _showFocus = true;
          });
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) setState(() => _showFocus = false);
          });
        },
        child: Stack(
          children: [
            // CAMERA
            MobileScanner(
              controller: controller,
              onDetect: (capture) {
                if (capture.barcodes.isEmpty) return;
                _handleResult(capture.barcodes.first.rawValue ?? '');
              },
            ),

            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: ScannerOverlayPainter(),
            ),

            // SCAN FRAME
            Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: CustomPaint(painter: CornerBracketsPainter()),
              ),
            ),

            // LASER
            AnimatedBuilder(
              animation: laserAnimation,
              builder: (_, __) {
                return Positioned(
                  top: MediaQuery.of(context).size.height * 0.5 -
                      140 +
                      (laserAnimation.value * 260),
                  left: MediaQuery.of(context).size.width * 0.5 - 130,
                  child: Container(
                    width: 260,
                    height: 2,
                    color: const Color(0xFF6366F1),
                  ),
                );
              },
            ),

            _focusIndicator(),

            // TOP CONTROLS
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleBtn(
                      Icons.history_rounded,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScanHistoryScreen(),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _circleBtn(Icons.image, _pickImageAndScan),
                        const SizedBox(width: 12),
                        _circleBtn(
                          isTorchOn
                              ? Icons.flash_on
                              : Icons.flash_off,
                          _toggleTorch,
                          active: isTorchOn,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap,
      {bool active = false}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? const Color(0xFF6366F1)
            : Colors.white.withOpacity(0.15),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

// 🔲 OVERLAY
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutout = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 280,
        height: 280,
      ),
      const Radius.circular(20),
    );

    path.addRRect(cutout);
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ⛶ CORNER BRACKETS
class CornerBracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const l = 40.0;

    canvas.drawLine(const Offset(0, 0), const Offset(l, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, l), paint);

    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width - l, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, l), paint);

    canvas.drawLine(
        Offset(0, size.height), Offset(l, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height - l), paint);

    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - l, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - l), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
