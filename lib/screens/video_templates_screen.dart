import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_header.dart';
import '../services/stock_image_service.dart';
import '../providers/user_provider.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'video_screen.dart';

class VideoTemplatesScreen extends StatefulWidget {
  const VideoTemplatesScreen({super.key});

  @override
  State<VideoTemplatesScreen> createState() => _VideoTemplatesScreenState();
}

class _VideoTemplatesScreenState extends State<VideoTemplatesScreen> {
  List<StockVideo> _videos = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;

  // Different video categories to show
  final List<String> _videoCategories = [
    'cinematic',
    'lifestyle',
    'product',
    'travel',
    'business',
    'nature',
  ];

  @override
  void initState() {
    super.initState();
    _loadTemplateVideos();
  }

  Future<void> _loadTemplateVideos() async {
    setState(() => _isLoading = true);
    try {
      // Load videos from multiple categories to show variety
      List<StockVideo> allVideos = [];
      
      for (String category in _videoCategories) {
        try {
          final videos = await StockImageService.searchBothVideos(
            query: category,
            perPage: 2, // Get 2 videos per category
            page: _currentPage,
          );
          allVideos.addAll(videos);
        } catch (e) {
          // Continue with other categories if one fails
          continue;
        }
      }

      setState(() {
        _videos = allVideos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading videos: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreVideos() async {
    setState(() => _isLoadingMore = true);
    try {
      _currentPage++;
      List<StockVideo> newVideos = [];
      
      for (String category in _videoCategories) {
        try {
          final videos = await StockImageService.searchBothVideos(
            query: category,
            perPage: 2,
            page: _currentPage,
          );
          newVideos.addAll(videos);
        } catch (e) {
          continue;
        }
      }

      setState(() {
        _videos.addAll(newVideos);
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more videos: $e')),
        );
      }
    }
  }

  void _push(BuildContext context, Widget w) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));

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
              child: Column(
                children: [
                  // Section Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VIDEO',
                        style: AppFonts.poppins(
                          size: 10,
                          weight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose Template Style',
                        style: AppFonts.playfair(
                          size: 32,
                          weight: FontWeight.w900,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select a video template to create studio-quality videos',
                        style: AppFonts.poppins(
                          size: 13,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildGrid(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.gold),
            const SizedBox(height: 16),
            Text(
              'Loading video templates...',
              style: AppFonts.poppins(color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Text(
          'No video templates found.',
          style: AppFonts.poppins(color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.65,
          ),
          itemCount: _videos.length,
          itemBuilder: (context, index) {
            final video = _videos[index];
            return _buildVideoCard(context, video);
          },
        ),
        const SizedBox(height: 24),
        // Load More Button
        GestureDetector(
          onTap: _isLoadingMore ? null : _loadMoreVideos,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.4),
                width: 1.5,
              ),
              color: _isLoadingMore
                  ? AppColors.gold.withValues(alpha: 0.1)
                  : AppColors.surface,
            ),
            child: Center(
              child: _isLoadingMore
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: AppColors.gold,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          color: AppColors.gold,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LOAD MORE',
                          style: AppFonts.poppins(
                            size: 11,
                            weight: FontWeight.w700,
                            color: AppColors.gold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildVideoCard(BuildContext context, StockVideo video) {
    return GestureDetector(
      onTap: () {
        // Open VideoScreen with the selected template video
        _push(
          context,
          VideoScreen(templateVideo: video),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                video.thumbnailUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.surface,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gold,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.surface,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          color: AppColors.muted,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load',
                          style: AppFonts.poppins(
                            size: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Overlay gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Play button overlay
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.6),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: AppColors.black,
                  size: 28,
                ),
              ),
            ),

            // Info at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      video.photographer,
                      style: AppFonts.poppins(
                        size: 11,
                        color: AppColors.gold,
                        weight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 10,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${video.duration}s',
                          style: AppFonts.poppins(
                            size: 9,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.source.toUpperCase(),
                            style: AppFonts.poppins(
                              size: 8,
                              color: AppColors.gold,
                              weight: FontWeight.w600,
                            ),
                          ),
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
}
