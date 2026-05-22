import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'generate_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});
  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _tabLabels = ['All', 'Images', 'Carousels', 'Videos'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AimrAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.muted),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TWINORA Logo
              Image.asset(
                'assets/images/TWINORA.AI_LOGO.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('CONTENT LIBRARY',
                        style: AppFonts.poppins(size: 10, weight: FontWeight.w700,
                            color: AppColors.muted, letterSpacing: 4)),
                    const SizedBox(height: 4),
                    Text('Your Studio',
                        style: AppFonts.playfair(size: 28, weight: FontWeight.w900,
                            color: AppColors.white)),
                  ]),
                  // Generate button in header
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const GenerateScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: AppColors.gold.withValues(alpha: 0.3),
                              blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.add, color: AppColors.black, size: 16),
                        const SizedBox(width: 4),
                        Text('Generate',
                            style: AppFonts.poppins(size: 11, weight: FontWeight.w700,
                                color: AppColors.black)),
                      ]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.06), width: 0.5),
          ),
          child: TabBar(
            controller: _tabs,
            indicator: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 0.5),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle: AppFonts.poppins(size: 10, weight: FontWeight.w700, letterSpacing: 1),
            unselectedLabelStyle: AppFonts.poppins(size: 10),
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.muted,
            tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
          ),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: _tabLabels.map((_) => _buildEmptyState(context)).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Manifest Identity',
            style: AppFonts.playfair(size: 40, weight: FontWeight.w900,
                color: AppColors.gold.withValues(alpha: 0.5))),
        const SizedBox(height: 12),
        Text('AWAITING GENERATION',
            style: AppFonts.poppins(size: 10, weight: FontWeight.w700,
                color: AppColors.muted.withValues(alpha: 0.4), letterSpacing: 4)),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const GenerateScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 0.8),
              borderRadius: BorderRadius.circular(24),
              color: AppColors.gold.withValues(alpha: 0.08),
            ),
            child: Text('START GENERATING',
                style: AppFonts.poppins(size: 11, weight: FontWeight.w700,
                    color: AppColors.gold, letterSpacing: 3)),
          ),
        ),
      ]),
    );
  }
}
