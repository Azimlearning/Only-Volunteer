import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Single source of auth state for the app. Listen to [authStateChanges] and
/// use [currentUser] / [appUser] in router redirect and screens.
class AuthNotifier extends ChangeNotifier {
  AuthNotifier({
    AuthService? authService,
    FirestoreService? firestoreService,
  })  : _auth = authService ?? AuthService(),
        _firestore = firestoreService ?? FirestoreService() {
    _subscription = _auth.authStateChanges.listen(_onAuthStateChanged);
  }

  final AuthService _auth;
  final FirestoreService _firestore;
  StreamSubscription<User?>? _subscription;

  User? _firebaseUser;
  AppUser? _appUser;
  bool _appUserLoaded = false;

  User? get currentUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoggedIn => _firebaseUser != null;
  bool get appUserLoaded => _appUserLoaded;

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    _appUserLoaded = false;
    _appUser = null;
    if (user != null) {
      _appUser = await _firestore.getUser(user.uid);
      _appUserLoaded = true;
    }
    notifyListeners();
  }

  /// Call after creating/updating AppUser (e.g. after role selection) to refresh.
  Future<void> refreshAppUser() async {
    if (_firebaseUser == null) return;
    _appUser = await _firestore.getUser(_firebaseUser!.uid);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
