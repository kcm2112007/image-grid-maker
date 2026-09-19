import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

/// Holds the app's real, working theme-mode state.
/// Settings screen mutates this; MaterialApp listens to it.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system);

  void setMode(ThemeMode mode) => value = mode;
}

class ImageGridMakerApp extends StatelessWidget {
  const ImageGridMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Image Grid Maker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: HomeScreen(themeController: themeController),
        );
      },
    );
  }
}
