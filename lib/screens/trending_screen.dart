import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/premium_header.dart';
import '../providers/user_provider.dart';
import '../services/stock_image_service.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'generate_screen.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

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
  bool _isLoading = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _fetchTrending();
  }

  Future<void> _fetchTrending() async {
    setState(() => _isLoading = true);
    try {
      if (_selectedCategory == 'Image') {
        final images = await StockImageService.getTrendingBoth(page: _page);
        setState(() {
          if (_page == 1) {
            _trendingImages = images;
          } else {
            _trendingImages.addAll(images);
          }
        });
      } else {
        final videos = await StockImageService.getTrendingBothVideos(page: _page);
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

  @override
  Widget build(BuildContext context) {
    final credits = context.watch<UserProvider>().credits ?? 0;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      body: Column(
        children: [
          PremiumHeader(
            onProfileTap: () => _push(context, const ProfileScreen()),
            onSettingsTap: () => _push(context, const NotificationsScreen()),
            creditsText: '$credits CREDITS',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Trending Content',
                    style: AppFonts.playfair(size: 30, weight: FontWeight.w900, color: AppColors.white)),
                const SizedBox(height: 8),
                Text('Hand-picked trending visuals from around the world. Perfect for your next viral post.',
                    style: AppFonts.poppins(size: 12, color: AppColors.muted, height: 1.6)),
                const SizedBox(height: 24),

                // Category filter
                Text('TYPE', style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2)),
                const SizedBox(height: 10),
                Wrap(spacing: 10, runSpacing: 10, children: _categories.map((cat) =>
                  _categoryChip(cat, selected: cat == _selectedCategory, onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                      _page = 1;
                    });
                    _fetchTrending();
                  })).toList()),
                const SizedBox(height: 28),

                Text('Hot This Week', style: AppFonts.poppins(size: 12, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2)),
                const SizedBox(height: 16),
                
                if (_isLoading && (_trendingImages.isEmpty && _trendingVideos.isEmpty))
                  const Center(child: CircularProgressIndicator(color: AppColors.gold))
                else
                  _buildTrendingGrid(context),
                  
                const SizedBox(height: 28),

                GoldButton(
                  label: _isLoading ? 'LOADING...' : 'LOAD MORE',
                  onTap: _isLoading ? null : () {
                    setState(() => _page++);
                    _fetchTrending();
                  },
                ),
              ]),
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
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _trendingVideos.length,
        itemBuilder: (context, index) {
          final video = _trendingVideos[index];
          return _contentCard(
            context,
            imageUrl: video.thumbnailUrl,
            title: video.title,
            photographer: video.photographer,
            source: video.source,
            isVideo: true,
          );
        },
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
    return Container(
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
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(color: AppColors.surface, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                },
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
    );
  }
}
