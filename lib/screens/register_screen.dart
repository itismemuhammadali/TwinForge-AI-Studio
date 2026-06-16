import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _loading       = false;
  bool _agreed        = false;
  String? _error;
  bool _obscurePass   = true;
  bool _obscureConf   = true;
  String _selectedGender = 'Female';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || 
        _passCtrl.text.isEmpty || _confirmCtrl.text.isEmpty) {
      setState(() => _error = 'PLEASE FILL IN ALL FIELDS');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'PASSWORDS DO NOT MATCH');
      return;
    }
    if (!_agreed) {
      setState(() => _error = 'PLEASE CONFIRM TO CONTINUE');
      return;
    }
    
    setState(() { _error = null; _loading = true; });
    
    final success = await context.read<AuthProvider>().signUp(
      _emailCtrl.text.trim(),
      _passCtrl.text,
      _nameCtrl.text.trim(),
      _selectedGender,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim, anim2) => VerificationScreen(email: _emailCtrl.text),
          transitionsBuilder: (context, anim, anim2, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      setState(() {
        _loading = false;
        _error = context.read<AuthProvider>().errorMessage ?? 'Sign up failed';
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
          // Same background as login
          Image.network(
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb'
            '?q=80&w=2400',
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.65),
            colorBlendMode: BlendMode.darken,
          errorBuilder: (context, error, stack) => Container(color: AppColors.black),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xBF000000),
                  Colors.transparent,
                  Color(0xFF000000),
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // TWINORA Logo
                  Image.asset(
                    'assets/images/TWINORA.AI_LOGO.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 24),

                  // Brand title
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'TWIN',
                          style: AppFonts.playfair(
                            size: 36,
                            weight: FontWeight.w900,
                            color: AppColors.white,
                          ),
                        ),
                        TextSpan(
                          text: 'ORA',
                          style: AppFonts.playfair(
                            size: 36,
                            weight: FontWeight.w900,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Form card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 40),
                    decoration: BoxDecoration(
                      color: const Color(0xCC0C0C0C),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.1),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      children: [
                        // ENROLLMENT heading
                        Text(
                          'ENROLLMENT',
                          style: AppFonts.playfair(
                            size: 28,
                            weight: FontWeight.w900,
                            color: AppColors.gold,
                            letterSpacing: 4,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Identity Name
                        _fieldLabel('IDENTITY NAME'),
                        const SizedBox(height: 8),
                        _textField(controller: _nameCtrl,
                            keyboardType: TextInputType.name),

                        const SizedBox(height: 20),

                        // Studio Email
                        _fieldLabel('STUDIO EMAIL'),
                        const SizedBox(height: 8),
                        _textField(controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress),

                        const SizedBox(height: 20),

                        // Password
                        _fieldLabel('CREATE ACCESS PASS'),
                        const SizedBox(height: 8),
                        _textField(
                          controller: _passCtrl,
                          obscure: true,
                          isConfirm: false,
                        ),

                        const SizedBox(height: 20),

                        // Confirm password
                        _fieldLabel('CONFIRM ACCESS PASS'),
                        const SizedBox(height: 8),
                        _textField(
                          controller: _confirmCtrl,
                          obscure: true,
                          isConfirm: true,
                        ),

                        const SizedBox(height: 20),

                        // Gender Selector
                        _fieldLabel('SELECT YOUR GENDER'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedGender = 'Female'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _selectedGender == 'Female'
                                        ? AppColors.gold.withValues(alpha: 0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedGender == 'Female'
                                          ? AppColors.gold
                                          : AppColors.white.withValues(alpha: 0.1),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'FEMALE',
                                      style: AppFonts.poppins(
                                        size: 11,
                                        weight: FontWeight.w700,
                                        color: _selectedGender == 'Female'
                                            ? AppColors.gold
                                            : AppColors.muted,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedGender = 'Male'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _selectedGender == 'Male'
                                        ? AppColors.gold.withValues(alpha: 0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedGender == 'Male'
                                          ? AppColors.gold
                                          : AppColors.white.withValues(alpha: 0.1),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'MALE',
                                      style: AppFonts.poppins(
                                        size: 11,
                                        weight: FontWeight.w700,
                                        color: _selectedGender == 'Male'
                                            ? AppColors.gold
                                            : AppColors.muted,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Agreement checkbox
                        GestureDetector(
                          onTap: () =>
                              setState(() => _agreed = !_agreed),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: _agreed
                                      ? AppColors.gold
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: AppColors.white
                                        .withValues(alpha: 0.2),
                                    width: 0.8,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: _agreed
                                    ? const Icon(Icons.check,
                                        color: AppColors.black, size: 12)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'I understand that I must sign up and log in using the same email used to purchase this app. Access may be delayed or removed if emails do not match.',
                                      style: AppFonts.poppins(
                                        size: 10,
                                        weight: FontWeight.w700,
                                        color: AppColors.muted,
                                        letterSpacing: 1,
                                        height: 1.7,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'PLEASE CONFIRM TO CONTINUE.',
                                      style: AppFonts.poppins(
                                        size: 10,
                                        weight: FontWeight.w700,
                                        color: AppColors.gold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

                        const SizedBox(height: 32),

                        // Privacy Disclaimer
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.security,
                                  color: AppColors.gold,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PRIVACY & ETHICS POLICY',
                                      style: AppFonts.poppins(
                                        size: 10,
                                        weight: FontWeight.w800,
                                        color: AppColors.gold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'To protect privacy, you must only use your own face for generation. Please do not upload photos of others without their explicit consent.',
                                      style: AppFonts.poppins(
                                        size: 10,
                                        color: AppColors.white.withValues(alpha: 0.8),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // REGISTER button
                        GestureDetector(
                          onTap: _loading ? null : _onRegister,
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.gold.withValues(alpha: 0.2),
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
                                    'REGISTER',
                                    style: AppFonts.poppins(
                                      size: 12,
                                      weight: FontWeight.w900,
                                      color: AppColors.black,
                                      letterSpacing: 5,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Container(
                            height: 0.5,
                            color:
                                AppColors.white.withValues(alpha: 0.1)),

                        const SizedBox(height: 20),

                        // Back to login
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder: (context, anim, anim2) =>
                                  const LoginScreen(),
                              transitionsBuilder: (context, anim, anim2, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration:
                                  const Duration(milliseconds: 500),
                            ),
                          ),
                          child: Text(
                            'RETURN TO LOGIN',
                            style: AppFonts.poppins(
                              size: 10,
                              weight: FontWeight.w700,
                              color: AppColors.white
                                  .withValues(alpha: 0.3),
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) => Align(
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

  Widget _textField({
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    bool isConfirm = false,
  }) {
    final isObscured = isConfirm ? _obscureConf : _obscurePass;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure && isObscured,
      style: AppFonts.poppins(
        size: 16,
        weight: FontWeight.w300,
        color: AppColors.text,
      ),
      cursorColor: AppColors.gold,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 18),
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
                onTap: () => setState(() {
                  if (isConfirm) {
                    _obscureConf = !_obscureConf;
                  } else {
                    _obscurePass = !_obscurePass;
                  }
                }),
                child: Icon(
                  isObscured ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.muted,
                  size: 18,
                ),
              )
            : null,
      ),
    );
  }
}
