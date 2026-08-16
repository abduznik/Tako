import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/session.dart';
import 'app/theme.dart';
import 'app/theme_controller.dart';
import 'screens/launch/launch_screen.dart';
import 'storage/app_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStorage.init();
  runApp(const TakoApp());
}

class TakoApp extends StatelessWidget {
  const TakoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Session()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'Tako',
            theme: buildTakoLightTheme(),
            darkTheme: buildTakoDarkTheme(),
            themeMode: themeController.themeMode,
            home: const LaunchScreen(),
          );
        },
      ),
    );
  }
}
