import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'providers/app_provider.dart';
import 'providers/color_palette_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/plugin_provider.dart';
import 'screens/main_layout.dart';
import 'services/performance_service.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';
import 'services/version_check_service.dart';
import 'services/update_service.dart';

const double kMinWindowWidth = 1200.0;
const double kMinWindowHeight = 800.0;
const double kDefaultWindowWidth = 1400.0;
const double kDefaultWindowHeight = 900.0;
const double kSidebarAutoCollapseWidth = 1300.0;
const double kSidebarExpandedWidth = 200.0;
const double kSidebarCollapsedWidth = 72.0;

class AppException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(this.message, {this.originalError, this.stackTrace});

  @override
  String toString() => 'AppException: $message';
}

void _handleUncaughtError(Object error, StackTrace stackTrace) {
  debugPrint('=== 未捕获的错误 ===');
  debugPrint('错误类型: ${error.runtimeType}');
  debugPrint('错误信息: $error');
  debugPrint('堆栈跟踪: $stackTrace');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('=== Flutter 错误 ===');
    debugPrint('错误: ${details.exception}');
    debugPrint('堆栈: ${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    _handleUncaughtError(error, stack);
    return true;
  };

  runZonedGuarded<Future<void>>(
    () async {
      try {
        await _initializeApp();
      } catch (e, stack) {
        _handleUncaughtError(e, stack);
        rethrow;
      }
    },
    (error, stack) {
      _handleUncaughtError(error, stack);
    },
  );
}

Future<void> _initializeApp() async {
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    minimumSize: Size(kMinWindowWidth, kMinWindowHeight),
    size: Size(kDefaultWindowWidth, kDefaultWindowHeight),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: '拼豆设计器',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final settingsService = SettingsService();
  await settingsService.initialize();

  final storageService = StorageService();
  await storageService.initialize();

  final performanceService = PerformanceService();
  await performanceService.initialize();

  final versionCheckService = VersionCheckService();
  await versionCheckService.initialize();

  runApp(
    PerlerBeadDesignerApp(
      settingsService: settingsService,
      performanceService: performanceService,
    ),
  );
}

class PerlerBeadDesignerApp extends StatelessWidget {
  final SettingsService settingsService;
  final PerformanceService performanceService;

  const PerlerBeadDesignerApp({
    super.key,
    required this.settingsService,
    required this.performanceService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              AppProvider(settingsService: settingsService)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => ColorPaletteProvider()..loadDefaultPalette(),
        ),
        ChangeNotifierProvider(
          create: (_) => InventoryProvider()..loadInventory(),
        ),
        ChangeNotifierProvider(create: (_) => PluginProvider()),
        ChangeNotifierProvider.value(value: performanceService),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return MaterialApp(
            title: '拼豆设计器',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(appProvider.themeColors),
            darkTheme: _buildDarkTheme(appProvider.themeColors),
            themeMode: appProvider.themeMode,
            home: const MainLayout(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme(ThemeColors themeColors) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: themeColors.primaryColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme.copyWith(
        secondary: themeColors.secondaryColor,
        tertiary: themeColors.accentColor,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelType: NavigationRailLabelType.all,
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  ThemeData _buildDarkTheme(ThemeColors themeColors) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: themeColors.primaryColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: colorScheme.copyWith(
        secondary: themeColors.secondaryColor,
        tertiary: themeColors.accentColor,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelType: NavigationRailLabelType.all,
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
