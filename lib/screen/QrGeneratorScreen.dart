import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';

// ----------------------------------------------------
// 🔥 QR THEME MODEL
// ----------------------------------------------------
class QrThemeModel {
  final String name;
  final List<Color> gradient;
  final Color qrColor;
  final bool rounded;

  QrThemeModel({
    required this.name,
    required this.gradient,
    required this.qrColor,
    required this.rounded,
  });
}

// ----------------------------------------------------
// 🔥 20+ READY THEMES
// ----------------------------------------------------
final List<QrThemeModel> qrThemes = [
  QrThemeModel(name: "Blue Neon", gradient: [Color(0xFF4FACFE), Color(0xFF00F2FE)], qrColor: Colors.black, rounded: true),
  QrThemeModel(name: "Sunset", gradient: [Color(0xFFFF512F), Color(0xFFF09819)], qrColor: Colors.black, rounded: true),
  QrThemeModel(name: "Aqua", gradient: [Color(0xFF00C9FF), Color(0xFF92FE9D)], qrColor: Colors.black, rounded: true),
  QrThemeModel(name: "Dark Matrix", gradient: [Color(0xFF0F2027), Color(0xFF203A43)], qrColor: Colors.greenAccent, rounded: false),
  QrThemeModel(name: "Royal Gold", gradient: [Color(0xFFFFD700), Color(0xFFFFA500)], qrColor: Colors.black, rounded: true),
  QrThemeModel(name: "Pink Candy", gradient: [Color(0xFFFF9A9E), Color(0xFFFAD0C4)], qrColor: Colors.black, rounded: true),
  QrThemeModel(name: "Green Nature", gradient: [Color(0xFF56ab2f), Color(0xFFA8E063)], qrColor: Colors.black, rounded: true),
  QrThemeModel(name: "Lavender", gradient: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)], qrColor: Colors.black, rounded: true),
  QrThemeModel(name: "Ice", gradient: [Color(0xFF74ebd5), Color(0xFFACB6E5)], qrColor: Colors.black, rounded: true),
  QrThemeModel(name: "Tropical", gradient: [Color(0xFFf6d365), Color(0xFFfda085)], qrColor: Colors.black, rounded: true),
  QrThemeModel(name: "Mint", gradient: [Color(0xFFBFF098), Color(0xFF6FD6FF)], qrColor: Colors.black, rounded: true),
  QrThemeModel(name: "RoseGold", gradient: [Color(0xFFF4C4F3), Color(0xFFFC67FA)], qrColor: Colors.black, rounded: true),
];

// ----------------------------------------------------
// 🔥 MAIN SCREEN
// ----------------------------------------------------
class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> with SingleTickerProviderStateMixin {
  TextEditingController controller = TextEditingController();
  String data = "";

  GlobalKey qrKey = GlobalKey();

  File? galleryLogo;
  String? networkLogo = "assets/logo.png";

  final picker = ImagePicker();

  QrThemeModel selectedTheme = qrThemes[0];

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }

  // --------------------- LOGO PICK ---------------------
  Future<void> pickLogo() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      galleryLogo = File(image.path);
      networkLogo = null;
      setState(() {});
      _showSuccessSnackbar('Logo uploaded successfully!');
    }
  }

  // --------------------- GET LOGO ---------------------
  Future<ImageProvider?> getLogo() async {
    if (galleryLogo != null) return FileImage(galleryLogo!);
    if (networkLogo != null) return AssetImage(networkLogo!);
    return null;
  }

  // --------------------- SAVE QR ---------------------
  Future<void> saveQr() async {
    final perm = await PhotoManager.requestPermissionExtend();
    log('Photo permission: ${perm.isAuth}');
    // if (!perm.isAuth) {
    //   _showErrorSnackbar('Permission denied');
    //   return;
    // }

    RenderRepaintBoundary boundary =
    qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image img = await boundary.toImage(pixelRatio: 3);
    ByteData? byte = await img.toByteData(format: ui.ImageByteFormat.png);
    Uint8List bytes = byte!.buffer.asUint8List();

    await PhotoManager.editor.saveImage(bytes,
        filename: 'qr_${DateTime.now().millisecondsSinceEpoch}.png');

    _showSuccessSnackbar('QR Code saved successfully!');
  }

  // --------------------- SHARE QR ---------------------
  Future<void> shareQr() async {
    RenderRepaintBoundary boundary =
    qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    ui.Image img = await boundary.toImage(pixelRatio: 3);
    ByteData? byte = await img.toByteData(format: ui.ImageByteFormat.png);
    Uint8List bytes = byte!.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/qr.png");
    await file.writeAsBytes(bytes);

    Share.shareXFiles([XFile(file.path)]);
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  // ----------------------------------------------------
  // 🔥 HORIZONTAL THEME CAROUSEL
  // ----------------------------------------------------
  Widget themeCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Choose Theme',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: qrThemes.length,
            itemBuilder: (context, index) {
              final theme = qrThemes[index];
              final isSelected = selectedTheme == theme;

              return GestureDetector(
                onTap: () {
                  setState(() => selectedTheme = theme);
                  if (data.isNotEmpty) {
                    _animationController.reset();
                    _animationController.forward();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: EdgeInsets.all(isSelected ? 3 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: isSelected
                        ? const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    )
                        : null,
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                        : null,
                  ),
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: theme.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.qr_code_2_rounded,
                            size: 45, color: theme.qrColor.withOpacity(0.9)),
                        Positioned(
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              theme.name,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 16,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // 🔥 UI
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Generate QR',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.1),
                      const Color(0xFF8B5CF6).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Input Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller,
                    // maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Enter URL or Text",
                      hintText: "https://example.com or any text",
                      prefixIcon: const Icon(Icons.link, color: Color(0xFF6366F1)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isEmpty) {
                        _showErrorSnackbar('Please enter text or URL');
                        return;
                      }
                      setState(() => data = controller.text.trim());
                      _animationController.forward();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2_rounded, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Generate QR Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (data.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  themeCarousel(),
                  const SizedBox(height: 24),

                  // Logo Upload Button
                  OutlinedButton.icon(
                    onPressed: pickLogo,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: const Text('Add Custom Logo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                      side: const BorderSide(color: Color(0xFF6366F1), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // QR PREVIEW
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: RepaintBoundary(
                      key: qrKey,
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: selectedTheme.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: selectedTheme.gradient.first.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: FutureBuilder<ImageProvider?>(
                            future: getLogo(),
                            builder: (context, logo) {
                              return PrettyQr(
                                data: data,
                                size: 220,
                                elementColor: selectedTheme.qrColor,
                                roundEdges: selectedTheme.rounded,
                                image: logo.data,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: saveQr,
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Download'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: shareQr,
                          icon: const Icon(Icons.share_rounded),
                          label: const Text('Share'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}