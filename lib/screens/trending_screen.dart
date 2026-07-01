import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/premium_header.dart';
import '../providers/admin_provider.dart';
import '../services/stock_image_service.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'generate_screen.dart';

class TrendingScreen extends StatefulWidget {
  final bool showTypeSelector;
  final bool fromBroll;
  const TrendingScreen({super.key, this.showTypeSelector = true, this.fromBroll = false});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  String _selectedCategory = 'Image'; // Default to Image
  String _selectedVibe = 'All';

  final List<String> _categories = ['Image', 'Video'];
  final List<String> _vibes = ['All', 'Business', 'Success', 'Minimal', 'Lifestyle'];

  List<StockImage> _trendingImages = [];
  List<StockVideo> _trendingVideos = [];
  List<AdminContent> _adminContent = [];
  bool _isLoading = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _fetchTrending();
    _loadAdminContent();
  }

  Future<void> _fetchTrending() async {
    setState(() => _isLoading = true);
    try {
      if (_selectedCategory == 'Image') {
        // Search for business/professional images only
        final images = await StockImageService.searchBoth(
          query: 'business professional office meeting corporate',
          perPage: 12,
          page: _page,
        );
        setState(() {
          if (_page == 1) {
            _trendingImages = images;
          } else {
            _trendingImages.addAll(images);
          }
        });
        if (mounted) {
          for (final img in images) {
            precacheImage(NetworkImage(img.imageUrl), context);
          }
        }
      } else {
        // Search for business/professional videos
        final videos = await StockImageService.searchBothVideos(
          query: 'business professional office meeting corporate',
          perPage: 12,
          page: _page,
        );
        setState(() {
          if (_page == 1) {
            _trendingVideos = videos;
          } else {
            _trendingVideos.addAll(videos);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching trending: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  void _loadAdminContent() {
    FirebaseFirestore.instance
        .collection('admin_content')
        .snapshots()
        .listen(
      (snapshot) {
        if (mounted) {
          final items = snapshot.docs
              .map((doc) => AdminContent.fromMap({'id': doc.id, ...doc.data()}))
              .toList();
          items.shuffle();
          for (final item in items) {
            precacheImage(NetworkImage(item.imageUrl), context);
          }
          setState(() {
            _adminContent = items;
          });
        }
      },
      onError: (e) {
        debugPrint('Error loading admin content: $e');
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
                  Text('Trending Content',
                      style: AppFonts.playfair(size: 30, weight: FontWeight.w900, color: AppColors.white)),
                  const SizedBox(height: 8),
                  Text('Hand-picked trending visuals from around the world. Perfect for your next viral post.',
                      style: AppFonts.poppins(size: 12, color: AppColors.muted, height: 1.6)),
                  const SizedBox(height: 24),

                  Text('TYPE', style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _categories.map((cat) =>
                      _categoryChip(cat, selected: cat == _selectedCategory, onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                          _page = 1;
                        });
                        if (cat == 'Image') _fetchTrending();
                      })
                    ).toList(),
                  ),
                  const SizedBox(height: 28),

                  if (_selectedCategory == 'Image') ...[
                    Text('Hot This Week', style: AppFonts.poppins(size: 12, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2)),
                    const SizedBox(height: 16),
                    if (_isLoading && _adminContent.isEmpty && _trendingImages.isEmpty)
                      const Center(child: CircularProgressIndicator(color: AppColors.gold))
                    else ...[
                      if (_adminContent.isNotEmpty) ...[
                        _buildAdminContentGrid(),
                        const SizedBox(height: 24),
                        Container(height: 0.5, color: AppColors.white.withValues(alpha: 0.08)),
                        const SizedBox(height: 24),
                      ],
                      _buildTrendingGrid(context),
                    ],
                    const SizedBox(height: 28),
                    GoldButton(
                      label: _isLoading ? 'LOADING...' : 'LOAD MORE',
                      onTap: _isLoading ? null : () {
                        setState(() => _page++);
                        _fetchTrending();
                      },
                    ),
                  ],

                  if (_selectedCategory == 'Video')
                    _buildTrendingGrid(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, {bool selected = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withValues(alpha: 0.18) : AppColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.gold : AppColors.white.withValues(alpha: 0.08), width: 0.5),
        ),
        child: Text(label.toUpperCase(),
            style: AppFonts.poppins(
                size: 11,
                weight: FontWeight.w700,
                color: selected ? AppColors.gold : AppColors.text,
                letterSpacing: 1.5)),
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
      case 'Luxury Lifestyle': return const Color(0xFFD4AF37);
      case 'Luxury Office': return const Color(0xFF8B6914);
      case 'Luxury Car': return const Color(0xFFC0392B);
      case 'Seaside Work': return const Color(0xFF1ABC9C);
      default: return AppColors.gold;
    }
  }

  Widget _buildTrendingGrid(BuildContext context) {
    if (_selectedCategory == 'Image') {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _trendingImages.length,
        itemBuilder: (context, index) {
          final image = _trendingImages[index];
          return _contentCard(
            context,
            imageUrl: image.imageUrl,
            title: image.title,
            photographer: image.photographer,
            source: image.source,
          );
        },
      );
    } else {
      // Video Coming Soon
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Text(
            'Videos Coming Soon',
            style: AppFonts.poppins(
              size: 14,
              color: AppColors.muted,
            ),
          ),
        ),
      );
    }
  }

  Widget _contentCard(BuildContext context, {
    required String imageUrl,
    required String title,
    required String photographer,
    required String source,
    bool isVideo = false,
  }) {
    return GestureDetector(
      onTap: () {
        _push(
          context,
          GenerateScreen(
            templateImage: StockImage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              imageUrl: imageUrl,
              title: title,
              photographer: photographer,
              source: source,
            ),
            fromBroll: widget.fromBroll,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.06), width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  imageUrl,
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
              if (isVideo)
                const Center(
                  child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 48),
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
                      Text(title, 
                        style: AppFonts.poppins(size: 10, weight: FontWeight.w600, color: AppColors.white),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('by $photographer', 
                              style: AppFonts.poppins(size: 8, color: AppColors.muted),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(source.toUpperCase(), style: AppFonts.poppins(size: 8, weight: FontWeight.w800, color: AppColors.gold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
