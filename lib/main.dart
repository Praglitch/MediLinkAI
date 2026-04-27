import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'src/providers/app_providers.dart';
import 'src/screens/auth_screen.dart';
import 'src/screens/role_selector_screen.dart';
import 'src/screens/splash_screen.dart';
import 'src/services/auth_service.dart';
import 'src/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MediLinkApp());
}

class MediLinkApp extends StatelessWidget {
  const MediLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..isMockMode = false,
      child: MaterialApp(
        title: 'MediLink AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _AppGate(),
      ),
    );
  }
}

/// Controls the splash → auth → dashboard flow.
class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(
        onComplete: () => setState(() => _splashDone = true),
      );
    }

    final authService = AuthService();
    final isMockMode = context.watch<AppState>().isMockMode;

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.data != null || isMockMode) {
          return const RoleSelectorScreen();
        }

        return AuthScreen(
          onAuthenticated: () => setState(() {}),
        );
      },
    );
  }
}
