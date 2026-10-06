import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'app/config/app_config.dart';
import 'data/storage/storage_service.dart';
import 'providers/theme_provider.dart';
import 'providers/finance_provider.dart';
import 'core/services/security_service.dart';
import 'core/localization/app_localizations.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/pin_lock_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/saas_backend_service.dart';
import 'features/update/models/app_update_info.dart';
import 'features/update/services/app_update_service.dart';
import 'features/update/screens/force_update_screen.dart';
import 'features/update/widgets/update_available_dialog.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize persistence storage & security
  final storageService = StorageService();
  await storageService.init();
  await SecurityService.instance.init();

  // Supabase initialization
  try {
    await Supabase.initialize(
      url: 'https://dcwdjpjgxtagaozvkesr.supabase.co',
      anonKey: 'sb_publishable_O7pwSVJsGL2U2kQv6VkYog_bzEaunT1',
    );
  } catch (e) {
    debugPrint('Supabase initialization failed (Are keys empty?): $e');
  }

  final saas = SaaSBackendService();
  await saas.initializeDatabase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),
        ChangeNotifierProvider(create: (_) => FinanceProvider(storageService)),
      ],
      child: const AstrackApp(),
    ),
  );
}

class AstrackApp extends StatefulWidget {
  const AstrackApp({super.key});

  @override
  State<AstrackApp> createState() => _AstrackAppState();
}

class _AstrackAppState extends State<AstrackApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lock the app when it goes to background
    if (state == AppLifecycleState.paused) {
      SecurityService.instance.lockApp();
    } else if (state == AppLifecycleState.resumed) {
      _checkUpdateOnResume();
    }
  }

  Future<void> _checkUpdateOnResume() async {
    try {
      final (status, info) = await AppUpdateService().check();
      if (!mounted || info == null) return;
      final nav = rootNavigatorKey.currentState;
      if (nav == null || !nav.mounted) return;

      if (status == UpdateStatus.forced) {
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => ForceUpdateScreen(info: info)),
          (route) => false,
        );
      } else if (status == UpdateStatus.optional) {
        final ctx = nav.context;
        final isDark = Provider.of<ThemeProvider>(ctx, listen: false).isDarkMode;
        UpdateAvailableDialog.show(ctx, info: info, isDark: isDark);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: themeProvider.lightThemeData,
      darkTheme: themeProvider.darkThemeData,
      themeMode: themeProvider.themeMode,
      locale: themeProvider.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final factor = themeProvider.textScale.factor;
        final scaledMediaQuery = mediaQuery.copyWith(
          textScaler: _ScaledTextScaler(mediaQuery.textScaler, factor),
        );

        return MediaQuery(
          data: scaledMediaQuery,
          child: ValueListenableBuilder<bool>(
            valueListenable: SecurityService.instance.isLockedNotifier,
            builder: (context, isLocked, _) {
              return Stack(
                children: [
                  if (child != null) child,
                  if (isLocked)
                    Positioned.fill(
                      child: Navigator(
                        onGenerateRoute: (settings) => MaterialPageRoute(
                          builder: (ctx) => PinLockScreen(
                            mode: PinMode.unlock,
                            onSuccess: () {
                              SecurityService.instance.unlockApp();
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Custom TextScaler combining device accessibility font size with user preference
class _ScaledTextScaler extends TextScaler {
  final TextScaler parent;
  final double factor;

  const _ScaledTextScaler(this.parent, this.factor);

  @override
  double get textScaleFactor => parent.textScaleFactor * factor;

  @override
  double scale(double fontSize) => parent.scale(fontSize) * factor;

  @override
  TextScaler clamp({double minScaleFactor = 0, double maxScaleFactor = double.infinity}) {
    return _ScaledTextScaler(
      parent.clamp(minScaleFactor: minScaleFactor, maxScaleFactor: maxScaleFactor),
      factor,
    );
  }
}
