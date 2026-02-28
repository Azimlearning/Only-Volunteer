import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _error;
  
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final cred = await _auth.signInWithGoogle();
      if (cred?.user == null || !mounted) return;
      var appUser = await _auth.getAppUser(cred!.user!.uid);
      final isNewUser = appUser == null;
      if (appUser == null) {
        appUser = AppUser(
          uid: cred.user!.uid,
          email: cred.user!.email ?? '',
          displayName: cred.user!.displayName,
          photoUrl: cred.user!.photoURL,
          createdAt: DateTime.now(),
        );
        await _auth.createOrUpdateUser(appUser);
      }
      if (mounted) {
        if (isNewUser) {
          await _showRolePickerAndGo(appUser!);
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty) {
      setState(() => _error = 'Enter email');
      return;
    }
    if (password.isEmpty && !_isSignUp) {
      setState(() => _error = 'Enter password');
      return;
    }
    if (_isSignUp && password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      if (_isSignUp) {
        final cred = await _auth.signUpWithEmail(email, password);
        var appUser = AppUser(
          uid: cred.user!.uid,
          email: email,
          displayName: cred.user?.displayName,
          createdAt: DateTime.now(),
        );
        await _auth.createOrUpdateUser(appUser);
        if (mounted) await _showRolePickerAndGo(appUser);
      } else {
        final cred = await _auth.signInWithEmail(email, password);
        var appUser = await _auth.getAppUser(cred.user!.uid);
        if (appUser == null) {
          appUser = AppUser(uid: cred.user!.uid, email: email, displayName: cred.user!.displayName, createdAt: DateTime.now());
          await _auth.createOrUpdateUser(appUser);
          if (mounted) await _showRolePickerAndGo(appUser);
        } else if (mounted) {
          context.go('/home');
        }
      }
    } on Exception catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showRolePickerAndGo(AppUser appUser) async {
    final role = await showDialog<UserRole>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Select your role', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
        content: Text('How do you want to use OnlyVolunteer?', style: GoogleFonts.dmSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(UserRole.volunteer),
            child: Text('User - Join drives & volunteer', style: GoogleFonts.dmSans()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(UserRole.ngo),
            child: Text('Organizer - Create & manage drives', style: GoogleFonts.dmSans()),
          ),
        ],
      ),
    );
    if (role != null && mounted) {
      final updated = AppUser(
        uid: appUser.uid,
        email: appUser.email,
        displayName: appUser.displayName,
        photoUrl: appUser.photoUrl,
        role: role,
        skills: appUser.skills,
        interests: appUser.interests,
        points: appUser.points,
        badges: appUser.badges,
        createdAt: appUser.createdAt,
      );
      await _auth.createOrUpdateUser(updated);
      if (mounted) {
        Provider.of<AuthNotifier>(context, listen: false).refreshAppUser();
        context.go('/home');
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    final controller = TextEditingController(text: email);
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Forgot password', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email to receive reset link',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) Navigator.pop(context, true);
            },
            style: FilledButton.styleFrom(backgroundColor: appCoral),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    if (submitted != true || !mounted) return;
    final targetEmail = controller.text.trim();
    if (targetEmail.isEmpty) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      await _auth.sendPasswordResetEmail(targetEmail);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent. Check your inbox.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;

    return Scaffold(
      backgroundColor: appCream,
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: _buildRightPanel(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(child: _buildLeftPanel()),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: _buildRightPanel(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      color: appDark,
      child: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -80,
            left: -80,
            child: _buildBlob(appCoral, 320),
          ),
          Positioned(
            bottom: 60,
            right: -60,
            child: _buildBlob(appAmber, 240),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.5,
            left: MediaQuery.of(context).size.width * 0.2,
            child: _buildBlob(appSuccess, 180),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 48.0),
                    child: Image.asset(
                      'assets/onlyvolunteer_logo.png',
                      height: 360, // 3x bigger
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                
                // Hero Content
                const SizedBox(height: 28),
                Text(
                  'Make your',
                  style: GoogleFonts.fraunces(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [appCoral, appAmber],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  child: Text(
                    'impact',
                    style: GoogleFonts.fraunces(
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
                Text(
                  'count.',
                  style: GoogleFonts.fraunces(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Connect with causes that matter, track your volunteer hours, and build a community around shared values.',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.55),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(Color color, double size) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }



  Widget _buildRightPanel() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSignUp ? 'Create an account 🚀' : 'Welcome back 👋',
                style: GoogleFonts.fraunces(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: appDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isSignUp ? 'Join our community of volunteers today.' : 'Good to see you again. Sign in to continue your journey.',
                style: GoogleFonts.dmSans(fontSize: 15, color: appMuted),
              ),
              const SizedBox(height: 36),
              
              InkWell(
                onTap: _isLoading ? null : _signInWithGoogle,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: appBorder, width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const SweepGradient(
                            colors: [Colors.blue, Colors.red, Colors.yellow, Colors.green, Colors.blue],
                          ),
                        ),
                        child: const Center(child: Text('G', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Continue with Google',
                        style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: appDark),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(child: Divider(color: appBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or sign in with email', style: GoogleFonts.dmSans(fontSize: 13, color: appMuted)),
                  ),
                  const Expanded(child: Divider(color: appBorder)),
                ],
              ),
              const SizedBox(height: 28),
              
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.dmSans(color: Colors.red[800], fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Email Field
              Text('EMAIL', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: appMid, letterSpacing: 0.2)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  hintStyle: GoogleFonts.dmSans(color: appMuted),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: appBorder, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: appCoral, width: 1.5)),
                ),
                style: GoogleFonts.dmSans(fontSize: 15, color: appDark),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              // Password Field
              Text('PASSWORD', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: appMid, letterSpacing: 0.2)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: GoogleFonts.dmSans(color: appMuted),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: appBorder, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: appCoral, width: 1.5)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: appMuted, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                style: GoogleFonts.dmSans(fontSize: 15, color: appDark),
              ),
              
              const SizedBox(height: 24),
              if (!_isSignUp) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 24, height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v ?? false),
                            activeColor: appCoral,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            side: const BorderSide(color: appBorder, width: 1.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Remember me', style: GoogleFonts.dmSans(fontSize: 14, color: appMid)),
                      ],
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _forgotPassword,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text('Forgot password?', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: appCoral)),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
              ] else const SizedBox(height: 12),
              
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: appCoral.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8)),
                  ],
                  gradient: const LinearGradient(
                    colors: [appCoral, Color(0xFFFF7A25)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _submitEmailAuth,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                _isSignUp ? 'Sign Up' : 'Sign In',
                                style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.2),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp ? 'Already have an account? ' : 'New to OnlyVolunteer? ',
                      style: GoogleFonts.dmSans(fontSize: 14, color: appMuted),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : () => setState(() { _isSignUp = !_isSignUp; _error = null; }),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text(
                        _isSignUp ? 'Sign in' : 'Create an account',
                        style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: appCoral),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: appSuccess),
                    const SizedBox(width: 6),
                    Text(
                      'Secured with Firebase Auth & end-to-end encryption',
                      style: GoogleFonts.dmSans(fontSize: 12, color: appMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
