import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/app_router.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final authNotifier = AuthNotifier();
  runApp(OnlyVolunteerApp(authNotifier: authNotifier));
}

class OnlyVolunteerApp extends StatelessWidget {
  const OnlyVolunteerApp({super.key, required this.authNotifier});

  final AuthNotifier authNotifier;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthNotifier>.value(
      value: authNotifier,
      child: MaterialApp.router(
        title: 'OnlyVolunteer',
        theme: appTheme,
        routerConfig: createAppRouter(authNotifier),
      ),
    );
  }
}
