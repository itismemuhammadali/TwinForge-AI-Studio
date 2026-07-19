import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../providers/admin_provider.dart';
import '../services/stock_image_service.dart';
import 'generate_screen.dart';

class TrendingScreen extends StatefulWidget {
  final bool fromBroll;
  final bool fromTalkingHead;
  final bool fromHoliday;
  final bool fromManifestation;
  final String? category;
  final String? title;
  const TrendingScreen({super.key, this.fromBroll = false, this.fromTalkingHead = false, this.fromHoliday = false, this.fromManifestation = false, this.category, this.title});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  List<AdminContent> _adminContent = [];
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _sub;

  @override
  void initState() {
    super.initState();
    _loadAdminContent();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  void _loadAdminContent() {
    _sub = FirebaseFirestore.instance
        .collection('admin_content')
        .snapshots()
        .listen(
      (snapshot) {
        if (mounted) {
          var items = snapshot.docs
              .map((doc) {
                final data = doc.data();
                return AdminContent.fromMap({'id': doc.id, ...data});
              })
              .toList();
          if (widget.category != null) {
            items = items.where((item) {
              final matchesCategory = item.category == widget.category;
              final matchesTag = item.tags.contains(widget.category);
              if (matchesCategory || matchesTag) return true;
              if (widget.fromTalkingHead && item.tags.contains('Podcast')) return true;
              return false;
            }).toList();
          }
          items.shuffle();
          for (final item in items) {
            precacheImage(NetworkImage(item.imageUrl), context);
          }
          setState(() {
            _adminContent = items;
            _isLoading = false;
          });
        }
      },
      onError: (e) {
        debugPrint('Error loading admin content: $e');
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AimrAppBar(actions: []),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title ?? 'Trending Content',
                      style: AppFonts.playfair(size: 30, weight: FontWeight.w900, color: AppColors.white)),
                  const SizedBox(height: 8),
                  Text(widget.title != null ? 'Explore our curated collection of ${widget.title!.toLowerCase()} templates.' : 'Hand-picked trending visuals from around the world. Perfect for your next viral post.',
                      style: AppFonts.poppins(size: 12, color: AppColors.muted, height: 1.6)),
                  const SizedBox(height: 24),

                  Text('Hot This Week', style: AppFonts.poppins(size: 12, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  if (_isLoading && _adminContent.isEmpty)
                    const Center(child: CircularProgressIndicator(color: AppColors.gold))
                  else if (_adminContent.isNotEmpty)
                    _buildAdminContentGrid()
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Text(
                          'No templates available yet',
                          style: AppFonts.poppins(size: 14, color: AppColors.muted),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminContentGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _adminContent.length,
      itemBuilder: (context, index) {
        final item = _adminContent[index];
        return _adminContentCard(context, item);
      },
    );
  }

  Widget _adminContentCard(BuildContext context, AdminContent item) {
    final categoryColor = _getCategoryColor(item.category);
    return GestureDetector(
      onTap: () {
        _push(
          context,
          GenerateScreen(
            templateImage: StockImage(
              id: item.id,
              imageUrl: item.imageUrl,
              title: '${item.category} Template',
              photographer: 'Twinora',
              source: 'Admin',
            ),
            prefilledPrompt: item.prompt,
            fromBroll: widget.fromBroll,
            fromTalkingHead: widget.fromTalkingHead,
            fromHoliday: widget.fromHoliday,
            fromManifestation: widget.fromManifestation,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: categoryColor.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded || frame != null) return child;
                    return Container(color: AppColors.surface, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.surface,
                    child: const Icon(Icons.broken_image, color: AppColors.muted),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: categoryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.category.toUpperCase(),
                          style: AppFonts.poppins(size: 8, color: AppColors.white, weight: FontWeight.w700),
                        ),
                      ),
                      if (item.prompt != null && item.prompt!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.prompt!,
                          style: AppFonts.poppins(
                            size: 9,
                            color: AppColors.white.withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (item.overlayPrompt != null && item.overlayPrompt!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.overlayPrompt!,
                          style: AppFonts.poppins(
                            size: 8,
                            color: AppColors.gold.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold,
                    boxShadow: [
                      BoxShadow(color: AppColors.gold.withValues(alpha: 0.6), blurRadius: 10),
                    ],
                  ),
                  child: const Icon(Icons.arrow_forward, color: AppColors.black, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Podcast': return const Color(0xFFE74C3C);
      case 'Trending': return const Color(0xFFF39C12);
      case 'B-Roll': return const Color(0xFFE8A0B4);
      case 'Carousel': return const Color(0xFF9B59B6);
      case 'Magazine': return const Color(0xFFE74C3C);
      case 'Luxury Lifestyle': return const Color(0xFFD4AF37);
      case 'Luxury Office': return const Color(0xFF8B6914);
      case 'Luxury Car': return const Color(0xFFC0392B);
      case 'Seaside Work': return const Color(0xFF1ABC9C);
      default: return AppColors.gold;
    }
  }

}
