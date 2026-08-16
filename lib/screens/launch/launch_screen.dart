import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/session.dart';
import '../../storage/app_storage.dart';
import '../dashboard/dashboard_screen.dart';
import 'get_started_screen.dart';

/// First widget shown on app start. Runs [Session.bootstrap] and then routes
/// to the dashboard (silent login succeeded, or falling through to
/// standalone because a profile exists but couldn't connect) or to the
/// "Get Started" screen (no saved profile has ever been set up).
class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final session = context.read<Session>();
    await session.bootstrap();
    if (!mounted) return;

    final hasEverConfigured = AppStorage.profiles.isNotEmpty;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => hasEverConfigured || !session.isStandalone
            ? const DashboardScreen()
            : const GetStartedScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
