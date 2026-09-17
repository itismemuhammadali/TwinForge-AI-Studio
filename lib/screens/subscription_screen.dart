import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../providers/user_provider.dart';
import '../services/iap_service.dart';
import '../models/credit_config.dart';
import '../constants/legal_links.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _selectedPlanIndex = 2; // Default to Pro ⭐ plan

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final iapService = Provider.of<IapService>(context, listen: false);
      if (iapService.products.isEmpty && !iapService.isLoading) {
        iapService.loadProducts();
      }
    });
  }

  Future<void> _openUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $e', style: AppFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  final List<_Plan> _plans = const [
    _Plan(
      id: CreditConfig.subStarter,
      name: 'STARTER',
      price: '\$27',
      period: '/mo',
      credits: '600 Credits / month',
      badge: '',
      color: Color(0xFFB1946C),
      features: [
        '600 monthly credits',
        'Up to 300 HD images',
        'All photoshoot templates',
        'Direct Talk & Cinematic B-Roll',
        'Content library & downloads',
      ],
    ),
    _Plan(
      id: CreditConfig.subPlus,
      name: 'PLUS',
      price: '\$47',
      period: '/mo',
      credits: '1,200 Credits / month',
      badge: '',
      color: Color(0xFF3498DB),
      features: [
        '1,200 monthly credits',
        'Consistent weekly content creation',
        'All image & video features',
        'Talking Head & Carousel generator',
        'High resolution 1080p & 4K exports',
      ],
    ),
    _Plan(
      id: CreditConfig.subPro,
      name: 'PRO',
      price: '\$97',
      period: '/mo',
      credits: '3,000 Credits / month',
      badge: 'RECOMMENDED',
      color: AppColors.gold,
      features: [
        '3,000 monthly credits',
        'Full month consistency across images & videos',
        'Natural Talk with Premium Lip-Sync',
        'Priority queue processing',
        'Twinora University advanced',
      ],
    ),
    _Plan(
      id: CreditConfig.subBusiness,
      name: 'BUSINESS',
      price: '\$197.99',
      period: '/mo',
      credits: '6,000 Credits / month',
      badge: 'ENTERPRISE',
      color: Color(0xFF9B59B6),
      features: [
        '6,000 monthly credits',
        'Heavy creators, brands & agencies',
        'Complete content production system',
        'Dedicated VIP support',
        'All Phase 1 & 2 features included',
      ],
    ),
  ];

  final List<_CreditPack> _packs = const [
    _CreditPack(CreditConfig.topUp250, '250 Credits', '\$14.99'),
    _CreditPack(CreditConfig.topUp500, '500 Credits', '\$28.99'),
    _CreditPack(CreditConfig.topUp1000, '1,000 Credits', '\$54.99'),
    _CreditPack(CreditConfig.topUp2000, '2,000 Credits', '\$104.99'),
    _CreditPack(CreditConfig.topUp4000, '4,000 Credits', '\$198.99'),
  ];

  Future<void> _handlePurchase(String productId) async {
    final iapService = Provider.of<IapService>(context, listen: false);
    if (iapService.isLoading) return;

    final success = await iapService.buyProduct(productId);
    if (!mounted) return;

    if (!success && iapService.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(iapService.errorMessage!, style: AppFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleRestore() async {
    final iapService = Provider.of<IapService>(context, listen: false);
    if (iapService.isLoading) return;

    await iapService.restorePurchases();
    if (!mounted) return;

    if (iapService.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(iapService.errorMessage!, style: AppFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchases restored successfully.', style: AppFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final iapService = context.watch<IapService>();

    if (iapService.lastPurchasedCredits != null) {
      final credits = iapService.lastPurchasedCredits!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        iapService.clearLastPurchasedCredits();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Success! $credits Credits added to your account.',
                    style: AppFonts.poppins(color: Colors.white, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF27AE60),
            duration: const Duration(seconds: 4),
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AimrAppBar(actions: [
        TextButton(
          onPressed: _handleRestore,
          child: Text(
            'RESTORE',
            style: AppFonts.poppins(size: 11, weight: FontWeight.w700, color: AppColors.gold),
          ),
        ),
      ]),
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.gold,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              await iapService.loadProducts();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Header
                Text('MEMBERSHIP & CREDITS',
                    style: AppFonts.poppins(
                      size: 10, weight: FontWeight.w700,
                      color: AppColors.gold, letterSpacing: 3,
                    )),
                const SizedBox(height: 8),
                Text('Choose Your Plan',
                    style: AppFonts.playfair(
                      size: 32, weight: FontWeight.w900, color: AppColors.white,
                    )),
                const SizedBox(height: 6),
                Text('Unlock the full power of your AI Twin',
                    style: AppFonts.poppins(size: 13, color: AppColors.muted, height: 1.5)),
                const SizedBox(height: 12),

                // Current plan indicator
                Consumer<UserProvider>(
                  builder: (context, userProvider, _) {
                    final plan = userProvider.subscription ?? 'free_trial';
                    final credits = userProvider.credits ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars, color: AppColors.gold, size: 20),
                          const SizedBox(width: 10),
                          Text('Current: ', style: AppFonts.poppins(size: 12, color: AppColors.muted)),
                          Text(_planLabel(plan),
                              style: AppFonts.poppins(size: 12, weight: FontWeight.w700, color: AppColors.gold)),
                          const Spacer(),
                          Text('$credits Credits',
                              style: AppFonts.poppins(size: 12, weight: FontWeight.w600, color: AppColors.text)),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Subscription Plan Cards
                ...List.generate(_plans.length, (i) => _buildPlanCard(i, iapService)),

                const SizedBox(height: 32),

                // Credit top-ups
                _buildDivider('CREDIT TOP-UPS'),
                const SizedBox(height: 8),
                Text('Top-up extra credits anytime for images, videos, and voice sync.',
                    style: AppFonts.poppins(size: 12, color: AppColors.muted)),
                const SizedBox(height: 20),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: _packs.length,
                  itemBuilder: (context, index) => _buildPackCard(_packs[index], iapService),
                ),

                const SizedBox(height: 32),

                // Apple Guideline 3.1.2 Mandatory Auto-Renewal & Legal Links Footer
                _buildLegalAndAutoRenewalFooter(),
              ],
            ),
          ),
        ),

          // Loading overlay during StoreKit communication
          if (iapService.isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.gold),
                        const SizedBox(height: 16),
                        Text(
                          'Connecting to App Store...',
                          style: AppFonts.poppins(size: 13, color: Colors.white, weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Please wait while the secure purchase sheet opens',
                          style: AppFonts.poppins(size: 11, color: AppColors.muted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegalAndAutoRenewalFooter() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'AUTO-RENEWABLE SUBSCRIPTION TERMS',
            style: AppFonts.poppins(
              size: 10,
              weight: FontWeight.w800,
              color: AppColors.gold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews monthly unless auto-renew is turned off at least 24 hours before the end of the current billing cycle. Your account will be charged for renewal within 24 hours prior to the end of the current cycle at the rate of your selected plan. You can manage or cancel your subscription anytime by navigating to your Apple ID Account Settings.',
            textAlign: TextAlign.center,
            style: AppFonts.poppins(
              size: 10.5,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              InkWell(
                onTap: () => _openUrl(LegalLinks.termsOfUseUrl),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'Terms of Use (EULA)',
                    style: AppFonts.poppins(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.gold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              Text('•', style: AppFonts.poppins(color: AppColors.muted, size: 12)),
              InkWell(
                onTap: () => _openUrl(LegalLinks.privacyPolicyUrl),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'Privacy Policy',
                    style: AppFonts.poppins(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.gold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              Text('•', style: AppFonts.poppins(color: AppColors.muted, size: 12)),
              InkWell(
                onTap: _handleRestore,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'Restore Purchases',
                    style: AppFonts.poppins(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.gold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _planLabel(String planId) {
    switch (planId) {
      case 'starter': return 'Starter Plan';
      case 'plus': return 'Plus Plan';
      case 'pro': return 'Pro Plan';
      case 'business': return 'Business Plan';
      default: return 'Free Trial';
    }
  }

  Widget _buildPlanCard(int i, IapService iapService) {
    final plan = _plans[i];
    final isSelected = _selectedPlanIndex == i;
    final displayPrice = iapService.getLocalizedPrice(plan.id, plan.price);

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = i),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? plan.color.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? plan.color : AppColors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.8 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.name,
                            style: AppFonts.poppins(
                              size: 14,
                              weight: FontWeight.w800,
                              color: isSelected ? plan.color : AppColors.text,
                              letterSpacing: 2,
                            ),
                          ),
                          if (plan.badge.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: plan.color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                plan.badge,
                                style: AppFonts.poppins(
                                  size: 8,
                                  weight: FontWeight.w900,
                                  color: AppColors.black,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(plan.credits, style: AppFonts.poppins(size: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: displayPrice,
                        style: AppFonts.playfair(
                          size: 26,
                          weight: FontWeight.w900,
                          color: isSelected ? plan.color : AppColors.text,
                        ),
                      ),
                      TextSpan(text: plan.period, style: AppFonts.poppins(size: 11, color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...plan.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: plan.color, size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f, style: AppFonts.poppins(size: 12, color: AppColors.text))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _handlePurchase(plan.id),
              child: Container(
                width: double.infinity,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected ? plan.color : Colors.transparent,
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(color: plan.color, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    'SUBSCRIBE NOW',
                    style: AppFonts.poppins(
                      size: 11,
                      weight: FontWeight.w900,
                      color: isSelected ? AppColors.black : plan.color,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(String label) {
    return Row(
      children: [
        Container(width: 32, height: 0.5, color: AppColors.gold.withValues(alpha: 0.4)),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppFonts.poppins(
            size: 10,
            weight: FontWeight.w700,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 0.5, color: AppColors.gold.withValues(alpha: 0.4))),
      ],
    );
  }

  Widget _buildPackCard(_CreditPack pack, IapService iapService) {
    final displayPrice = iapService.getLocalizedPrice(pack.id, pack.defaultPrice);

    return DarkCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(pack.credits, style: AppFonts.playfair(size: 18, weight: FontWeight.w900, color: AppColors.gold)),
          const SizedBox(height: 2),
          Text(displayPrice, style: AppFonts.poppins(size: 13, weight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _handlePurchase(pack.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'BUY NOW',
                style: AppFonts.poppins(
                  size: 9,
                  weight: FontWeight.w900,
                  color: AppColors.black,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Plan {
  final String id, name, price, period, credits, badge;
  final Color color;
  final List<String> features;

  const _Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    required this.credits,
    required this.badge,
    required this.color,
    required this.features,
  });
}

class _CreditPack {
  final String id, credits, defaultPrice;

  const _CreditPack(this.id, this.credits, this.defaultPrice);
}
