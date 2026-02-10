import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const OnlyVolunteerApp());
}

class OnlyVolunteerApp extends StatelessWidget {
  const OnlyVolunteerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'OnlyVolunteer',
      theme: appTheme,
      routerConfig: appRouter,
    );
  }
}
