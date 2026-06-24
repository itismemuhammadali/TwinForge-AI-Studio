import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:image/image.dart' as img;
import '../services/filter_service.dart';
import '../theme/app_theme.dart';

class FilterPreviewGrid extends StatefulWidget {
  final String imageUrl;
  final List<String> filters;
  final String? title;

  const FilterPreviewGrid({
    super.key,
    required this.imageUrl,
    required this.filters,
    this.title,
  });

  @override
  State<FilterPreviewGrid> createState() => _FilterPreviewGridState();
}

class _FilterPreviewGridState extends State<FilterPreviewGrid> {
  Map<String, Uint8List?> _filterCache = {};
  bool _isLoadingFilters = true;

  @override
  void initState() {
    super.initState();
    _loadFilteredImages();
  }

  Future<void> _loadFilteredImages() async {
    try {
      // Load original image
      final imageData = await _fetchImageBytes(widget.imageUrl);
      if (imageData == null) return;

      // Apply filters
      for (String filter in widget.filters) {
        if (mounted) {
          final filtered = FilterService.applyFilter(imageData, filter);
          setState(() {
            _filterCache[filter] = filtered;
          });
        }
      }

      if (mounted) {
        setState(() => _isLoadingFilters = false);
      }
    } catch (e) {
      debugPrint('Error loading filtered images: $e');
      if (mounted) {
        setState(() => _isLoadingFilters = false);
      }
    }
  }

  Future<Uint8List?> _fetchImageBytes(String url) async {
    try {
      final response = await HttpClient().getUrl(Uri.parse(url));
      final httpResponse = await response.close();
      return await httpResponse.fold<Uint8List>(
        Uint8List(0),
        (current, chunk) => Uint8List.fromList(current + chunk),
      );
    } catch (e) {
      debugPrint('Error fetching image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              widget.title!,
              style: AppFonts.poppins(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.gold,
              ),
            ),
          ),
        if (_isLoadingFilters)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.filters.length,
              itemBuilder: (context, index) {
                final filterName = widget.filters[index];
                final filteredImage = _filterCache[filterName];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          image: filteredImage != null
                              ? DecorationImage(
                                  image: MemoryImage(filteredImage),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: filteredImage == null
                            ? Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(
                                    AppColors.gold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 120,
                        child: Text(
                          filterName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.poppins(
                            size: 10,
                            weight: FontWeight.w500,
                            color: AppColors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
