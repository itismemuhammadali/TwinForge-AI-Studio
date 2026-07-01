import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import 'admin_upload_screen.dart';
import 'login_screen.dart';

class AdminPortalScreen extends StatefulWidget {
  const AdminPortalScreen({super.key});

  @override
  State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends State<AdminPortalScreen> {
  String? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAdminContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: AppColors.gold, size: 20),
          onPressed: () => _showLogoutDialog(context),
        ),
        title: Text(
          'ADMIN PORTAL',
          style: AppFonts.poppins(
            size: 13,
            weight: FontWeight.w700,
            color: AppColors.gold,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.gold, size: 20),
            onPressed: () => context.read<AdminProvider>().loadAdminContent(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          _buildStatsBar(),

          // Category filter chips
          _buildFilterChips(),

          // Content grid
          Expanded(child: _buildContentGrid()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminUploadScreen()),
          );
        },
        child: const Icon(Icons.add, color: AppColors.black, size: 28),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final total = admin.contentList.length;
        final podcastCount = admin.contentList.where((c) => c.category == 'Podcast').length;
        final trendingCount = admin.contentList.where((c) => c.category == 'Trending').length;
        final brollCount = admin.contentList.where((c) => c.category == 'B-Roll').length;
        final carouselCount = admin.contentList.where((c) => c.category == 'Carousel').length;
        final luxuryLifestyleCount = admin.contentList.where((c) => c.category == 'Luxury Lifestyle').length;
        final luxuryOfficeCount = admin.contentList.where((c) => c.category == 'Luxury Office').length;
        final luxuryCarCount = admin.contentList.where((c) => c.category == 'Luxury Car').length;
        final seasideWorkCount = admin.contentList.where((c) => c.category == 'Seaside Work').length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              _statChip('TOTAL', '$total', AppColors.gold),
              const SizedBox(width: 8),
              _statChip('PODCAST', '$podcastCount', const Color(0xFFE74C3C)),
              const SizedBox(width: 8),
              _statChip('TRENDING', '$trendingCount', const Color(0xFFf39c12)),
              const SizedBox(width: 8),
              _statChip('B-ROLL', '$brollCount', const Color(0xFFE8A0B4)),
              const SizedBox(width: 8),
              _statChip('CAROUSEL', '$carouselCount', const Color(0xFF9B59B6)),
              const SizedBox(width: 8),
              _statChip('LUXURY', '$luxuryLifestyleCount', const Color(0xFFD4AF37)),
              const SizedBox(width: 8),
              _statChip('OFFICE', '$luxuryOfficeCount', const Color(0xFF8B6914)),
              const SizedBox(width: 8),
              _statChip('CAR', '$luxuryCarCount', const Color(0xFFC0392B)),
              const SizedBox(width: 8),
              _statChip('SEASIDE', '$seasideWorkCount', const Color(0xFF1ABC9C)),
            ],
          ),
        );
      },
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppFonts.playfair(size: 18, weight: FontWeight.w900, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppFonts.poppins(size: 8, weight: FontWeight.w600, color: color, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip('All', null),
          const SizedBox(width: 8),
          ...AdminProvider.categories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _filterChip(cat, cat),
            );
          }),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? category) {
    final isSelected = _selectedCategoryFilter == category;
    final color = isSelected ? AppColors.gold : AppColors.muted;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryFilter = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.gold.withValues(alpha: 0.4) : AppColors.white.withValues(alpha: 0.1),
            width: 0.8,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppFonts.poppins(
            size: 10,
            weight: FontWeight.w700,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildContentGrid() {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        if (admin.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
          );
        }

        var filtered = admin.contentList;
        if (_selectedCategoryFilter != null) {
          filtered = filtered.where((c) => c.category == _selectedCategoryFilter).toList();
        }

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_outlined, size: 64, color: AppColors.muted.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(
                  'No content yet',
                  style: AppFonts.poppins(size: 14, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to upload your first image',
                  style: AppFonts.poppins(size: 12, color: AppColors.muted.withValues(alpha: 0.6)),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];
            return _contentCard(item);
          },
        );
      },
    );
  }

  Widget _contentCard(AdminContent item) {
    final categoryColor = _getCategoryColor(item.category);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                color: AppColors.surface,
                child: Icon(Icons.broken_image, color: AppColors.muted.withValues(alpha: 0.3)),
              ),
            ),
            // Category badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.category,
                  style: AppFonts.poppins(
                    size: 8,
                    weight: FontWeight.w700,
                    color: categoryColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            // Delete button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _confirmDelete(item),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 14),
                ),
              ),
            ),
            // Prompt indicator
            if (item.prompt != null && item.prompt!.isNotEmpty)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.gold, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        'AI Prompt',
                        style: AppFonts.poppins(size: 8, color: AppColors.gold),
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Podcast':
        return const Color(0xFFE74C3C);
      case 'Trending':
        return const Color(0xFFf39c12);
      case 'B-Roll':
        return const Color(0xFFE8A0B4);
      case 'Carousel':
        return const Color(0xFF9B59B6);
      case 'Luxury Lifestyle':
        return const Color(0xFFD4AF37);
      case 'Luxury Office':
        return const Color(0xFF8B6914);
      case 'Luxury Car':
        return const Color(0xFFC0392B);
      case 'Seaside Work':
        return const Color(0xFF1ABC9C);
      default:
        return AppColors.gold;
    }
  }

  void _confirmDelete(AdminContent item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Content?',
          style: AppFonts.playfair(size: 20, weight: FontWeight.w900, color: AppColors.gold),
        ),
        content: Text(
          'This will permanently remove the ${item.category} content.',
          style: AppFonts.poppins(size: 13, color: AppColors.muted, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: AppFonts.poppins(size: 11, weight: FontWeight.w700, color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AdminProvider>().deleteContent(item.id);
            },
            child: Text('DELETE', style: AppFonts.poppins(size: 11, weight: FontWeight.w700, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout?',
          style: AppFonts.playfair(size: 20, weight: FontWeight.w900, color: AppColors.gold),
        ),
        content: Text(
          'Are you sure you want to logout from admin portal?',
          style: AppFonts.poppins(size: 13, color: AppColors.muted, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: AppFonts.poppins(size: 11, weight: FontWeight.w700, color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: Text('LOGOUT', style: AppFonts.poppins(size: 11, weight: FontWeight.w700, color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
