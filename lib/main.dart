import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'auth/auth.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Reels use media_kit (bundled libmpv decoder) instead of video_player:
  // video_player delegates to the OS's hardware decoder, and some Android
  // devices (confirmed: MediaTek Codec2 on a Samsung Galaxy A13) hang
  // indefinitely inside that native decoder with no recoverable error.
  // media_kit ships its own decoder so playback doesn't depend on the
  // device's often-buggy vendor codec implementation.
  MediaKit.ensureInitialized();
  await ThemeController.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          key: ValueKey(mode),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: AuthPage(key: ValueKey('auth-$mode')),
        );
      },
    );
  }
}
