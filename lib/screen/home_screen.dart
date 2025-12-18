import 'package:flutter/material.dart';
import 'package:qru_soft/screen/QrGeneratorScreen.dart';
import 'package:qru_soft/screen/qr_scan_screen.dart';
import 'package:qru_soft/screen/scan_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int index = 1;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final screens = [
    const QrGeneratorScreen(),
    const QrScanScreen(),
    const ScanHistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int i) {
    if (i != index) {
      _animationController.forward().then((_) {
        setState(() => index = i);
        _animationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SafeArea(
              child: IndexedStack(
                index: index,
                children: screens,
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.qr_code_2_rounded,
                  label: "Generate",
                  currentIndex: 0,
                ),
                _buildNavItem(
                  icon: Icons.qr_code_scanner_rounded,
                  label: "Scan",
                  currentIndex: 1,
                  isPrimary: true,
                ),
                _buildNavItem(
                  icon: Icons.history_rounded,
                  label: "History",
                  currentIndex: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int currentIndex,
    bool isPrimary = false,
  }) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () => _onTabTapped(currentIndex),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? (isPrimary
              ? const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : LinearGradient(
            colors: [
              const Color(0xFF3B82F6).withOpacity(0.15),
              const Color(0xFF8B5CF6).withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ))
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected && isPrimary
              ? [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (isPrimary ? Colors.white : const Color(0xFF6366F1))
                  : Colors.grey.shade500,
              size: isSelected ? 26 : 24,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: isSelected ? 8 : 0,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Text(
                label,
                style: TextStyle(
                  color: isPrimary
                      ? Colors.white
                      : const Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}