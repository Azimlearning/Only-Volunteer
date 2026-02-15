import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';

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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('OnlyVolunteer', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Volunteer & Aid Management', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: _isSignUp ? 'Password (min 6)' : 'Password',
                  ),
                  obscureText: true,
                ),
                if (!_isSignUp)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _forgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _submitEmailAuth,
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isSignUp ? 'Sign up' : 'Sign in with Email'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('Sign in with Google'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : () => setState(() { _isSignUp = !_isSignUp; _error = null; }),
                  child: Text(_isSignUp ? 'Already have an account? Sign in' : 'Don\'t have an account? Sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
