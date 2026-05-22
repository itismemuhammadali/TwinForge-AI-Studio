import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../providers/user_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _selectedPlan = 0;

  // Plans based on the screenshot (Standard = 300, not 400)
  final _plans = const [
    _Plan(
      id: 'free_trial',
      name: 'FREE TRIAL',
      price: '\$0',
      period: '',
      credits: '4 image generations — 1 day only',
      badge: '',
      color: Color(0xFF4A4A4A),
      features: [
        '4 image generations only',
        '1 day access',
        'NO permanent free plan',
        'Upgrade to continue after trial',
      ],
    ),
    _Plan(
      id: 'standard',
      name: 'STANDARD',
      price: '\$27',
      period: '/mo',
      credits: '300 image generations/month',
      badge: 'POPULAR',
      color: Color(0xFFB1946C),
      features: [
        '300 image generations/month',
        'All photoshoot templates',
        'Content library & downloads',
        'All Phase 1 features',
        'Twinora University basic',
      ],
    ),
    _Plan(
      id: 'creator',
      name: 'CREATOR',
      price: '\$47',
      period: '/mo',
      credits: '300 images + videos/month',
      badge: 'BEST VALUE',
      color: Color(0xFF9B59B6),
      features: [
        '300 image generations/month',
        '10 B-Roll clips/month',
        '5 Talking Head videos/month',
        'Carousel generator',
        'Advanced templates',
        'Twinora University advanced',
      ],
    ),
  ];

  final _packs = const [
    _CreditPack('50 Credits', '\$4.99'),
    _CreditPack('100 Credits', '\$8.99'),
    _CreditPack('250 Credits', '\$19.99'),
    _CreditPack('500 Credits', '\$34.99'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AimrAppBar(actions: []),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('MY PLAN',
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
            Text('Unlock the full power of your AI twin',
                style: AppFonts.poppins(size: 13, color: AppColors.muted, height: 1.5)),
            const SizedBox(height: 8),

            // Current plan indicator
            Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                final plan = userProvider.subscription ?? 'free_trial';
                final credits = userProvider.credits ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: AppColors.gold, size: 16),
                      const SizedBox(width: 8),
                      Text('Current: ${_planLabel(plan)}',
                          style: AppFonts.poppins(size: 12, weight: FontWeight.w600, color: AppColors.gold)),
                      const Spacer(),
                      Text('$credits credits remaining',
                          style: AppFonts.poppins(size: 11, color: AppColors.muted)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // Plan cards
            ...List.generate(_plans.length, (i) => _buildPlanCard(i)),

            const SizedBox(height: 32),

            // Feature gating table
            _buildFeatureGatingSection(),

            const SizedBox(height: 32),

            // Credit top-ups
            _buildDivider('CREDIT TOP-UPS'),
            const SizedBox(height: 8),
            Text('Additional credits purchasable any time inside the app.',
                style: AppFonts.poppins(size: 11, color: AppColors.muted)),
            const SizedBox(height: 20),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: _packs.map(_buildPackCard).toList(),
            ),

            const SizedBox(height: 32),

            // Note about payment
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.gold, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Payment integration coming soon. In-app purchases will use Apple billing for iOS. Users will never be redirected to a browser.',
                      style: AppFonts.poppins(size: 11, color: AppColors.gold, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: Text('Subscriptions auto-renew. Cancel anytime.',
                  style: AppFonts.poppins(size: 10, color: AppColors.muted.withValues(alpha: 0.5))),
            ),
          ],
        ),
      ),
    );
  }

  String _planLabel(String planId) {
    switch (planId) {
      case 'standard': return 'Standard \$27/mo';
      case 'creator': return 'Creator \$47/mo';
      default: return 'Free Trial';
    }
  }

  Widget _buildPlanCard(int i) {
    final plan = _plans[i];
    final isSelected = _selectedPlan == i;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = i),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? plan.color.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? plan.color : AppColors.white.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(plan.name,
                      style: AppFonts.poppins(
                        size: 13, weight: FontWeight.w700,
                        color: isSelected ? plan.color : AppColors.text,
                        letterSpacing: 2,
                      )),
                  if (plan.badge.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: plan.color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(plan.badge,
                          style: AppFonts.poppins(
                            size: 8, weight: FontWeight.w900,
                            color: AppColors.black, letterSpacing: 1,
                          )),
                    ),
                  ],
                ]),
                const SizedBox(height: 4),
                Text(plan.credits,
                    style: AppFonts.poppins(size: 11, color: AppColors.muted)),
              ]),
            ),
            RichText(
              text: TextSpan(children: [
                TextSpan(text: plan.price,
                    style: AppFonts.playfair(
                      size: 28, weight: FontWeight.w900,
                      color: isSelected ? plan.color : AppColors.text,
                    )),
                TextSpan(text: plan.period,
                    style: AppFonts.poppins(size: 11, color: AppColors.muted)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          ...plan.features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Icon(Icons.check_circle_outline, color: plan.color, size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text(f,
                  style: AppFonts.poppins(size: 12, color: AppColors.text))),
            ]),
          )),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment integration coming soon!',
                      style: AppFonts.poppins(color: AppColors.white)),
                  backgroundColor: AppColors.surface,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? plan.color : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: plan.color, width: 1.5),
              ),
              child: Center(
                child: Text(
                  isSelected ? 'SELECTED' : 'GET STARTED',
                  style: AppFonts.poppins(
                    size: 11, weight: FontWeight.w900,
                    color: isSelected ? AppColors.black : plan.color,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildFeatureGatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDivider('FEATURE GATING BY TIER'),
        const SizedBox(height: 16),
        _featureRow('Free Trial', 'Image generation only — limited credits', const Color(0xFF4A4A4A)),
        _featureRow('Standard \$27/mo', 'All photoshoot templates, library, downloads', AppColors.gold),
        _featureRow('Creator \$47/mo', 'Carousel + B-roll + talking head videos + advanced templates', const Color(0xFF9B59B6)),
        _featureRow('Twinora University basic', 'Free with any paid plan', AppColors.gold),
        _featureRow('Twinora University advanced', 'Creator tier only', const Color(0xFF9B59B6)),
      ],
    );
  }

  Widget _featureRow(String tier, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8, height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tier,
                    style: AppFonts.poppins(
                      size: 11, weight: FontWeight.w700, color: color,
                    )),
                const SizedBox(height: 2),
                Text(description,
                    style: AppFonts.poppins(size: 11, color: AppColors.muted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(String label) {
    return Row(children: [
      Container(width: 32, height: 0.5, color: AppColors.gold.withValues(alpha: 0.4)),
      const SizedBox(width: 12),
      Text(label,
          style: AppFonts.poppins(
            size: 10, weight: FontWeight.w700,
            color: AppColors.gold, letterSpacing: 2,
          )),
      const SizedBox(width: 12),
      Expanded(child: Container(height: 0.5, color: AppColors.gold.withValues(alpha: 0.4))),
    ]);
  }

  Widget _buildPackCard(_CreditPack pack) {
    return DarkCard(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(pack.credits,
            style: AppFonts.playfair(size: 18, weight: FontWeight.w900, color: AppColors.gold)),
        const SizedBox(height: 2),
        Text(pack.price,
            style: AppFonts.poppins(size: 13, weight: FontWeight.w600, color: AppColors.text)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment integration coming soon!',
                    style: AppFonts.poppins(color: AppColors.white)),
                backgroundColor: AppColors.surface,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.5),
            ),
            child: Text('BUY NOW',
                style: AppFonts.poppins(
                  size: 9, weight: FontWeight.w700,
                  color: AppColors.gold, letterSpacing: 2,
                )),
          ),
        ),
      ]),
    );
  }
}

class _Plan {
  final String id, name, price, period, credits, badge;
  final Color color;
  final List<String> features;
  const _Plan({
    required this.id, required this.name, required this.price,
    required this.period, required this.credits, required this.badge,
    required this.color, required this.features,
  });
}

class _CreditPack {
  final String credits, price;
  const _CreditPack(this.credits, this.price);
}
