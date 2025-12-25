import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/scan_history_model.dart';
import '../service/scan_history_service.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen>
    with SingleTickerProviderStateMixin {
  List<ScanHistoryModel> history = [];
  bool isLoading = true;
  late AnimationController _animationController;
  String selectedFilter = 'All';

  final List<String> filters = ['All', 'URL', 'WhatsApp', 'WiFi', 'Phone', 'Email'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    load();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    history = await ScanHistoryService().getHistory();
    setState(() => isLoading = false);
    _animationController.forward(from: 0);
  }

  List<ScanHistoryModel> get filteredHistory {
    if (selectedFilter == 'All') return history;
    return history.where((item) {
      return _getTypeLabel(item.type) == selectedFilter;
    }).toList();
  }

  Future<void> _handleTap(String value) async {
    String v = value.trim();
    Uri? uri;

    if (v.startsWith('whatsapp://') || v.contains('wa.me')) {
      uri = Uri.parse(v);
    } else if (v.startsWith('tel:')) {
      uri = Uri.parse(v);
    } else if (v.startsWith('mailto:')) {
      uri = Uri.parse(v);
    } else if (!v.startsWith('http://') &&
        !v.startsWith('https://') &&
        v.contains('.')) {
      uri = Uri.parse('https://$v');
    } else {
      uri = Uri.tryParse(v);
    }

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    _showSnackBar('Not a valid link', isError: true);
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Copied to clipboard', isError: false);
  }

  void _deleteItem(int index) {
    setState(() => history.removeAt(index));
    ScanHistoryService().deleteAt(index);
    _showSnackBar('Item deleted', isError: true);
  }

  void _toggleFavorite(int index) {
    setState(() {
      history[index] = ScanHistoryModel(
        value: history[index].value,
        type: history[index].type,
        time: history[index].time,
        isFavorite: !history[index].isFavorite,
      );
    });
    ScanHistoryService().updateAt(index, history[index]);
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Clear History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete all scan history? This action cannot be undone.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => history.clear());
              ScanHistoryService().clearAll();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredHistory;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Stats
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6366F1),
                      const Color(0xFF8B5CF6),
                      const Color(0xFFA855F7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scan History',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Your scanned QR codes',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (!isLoading && history.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${history.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        if (!isLoading && history.isNotEmpty)
                          Row(
                            children: [
                              _buildStatCard('Today', '${_getTodayCount()}', Icons.today_rounded),
                              const SizedBox(width: 12),
                              _buildStatCard('Week', '${_getWeekCount()}', Icons.date_range_rounded),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              if (history.isNotEmpty && !isLoading)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                  onPressed: _clearAll,
                  tooltip: 'Clear All',
                ),
              const SizedBox(width: 8),
            ],
          ),

          // Filter Chips


          // Content
          if (isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Loading history...',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6366F1).withOpacity(0.1),
                            const Color(0xFF8B5CF6).withOpacity(0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        selectedFilter == 'All'
                            ? Icons.qr_code_scanner_rounded
                            : Icons.filter_list_off_rounded,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      selectedFilter == 'All' ? 'No Scan History' : 'No $selectedFilter Found',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedFilter == 'All'
                          ? 'Your scanned QR codes will appear here'
                          : 'Try a different filter',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final actualIndex = history.indexOf(filtered[index]);
                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        final delay = index * 0.05;
                        final animValue = Curves.easeOutCubic.transform(
                          (_animationController.value - delay).clamp(0.0, 1.0) /
                              (1.0 - delay),
                        );

                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - animValue)),
                          child: Opacity(opacity: animValue, child: child),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Dismissible(
                          key: Key(filtered[index].value + actualIndex.toString()),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _deleteItem(actualIndex),
                          background: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            child: const Icon(
                              Icons.delete_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          child: _buildModernCard(filtered[index], actualIndex),
                        ),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCard(ScanHistoryModel item, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(item.value),
          onLongPress: () => _copy(item.value),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Icon with gradient
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getColorForType(item.type).withOpacity(0.2),
                        _getColorForType(item.type).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _iconForType(item.type),
                    color: _getColorForType(item.type),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getColorForType(item.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getTypeLabel(item.type),
                              style: TextStyle(
                                fontSize: 11,
                                color: _getColorForType(item.type),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(item.time),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Favorite button
                IconButton(
                  icon: Icon(
                    item.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: item.isFavorite ? Colors.amber : Colors.grey.shade400,
                  ),
                  onPressed: () => _toggleFavorite(index),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForType(ScanType type) {
    switch (type) {
      case ScanType.url:
        return const Color(0xFF3B82F6);
      case ScanType.whatsapp:
        return const Color(0xFF10B981);
      case ScanType.wifi:
        return const Color(0xFF8B5CF6);
      case ScanType.phone:
        return const Color(0xFFF59E0B);
      case ScanType.email:
        return const Color(0xFFEF4444);
      case ScanType.text:
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _iconForType(ScanType type) {
    switch (type) {
      case ScanType.url:
        return Icons.link_rounded;
      case ScanType.whatsapp:
        return Icons.chat_bubble_rounded;
      case ScanType.wifi:
        return Icons.wifi_rounded;
      case ScanType.phone:
        return Icons.phone_rounded;
      case ScanType.email:
        return Icons.email_rounded;
      case ScanType.text:
      default:
        return Icons.text_fields_rounded;
    }
  }

  String _getTypeLabel(ScanType type) {
    switch (type) {
      case ScanType.url:
        return 'URL';
      case ScanType.whatsapp:
        return 'WhatsApp';
      case ScanType.wifi:
        return 'WiFi';
      case ScanType.phone:
        return 'Phone';
      case ScanType.email:
        return 'Email';
      case ScanType.text:
      default:
        return 'Text';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return "${time.day}/${time.month}/${time.year}";
  }

  int _getTodayCount() {
    final now = DateTime.now();
    return history.where((item) {
      return item.time.year == now.year &&
          item.time.month == now.month &&
          item.time.day == now.day;
    }).length;
  }

  int _getWeekCount() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return history.where((item) => item.time.isAfter(weekAgo)).length;
  }
}