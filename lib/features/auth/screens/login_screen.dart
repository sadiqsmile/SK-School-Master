// features/auth/screens/login_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:school_app/services/parent_account_service.dart';
import 'package:school_app/core/utils/school_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final identifier = emailController.text.trim();
      final secret = passwordController.text.trim();

      if (identifier.isEmpty || secret.isEmpty) {
        setState(() {
          _errorMessage = 'Please fill in all fields';
          _isLoading = false;
        });
        return;
      }

      final mode = _getLoginMode(identifier);
      if (mode == _LoginMode.none) {
        setState(() {
          _errorMessage = 'Enter email or phone number';
          _isLoading = false;
        });
        return;
      }

      if (mode == _LoginMode.parent) {
        // Login-first UX: do not require a locally selected School ID.
        // The backend resolves the parent account + school from the phone.
        // Module access is enforced post-login in AuthGate.
        if (!_isPinLike(secret)) {
          setState(() {
            _errorMessage = 'Enter a valid PIN (4-12 digits)';
            _isLoading = false;
          });
          return;
        }

        final token = await ParentAccountService().parentLogin(
          phone: identifier,
          pin: secret,
        );

        await FirebaseAuth.instance.signInWithCustomToken(token);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: identifier,
          password: secret,
        );
      }

      final signedInUser = FirebaseAuth.instance.currentUser;
      if (signedInUser != null) {
        final ok = await _ensureSelectedSchoolMatchesAccount(signedInUser);
        if (!ok) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }
      }

      if (mounted) {
        context.go("/");
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Authentication failed';
        _isLoading = false;
      });
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'FUNCTIONS LOGIN ERROR: code=${e.code} message=${e.message} details=${e.details}',
        );
      }
      setState(() {
        _errorMessage = _friendlyFunctionsError(e);
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LOGIN ERROR: $e');
      }
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<bool> _ensureSelectedSchoolMatchesAccount(User user) async {
    final selected = (await SchoolStorage.getSchoolId())?.trim();
    if (selected == null || selected.isEmpty) {
      // No selection saved (legacy flow) — don't block login.
      return true;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = userDoc.data();

      // If there's no user profile, let AuthGate handle it.
      if (data == null) return true;

      // Super admin should not be constrained by stored school id.
      final role = (data['role'] ?? '').toString().trim();
      if (role == 'superAdmin') return true;

      final accountSchoolId = (data['schoolId'] ?? '').toString().trim();
      if (accountSchoolId.isEmpty) return true;

      // Keep local storage in sync.
      if (selected != accountSchoolId) {
        await FirebaseAuth.instance.signOut();
        await SchoolStorage.clearSchool();
        if (mounted) {
          setState(() {
            _errorMessage =
                'This account belongs to a different school. Tap “Change School” and try again.';
          });
        }
        return false;
      }

      // Selected matches; ensure it's saved (no-op if already).
      await SchoolStorage.saveSchoolId(accountSchoolId);
      return true;
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final identifier = emailController.text.trim();
    final mode = _getLoginMode(identifier);
    final isParent = mode == _LoginMode.parent;
    final isStaff = mode == _LoginMode.staff;

    // Modern gradient colors matching the SK logo
    const primaryBlue = Color(0xFF06B6D4); // Cyan blue from logo
    const primaryPink = Color(0xFFEC4899); // Pink from logo
    const accentPurple = Color(0xFF8B5CF6); // Purple blend

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryBlue, accentPurple, primaryPink],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: screenWidth > 800 ? 480 : double.infinity,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: SizedBox(
                  height: screenHeight > 700 ? screenHeight - 80 : null,
                  child: Column(
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 30 : 50,
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/logo.png',
                                width: 120,
                                height: 120,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    child: const Icon(
                                      Icons.school_rounded,
                                      size: 60,
                                      color: primaryBlue,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'SK School Master',
                                style: TextStyle(
                                  fontSize: isMobile ? 24 : 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(30),
                                      topRight: Radius.circular(30),
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 20,
                                        offset: const Offset(0, -5),
                                      ),
                                    ],
                                  ),
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.all(isMobile ? 24 : 40),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Login to your account',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Welcome back! Sign in to continue',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 30),
                                        if (_errorMessage != null) ...[
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              border: Border.all(
                                                color: Colors.red[400]!,
                                                width: 1.5,
                                              ),
                                              borderRadius: BorderRadius.circular(
                                                10,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red[700],
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    _errorMessage!,
                                                    style: TextStyle(
                                                      color: Colors.red[700],
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                        ],
                                        TextField(
                                          controller: emailController,
                                          enabled: !_isLoading,
                                          decoration: InputDecoration(
                                            hintText: isParent
                                                ? 'Enter phone number'
                                                : 'name@example.com',
                                            labelText: 'Email/Phone',
                                            prefixIcon: Icon(
                                              isParent
                                                  ? Icons.phone_rounded
                                                  : Icons.email_rounded,
                                              color: primaryBlue,
                                            ),
                                            suffixIcon: (isStaff &&
                                                    _isValidEmail(
                                                      emailController.text,
                                                    ))
                                                ? const Icon(
                                                    Icons.check_circle,
                                                    color: primaryBlue,
                                                  )
                                                : null,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: primaryBlue.withValues(
                                                  alpha: 0.3,
                                                ),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: primaryBlue,
                                                width: 2,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 16,
                                                ),
                                          ),
                                          keyboardType: isParent
                                              ? TextInputType.phone
                                              : TextInputType.emailAddress,
                                          inputFormatters: isParent
                                              ? [
                                                  FilteringTextInputFormatter
                                                      .allow(
                                                    RegExp(r'[0-9+\-\s()]'),
                                                  ),
                                                ]
                                              : null,
                                          onChanged: (_) => setState(() {}),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: passwordController,
                                          enabled: !_isLoading,
                                          decoration: InputDecoration(
                                            hintText: isParent
                                                ? 'Enter 4-digit PIN'
                                                : 'Enter your password',
                                            labelText:
                                                isParent ? 'PIN' : 'Password',
                                            prefixIcon: const Icon(
                                              Icons.lock_rounded,
                                              color: primaryBlue,
                                            ),
                                            suffixIcon: GestureDetector(
                                              onTap: () => setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              }),
                                              child: Icon(
                                                _obscurePassword
                                                    ? Icons
                                                          .visibility_off_rounded
                                                    : Icons.visibility_rounded,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: primaryBlue.withValues(
                                                  alpha: 0.3,
                                                ),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: primaryBlue,
                                                width: 2,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 16,
                                                ),
                                          ),
                                          obscureText: _obscurePassword,
                                          keyboardType: isParent
                                              ? TextInputType.number
                                              : TextInputType.text,
                                          inputFormatters: isParent
                                              ? [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                  LengthLimitingTextInputFormatter(
                                                    12,
                                                  ),
                                                ]
                                              : null,
                                          onChanged: (_) => setState(() {}),
                                        ),
                                        if (mode != _LoginMode.none) ...[
                                          const SizedBox(height: 12),
                                          Center(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: (isParent
                                                        ? primaryPink
                                                        : primaryBlue)
                                                    .withValues(alpha: 0.10),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                border: Border.all(
                                                  color: (isParent
                                                          ? primaryPink
                                                          : primaryBlue)
                                                      .withValues(alpha: 0.25),
                                                ),
                                              ),
                                              child: Text(
                                                isParent
                                                    ? 'Parent login'
                                                    : 'Staff login',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: isParent
                                                      ? primaryPink
                                                      : primaryBlue,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 54,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  primaryBlue,
                                                  accentPurple,
                                                  primaryPink,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(27),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: accentPurple.withValues(
                                                    alpha: 0.4,
                                                  ),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              onPressed:
                                                  _isLoading ? null : login,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.transparent,
                                                foregroundColor: Colors.white,
                                                shadowColor:
                                                    Colors.transparent,
                                                shape:
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            27,
                                                          ),
                                                    ),
                                                elevation: 0,
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      height: 24,
                                                      width: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 3,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                  Color
                                                                >(
                                                                  Colors.white,
                                                                ),
                                                          ),
                                                    )
                                                  : Text(
                                                      isParent
                                                          ? 'PARENT LOGIN'
                                                          : isStaff
                                                              ? 'STAFF LOGIN'
                                                              : 'LOGIN',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        letterSpacing: 1.2,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        // Login-first UX: hide legacy school pre-selection.
                                        const SizedBox.shrink(),
                                        const SizedBox(height: 30),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildEducationIcon(
                                              Icons.book,
                                              'Library',
                                              primaryBlue,
                                            ),
                                            _buildEducationIcon(
                                              Icons.school,
                                              'Courses',
                                              accentPurple,
                                            ),
                                            _buildEducationIcon(
                                              Icons.emoji_events,
                                              'Awards',
                                              primaryPink,
                                            ),
                                            _buildEducationIcon(
                                              Icons.calculate,
                                              'Learning',
                                              primaryBlue,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                      ],
                                    ),
                                  ),
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
    );
  }

  Widget _buildEducationIcon(IconData icon, String label, Color primaryColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: primaryColor.withAlpha(51),
              width: 1.5,
            ),
          ),
          child: Icon(icon, size: 28, color: primaryColor),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  bool _isValidEmail(String email) {
    return email.isNotEmpty && email.contains('@');
  }

  _LoginMode _getLoginMode(String identifier) {
    if (identifier.trim().isEmpty) return _LoginMode.none;

    // Staff: only when it looks like a valid email.
    if (_isValidEmail(identifier)) return _LoginMode.staff;

    // Parent: only when it clearly looks like a phone number.
    if (identifier.contains('@')) return _LoginMode.none;
    final digits = identifier.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) return _LoginMode.parent;

    // Otherwise ambiguous -> show nothing.
    return _LoginMode.none;
  }

  bool _isPinLike(String pin) {
    return RegExp(r'^[0-9]{4,12}$').hasMatch(pin.trim());
  }

  String _friendlyFunctionsError(FirebaseFunctionsException e) {
    // Prefer server message when available.
    final msg = (e.message ?? '').trim();
    if (msg.isNotEmpty) return msg;

    switch (e.code) {
      case 'not-found':
        return 'Parent account not found. Please check phone number.';
      case 'permission-denied':
        return 'Invalid phone or PIN.';
      case 'invalid-argument':
        return 'Please enter a valid phone number and PIN.';
      case 'unauthenticated':
        return 'Please try again.';
      default:
        return 'Login failed. Please try again.';
    }
  }
}

enum _LoginMode { none, staff, parent }
