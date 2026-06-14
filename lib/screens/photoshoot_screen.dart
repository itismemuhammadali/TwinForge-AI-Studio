import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_header.dart';
import '../services/stock_image_service.dart';
import '../providers/user_provider.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'generate_screen.dart';

class PhotoshootScreen extends StatefulWidget {
  const PhotoshootScreen({super.key});

  @override
  State<PhotoshootScreen> createState() => _PhotoshootScreenState();
}

class _PhotoshootScreenState extends State<PhotoshootScreen> {
  List<StockImage> _images = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  late TextEditingController _searchController;

  // Different template categories to show
  final List<String> _templateCategories = [
    'fashion',
    'lifestyle',
    'portrait',
    'professional',
    'casual',
    'elegant',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadTemplateImages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplateImages() async {
    setState(() => _isLoading = true);
    try {
      // Load images from multiple categories to show variety
      List<StockImage> allImages = [];
      
      for (String category in _templateCategories) {
        try {
          final images = await StockImageService.searchBoth(
            query: category,
            perPage: 3, // Get 3 images per category
            page: _currentPage,
          );
          allImages.addAll(images);
        } catch (e) {
          // Continue with other categories if one fails
          continue;
        }
      }

      setState(() {
        _images = allImages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading templates: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreTemplates() async {
    setState(() => _isLoadingMore = true);
    try {
      _currentPage++;
      List<StockImage> newImages = [];
      
      for (String category in _templateCategories) {
        try {
          final images = await StockImageService.searchBoth(
            query: category,
            perPage: 3,
            page: _currentPage,
          );
          newImages.addAll(images);
        } catch (e) {
          continue;
        }
      }

      setState(() {
        _images.addAll(newImages);
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more templates: $e')),
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
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PHOTOSHOOT',
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
                        'Select a template image to extract style features',
                        style: AppFonts.poppins(
                          size: 13,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Images Grid
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: AppColors.gold),
                              const SizedBox(height: 16),
                              Text(
                                'Loading template images...',
                                style: AppFonts.poppins(color: AppColors.muted),
                              ),
                            ],
                          ),
                        )
                      : _images.isEmpty
                          ? Center(
                              child: Text(
                                'No template images found.',
                                style: AppFonts.poppins(color: AppColors.muted),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: [
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.65,
                                    ),
                                    itemCount: _images.length,
                                    itemBuilder: (context, index) {
                                      final image = _images[index];
                                      return _buildTemplateCard(context, image);
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  // Load More Button
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: GestureDetector(
                                      onTap: _isLoadingMore ? null : _loadMoreTemplates,
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
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, StockImage image) {
    return GestureDetector(
      onTap: () {
        // Open GenerateScreen with the selected template image
        _push(
          context,
          GenerateScreen(
            templateImage: image,
            presetStyle: image.source,
          ),
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
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                image.imageUrl,
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
                          Icons.image_not_supported,
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
                      image.photographer,
                      style: AppFonts.poppins(
                        size: 11,
                        color: AppColors.gold,
                        weight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
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
                        image.source.toUpperCase(),
                        style: AppFonts.poppins(
                          size: 8,
                          color: AppColors.gold,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Click indicator
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.6),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: AppColors.black,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
