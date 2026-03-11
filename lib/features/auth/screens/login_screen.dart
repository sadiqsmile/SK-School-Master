// features/auth/screens/login_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/core/utils/school_storage.dart';
import 'package:school_app/services/parent_account_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  static const String _superAdminEmail = 'sadiq.smile@gmail.com';

  final TextEditingController _identityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  late final AnimationController _animationController;
  late final AnimationController _buttonAnimationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _buttonScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
    _buttonAnimationController.forward(from: 0.3);
  }

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  String _normalizePhone(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  bool _looksLikePhone(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return false;
    final digits = _normalizePhone(raw);

    final hasPhoneChars = RegExp(r'^[0-9+()\\-\\s]+$').hasMatch(raw);
    return hasPhoneChars && digits.length >= 10;
  }

  bool _looksLikeEmail(String input) {
    final raw = input.trim();
    if (!raw.contains('@')) return false;
    final parts = raw.split('@');
    if (parts.length != 2) return false;
    return parts[1].contains('.');
  }

  IconData _getInputIcon() {
    final input = _identityController.text;
    final digits = _normalizePhone(input);

    if (digits.length >= 5) {
      return Icons.smartphone_rounded;
    } else if (_looksLikeEmail(input)) {
      return Icons.alternate_email_rounded;
    }
    return Icons.account_circle_outlined;
  }

  Color _getInputIconColor() {
    final input = _identityController.text.trim().toLowerCase();
    final digits = _normalizePhone(input);

    if (input == _superAdminEmail) {
      return const Color(0xFFFF8C00); // Vibrant orange for super admin
    } else if (digits.length >= 5) {
      return const Color(0xFF00D9FF); // Vibrant cyan
    } else if (_looksLikeEmail(input)) {
      return const Color(0xFF9D4EDD); // Vibrant purple
    }
    return const Color(0xFF5B6EFF); // Vibrant blue
  }

  String _getLoginLabel() {
    final input = _identityController.text.trim().toLowerCase();
    if (input.isEmpty) return '';

    if (input == _superAdminEmail) {
      return 'Super Admin';
    }

    final digits = _normalizePhone(input);
    if (digits.length >= 5) {
      return 'Parent Login';
    }

    if (_looksLikeEmail(input)) {
      return 'Staff Login';
    }

    return '';
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFE53935),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _syncSchoolContextForSignedInUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final schoolId = (userDoc.data()?['schoolId'] ?? '').toString().trim();

      if (schoolId.isNotEmpty) {
        await SchoolStorage.saveSchoolId(schoolId);
      }
    } catch (_) {
      // Keep login smooth even if metadata sync fails.
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final identity = _identityController.text.trim();
      final password = _passwordController.text.trim();

      if (identity.isEmpty || password.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackbar('Please fill in all fields');
        return;
      }

      if (_looksLikePhone(identity)) {
        final phoneDigits = _normalizePhone(identity);
        final token = await ParentAccountService().parentLogin(
          phone: phoneDigits,
          pin: password,
        );
        await FirebaseAuth.instance.signInWithCustomToken(token);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: identity,
          password: password,
        );
      }

      await _syncSchoolContextForSignedInUser();

      if (!mounted) return;
      context.go('/');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorSnackbar(e.message ?? 'Authentication failed');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorSnackbar(
          'Login failed. Please check your details and try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loginLabel = _getLoginLabel();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF06B6D4), // Cyan blue (SK logo)
              Color(0xFF8B5CF6), // Purple
              Color(0xFFEC4899), // Pink (SK logo)
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0x1A0B2F4A)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x400C2A44),
                            blurRadius: 32,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 88,
                                height: 88,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.school_rounded,
                                  size: 64,
                                  color: Color(0xFF0E5F83),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'SK School Master',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 30,
                                height: 1.08,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: Color(0xFF0F2D45),
                              ),
                            ),
                            SizedBox(
                              height: 48,
                              child: Center(
                                child: loginLabel.isNotEmpty
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE6F4FA),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFB7D8E8),
                                          ),
                                        ),
                                        child: Text(
                                          loginLabel,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.6,
                                            color: Color(0xFF1A617F),
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            Text(
                              'Enter email for staff or phone for parents',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                color: const Color(0xFF4A687C),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _identityController,
                              enabled: !_isLoading,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Email / Phone',
                                hintText: 'name@example.com or 9876543210',
                                prefixIcon: Icon(
                                  _getInputIcon(),
                                  color: _getInputIconColor(),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF3F8FC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFBBD0DF),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFBBD0DF),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1A7194),
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _passwordController,
                              enabled: !_isLoading,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _login(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(
                                  Icons.lock_open_rounded,
                                  color: Color(0xFFEC4899),
                                ),
                                suffixIcon: IconButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF8B5CF6),
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF3F8FC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFBBD0DF),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFBBD0DF),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1A7194),
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            ScaleTransition(
                              scale: _buttonScaleAnimation,
                              child: SizedBox(
                                height: 52,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(
                                          0x9906B6D4,
                                        ), // Semi-transparent cyan
                                        Color(
                                          0x998B5CF6,
                                        ), // Semi-transparent purple
                                        Color(
                                          0x99EC4899,
                                        ), // Semi-transparent pink
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            loginLabel.isEmpty
                                                ? 'Login'
                                                : loginLabel,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              shadows: [
                                                Shadow(
                                                  color: Color(0x40000000),
                                                  offset: Offset(0, 1),
                                                  blurRadius: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
