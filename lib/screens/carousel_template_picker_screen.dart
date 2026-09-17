import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/stock_image_service.dart';
import 'generate_screen.dart';

class CarouselTemplate {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final String description;

  const CarouselTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.description,
  });
}

class CarouselTemplatePickerScreen extends StatefulWidget {
  final File avatarImageFile;

  const CarouselTemplatePickerScreen({
    super.key,
    required this.avatarImageFile,
  });

  @override
  State<CarouselTemplatePickerScreen> createState() =>
      _CarouselTemplatePickerScreenState();
}

class _CarouselTemplatePickerScreenState
    extends State<CarouselTemplatePickerScreen> {
  String _selectedCategory = 'All';
  CarouselTemplate? _selectedTemplate;
  StreamSubscription<QuerySnapshot>? _adminSubscription;
  List<CarouselTemplate> _adminTemplates = [];
  bool _isLoadingAdminContent = true;

  final List<String> _categories = [
    'All',
    'Infographic',
    'Minimalist Quote',
    'Educational Swipe',
    'Luxury Showcase',
    'Tech Product',
    'Viral Story',
  ];

  @override
  void initState() {
    super.initState();
    _listenToAdminContent();
  }

  @override
  void dispose() {
    _adminSubscription?.cancel();
    super.dispose();
  }

  void _listenToAdminContent() {
    _adminSubscription = FirebaseFirestore.instance
        .collection('admin_content')
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;
        final docs = snapshot.docs;
        final List<CarouselTemplate> fetched = [];

        int index = 1;
        for (final doc in docs) {
          final data = doc.data();
          final category = (data['category'] ?? '').toString();
          final tags = (data['tags'] is List)
              ? (data['tags'] as List).map((e) => e.toString()).toList()
              : <String>[];

          final isCarousel = category == 'Carousel' || tags.contains('Carousel');

          if (isCarousel) {
            final imageUrl = (data['imageUrl'] ?? '').toString();
            if (imageUrl.isEmpty) continue;

            final prompt = (data['prompt'] ?? '').toString().trim();
            final title = prompt.isNotEmpty
                ? (prompt.length > 35 ? '${prompt.substring(0, 35)}...' : prompt)
                : 'Admin Template #$index';
            final desc = prompt.isNotEmpty
                ? prompt
                : 'Custom client template uploaded via admin portal';
            final cat = tags.isNotEmpty ? tags.first : (category.isNotEmpty ? category : 'Infographic');

            fetched.add(
              CarouselTemplate(
                id: doc.id,
                title: title,
                category: cat,
                imageUrl: imageUrl,
                description: desc,
              ),
            );
            index++;
          }
        }

        setState(() {
          _adminTemplates = fetched;
          _isLoadingAdminContent = false;
        });
      },
      onError: (error) {
        debugPrint('⚠️ Error fetching admin carousel templates: $error');
        if (mounted) {
          setState(() => _isLoadingAdminContent = false);
        }
      },
    );
  }

  List<CarouselTemplate> get _allTemplates {
    return _adminTemplates;
  }

  List<String> get _availableCategories {
    final set = <String>{'All'};
    for (final cat in _categories) {
      if (cat != 'All') set.add(cat);
    }
    for (final t in _allTemplates) {
      if (t.category.isNotEmpty) set.add(t.category);
    }
    return set.toList();
  }

  List<CarouselTemplate> get _filteredTemplates {
    final list = _allTemplates;
    if (_selectedCategory == 'All') return list;
    return list
        .where((t) => t.category.toLowerCase() == _selectedCategory.toLowerCase())
        .toList();
  }

  void _proceedToPromptScreen(CarouselTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenerateScreen(
          templateImage: StockImage(
            id: template.id,
            imageUrl: template.imageUrl,
            title: template.title,
            photographer: 'Twinora',
            source: 'Admin',
          ),
          prefilledPrompt: (template.description.isNotEmpty && !template.description.contains('Custom client template'))
              ? template.description
              : null,
          avatarImageFile: widget.avatarImageFile,
          fromCarousel: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CHOOSE CAROUSEL TEMPLATE',
          style: AppFonts.poppins(
            size: 14,
            weight: FontWeight.w700,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Filter Pills
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _availableCategories.length,
                itemBuilder: (context, index) {
                  final cat = _availableCategories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(
                        cat,
                        style: AppFonts.poppins(
                          size: 11,
                          weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.black : AppColors.white,
                        ),
                      ),
                      selectedColor: AppColors.gold,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.gold
                            : AppColors.white.withValues(alpha: 0.1),
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Templates Grid
            Expanded(
              child: _isLoadingAdminContent
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    )
                  : _filteredTemplates.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.grid_view_rounded,
                                  color: AppColors.gold.withValues(alpha: 0.4),
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Carousel Templates Uploaded Yet',
                                  style: AppFonts.playfair(
                                    size: 18,
                                    weight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please upload carousel templates via the Admin Portal to make them available here.',
                                  style: AppFonts.poppins(
                                    size: 12,
                                    color: AppColors.muted,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _filteredTemplates.length,
                itemBuilder: (context, index) {
                  final template = _filteredTemplates[index];
                  final isSelected = _selectedTemplate?.id == template.id;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedTemplate = template);
                      _proceedToPromptScreen(template);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.gold
                              : AppColors.white.withValues(alpha: 0.15),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              template.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.surface,
                                child: const Icon(Icons.grid_view_rounded,
                                    color: AppColors.gold, size: 36),
                              ),
                            ),

                            // Overlay Gradient
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.3),
                                    Colors.black.withValues(alpha: 0.9),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),

                            // Badge Category
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.gold.withValues(alpha: 0.4),
                                      width: 0.8),
                                ),
                                child: Text(
                                  template.category,
                                  style: AppFonts.poppins(
                                    size: 9,
                                    weight: FontWeight.w600,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ),
                            ),

                            // Title & Action
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    template.title,
                                    style: AppFonts.poppins(
                                      size: 12,
                                      weight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    template.description,
                                    style: AppFonts.poppins(
                                      size: 9,
                                      color: AppColors.white.withValues(alpha: 0.7),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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
        ),
      ),
    );
  }
}
