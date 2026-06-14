import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/premium_header.dart';
import '../models/carousel_models.dart';
import '../providers/carousel_provider.dart';
import '../providers/user_provider.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'carousel_editor_screen.dart';

class CarouselCategoryScreen extends StatefulWidget {
  const CarouselCategoryScreen({super.key});

  @override
  State<CarouselCategoryScreen> createState() => _CarouselCategoryScreenState();
}

class _CarouselCategoryScreenState extends State<CarouselCategoryScreen> {
  String? _expandedCategory;
  bool _isLoading = false;

  void debugLog(String message) {
    developer.log('[CarouselCategoryScreen] $message');
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  void _toggleSubcategory(String subcategory) {
    context.read<CarouselProvider>().toggleSubcategory(subcategory);
  }

  Future<void> _proceedWithSelection() async {
    final carouselProvider = context.read<CarouselProvider>();

    if (carouselProvider.selectedSubcategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one subcategory',
            style: AppFonts.poppins(color: AppColors.white),
          ),
          backgroundColor: AppColors.surface,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugLog('🔍 Calling Pexels API with selected subcategories...');

      // Combine subcategories into search string
      final searchQuery = '${carouselProvider.selectedSubcategories.join(' ')} professional';
      debugLog('📝 Search query: "$searchQuery"');

      // Get Pexels API key from Firebase Remote Config
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();
      final apiKey = remoteConfig.getString('pexels_api_key');

      if (apiKey.isEmpty) {
        throw Exception('Pexels API key not configured');
      }

      // Call Pexels API
      final url = Uri.parse(
        'https://api.pexels.com/v1/search?query=${Uri.encodeComponent(searchQuery)}&per_page=5&page=1',
      );

      debugLog('📤 Fetching from: $url');

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': apiKey,
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final photos = data['photos'] as List;

        if (photos.length < 5) {
          throw Exception('Not enough images returned (${photos.length}/5)');
        }

        // Extract image URLs
        final imageUrls = photos
            .take(5)
            .map((photo) => photo['src']['large'] as String)
            .toList();

        debugLog('✅ Fetched ${imageUrls.length} images from Pexels');

        // Set background images in provider
        carouselProvider.setBackgroundImages(imageUrls);

        // Navigate to editor
        if (mounted) {
          _push(context, const CarouselEditorScreen());
        }
      } else {
        throw Exception('Pexels API returned ${response.statusCode}');
      }
    } catch (e) {
      debugLog('❌ Error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching images: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final credits = context.watch<UserProvider>().credits ?? 0;
    final carouselProvider = context.watch<CarouselProvider>();

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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SELECT IMAGES',
                    style: AppFonts.poppins(
                      size: 10,
                      weight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose Categories',
                    style: AppFonts.playfair(
                      size: 32,
                      weight: FontWeight.w900,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select one or more subcategories to find professional carousel images',
                    style: AppFonts.poppins(
                      size: 13,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Categories list
                  ...CarouselCategories.all.map((category) {
                    final isExpanded = _expandedCategory == category.name;
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(
                              () => _expandedCategory =
                                  isExpanded ? null : category.name,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isExpanded
                                    ? AppColors.gold
                                    : AppColors.gold.withValues(alpha: 0.2),
                                width: isExpanded ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    category.name,
                                    style: AppFonts.poppins(
                                      size: 14,
                                      weight: FontWeight.w600,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: AppColors.gold,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isExpanded) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Select one or more to refine your images',
                            style: AppFonts.poppins(
                              size: 11,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: category.subcategories
                                .map((sub) {
                              final isSelected = carouselProvider
                                  .selectedSubcategories
                                  .contains(sub);
                              return GestureDetector(
                                onTap: () => _toggleSubcategory(sub),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.gold
                                        : AppColors.inputBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.gold
                                          : AppColors.gold
                                              .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    sub,
                                    style: AppFonts.poppins(
                                      size: 11,
                                      weight: FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.black
                                          : AppColors.gold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          // Bottom buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _isLoading ? null : () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.surface,
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'BACK',
                          style: AppFonts.poppins(
                            size: 12,
                            weight: FontWeight.w700,
                            color: _isLoading
                                ? AppColors.gold.withValues(alpha: 0.5)
                                : AppColors.gold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GoldButton(
                    label: _isLoading ? 'LOADING...' : 'CONTINUE',
                    onTap: _isLoading ? null : _proceedWithSelection,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
