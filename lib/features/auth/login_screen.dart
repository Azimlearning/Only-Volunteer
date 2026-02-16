import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  String? _error;

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
        title: const Text('Select your role'),
        content: const Text('How do you want to use OnlyVolunteer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(UserRole.volunteer),
            child: const Text('User - Join drives & volunteer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(UserRole.ngo),
            child: const Text('Organizer - Create & manage drives'),
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
        title: const Text('Forgot password'),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left side - Gradient background (matches Figma)
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    figmaOrange.withOpacity(0.8),
                    figmaPurple.withOpacity(0.8),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/onlyvolunteer_logo.png',
                      width: 120,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.volunteer_activism, size: 60, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'OnlyVolunteer',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right side - Login form (matches Figma)
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: figmaBlack,
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[300]!),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Google Sign-In Button
                        OutlinedButton(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.grey),
                            foregroundColor: figmaBlack,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: LinearGradient(
                                    colors: [Colors.blue, Colors.green, Colors.yellow, Colors.red],
                                    stops: const [0.0, 0.33, 0.66, 1.0],
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'G',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('Continue with Google'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Divider with "or"
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: _isSignUp ? 'Password (min 6)' : 'Password',
                            border: const OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                        if (!_isSignUp) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : _forgotPassword,
                              style: TextButton.styleFrom(
                                foregroundColor: figmaPurple,
                              ),
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _submitEmailAuth,
                            style: FilledButton.styleFrom(
                              backgroundColor: figmaOrange,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(
                                    _isSignUp ? 'Sign up' : 'Login',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSignUp ? 'Already have an account? ' : 'Don\'t have an account? ',
                              style: const TextStyle(color: figmaBlack),
                            ),
                            TextButton(
                              onPressed: _isLoading ? null : () => setState(() { _isSignUp = !_isSignUp; _error = null; }),
                              style: TextButton.styleFrom(
                                foregroundColor: figmaPurple,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(_isSignUp ? 'Sign in' : 'Sign Up'),
                            ),
                          ],
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
    );
  }
}
