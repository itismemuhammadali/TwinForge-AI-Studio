import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../constants/legal_links.dart';
import 'register_screen.dart';
import 'main_shell.dart';
import 'forgot_password_screen.dart';
import 'admin_portal_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading       = false;
  String? _error;
  bool _obscurePass   = true;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onEnter() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() { _error = null; _loading = true; });
    
    final success = await context.read<AuthProvider>().signIn(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      final isAdmin = context.read<AuthProvider>().isAdmin;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim, anim2) =>
              isAdmin ? const AdminPortalScreen() : const MainShell(),
          transitionsBuilder: (context, anim, anim2, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      setState(() {
        _loading = false;
        _error = context.read<AuthProvider>().errorMessage ?? 'Sign in failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background portrait image (grayscale dark) ──────────────
          Image.network(
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb'
            '?q=80&w=2400',
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.65),
            colorBlendMode: BlendMode.darken,
          errorBuilder: (context, error, stack) => Container(color: AppColors.black),
          ),

          // gradient overlay — top & bottom fade to black
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xBF000000), // black/75 top
                  Colors.transparent,
                  Color(0xFF000000), // solid black bottom
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // ── Scrollable content ──────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      _buildHero(),
                      const SizedBox(height: 32),
                      _buildFormCard(),
                      const SizedBox(height: 20),
                      _buildLegalFooter(),
                      const SizedBox(height: 32),
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

  // ── Hero section ─────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Column(
      children: [
        // TWINORA Logo
        Image.asset(
          'assets/images/TWINORA.AI_LOGO.png',
          width: 160,
          height: 160,
          fit: BoxFit.contain,
        ),

        const SizedBox(height: 24),

        // Brand title: "TWIN" white + "ORA" gold
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'TWIN',
                style: AppFonts.playfair(
                  size: 52,
                  weight: FontWeight.w900,
                  color: AppColors.white,
                  letterSpacing: -1,
                ),
              ),
              TextSpan(
                text: 'ORA',
                style: AppFonts.playfair(
                  size: 52,
                  weight: FontWeight.w900,
                  color: AppColors.gold,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // FOR HER / FOR HIM divider row
        Row(
          children: [
            Expanded(
              child: Container(height: 0.5, color: AppColors.gold),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'FOR HER  •  FOR HIM',
                style: AppFonts.poppins(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 4,
                ),
              ),
            ),
            Expanded(
              child: Container(height: 0.5, color: AppColors.gold),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Tagline: "Your AI Digital Twin." — Playfair Display
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppFonts.playfair(
              size: 42,
              weight: FontWeight.w900,
              color: AppColors.white,
              height: 1.1,
            ),
            children: [
              const TextSpan(text: 'Your '),
              TextSpan(
                text: 'AI',
                style: AppFonts.playfair(
                  size: 42,
                  weight: FontWeight.w900,
                  color: AppColors.gold,
                  style: FontStyle.italic,
                ),
              ),
              const TextSpan(text: ' Digital Twin.'),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Three pillars row — Poppins
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _pillar('CONSISTENCY'),
            const SizedBox(width: 32),
            _pillar('LUXURY'),
            const SizedBox(width: 32),
            _pillar('HYPER-REAL'),
          ],
        ),
      ],
    );
  }

  Widget _pillar(String label) {
    return Column(
      children: [
        Text(
          label,
          style: AppFonts.poppins(
            size: 9,
            weight: FontWeight.w700,
            color: AppColors.white.withValues(alpha: 0.5),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Container(width: 32, height: 1, color: AppColors.gold.withValues(alpha: 0.6)),
      ],
    );
  }

  // ── Auth form card ────────────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xCC0C0C0C), // #0c0c0c / 80% opacity
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.1),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          // "ACCESS" heading — Playfair Display
          Text(
            'ACCESS',
            style: AppFonts.playfair(
              size: 28,
              weight: FontWeight.w900,
              color: AppColors.gold,
              letterSpacing: 6,
            ),
          ),

          const SizedBox(height: 32),

          // Studio Email field
          _buildFieldLabel('STUDIO EMAIL'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 20),

          // Password field
          _buildFieldLabel('PASSWORD'),
          const SizedBox(height: 4),
          // Forgot password row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, anim, anim2) => const ForgotPasswordScreen(),
                    transitionsBuilder: (context, anim, anim2, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                ),
                child: Text(
                  'FORGOT?',
                  style: AppFonts.poppins(
                    size: 10,
                    weight: FontWeight.w700,
                    color: AppColors.gold.withValues(alpha: 0.6),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _passwordCtrl,
            obscure: true,
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppFonts.poppins(
                size: 11,
                weight: FontWeight.w700,
                color: Colors.red.shade400,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 28),

          // ENTER button — gold bg, Poppins bold
          _buildEnterButton(),

          const SizedBox(height: 24),

          // Divider
          Container(height: 0.5, color: AppColors.white.withValues(alpha: 0.1)),

          const SizedBox(height: 20),

          // Register link
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, anim, anim2) => const RegisterScreen(),
                transitionsBuilder: (context, anim, anim2, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 500),
              ),
            ),
            child: Text(
              'NEW HERE? REGISTER YOUR TWIN',
              style: AppFonts.poppins(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.gold.withValues(alpha: 0.8),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: AppFonts.poppins(
          size: 10,
          weight: FontWeight.w700,
          color: AppColors.muted,
          letterSpacing: 3,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure && _obscurePass,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w300,
        color: AppColors.text,
      ),
      cursorColor: AppColors.gold,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.white.withValues(alpha: 0.05),
            width: 0.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        suffixIcon: obscure
            ? GestureDetector(
                onTap: () => setState(() => _obscurePass = !_obscurePass),
                child: Icon(
                  _obscurePass ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.muted,
                  size: 18,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildEnterButton() {
    return GestureDetector(
      onTap: _loading ? null : _onEnter,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.black,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'ENTER',
                style: AppFonts.poppins(
                  size: 12,
                  weight: FontWeight.w900,
                  color: AppColors.black,
                  letterSpacing: 5,
                ),
              ),
      ),
    );
  }

  Future<void> _openLegalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching legal link: $e');
    }
  }

  Widget _buildLegalFooter() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        GestureDetector(
          onTap: () => _openLegalUrl(LegalLinks.termsOfUseUrl),
          child: Text(
            'Terms of Use (EULA)',
            style: AppFonts.poppins(
              size: 11,
              color: AppColors.muted,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Text('•', style: TextStyle(color: AppColors.muted, fontSize: 11)),
        GestureDetector(
          onTap: () => _openLegalUrl(LegalLinks.privacyPolicyUrl),
          child: Text(
            'Privacy Policy',
            style: AppFonts.poppins(
              size: 11,
              color: AppColors.muted,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
