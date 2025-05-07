import 'dart:async';
import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:errorx/clash/clash.dart';
import 'package:errorx/common/common.dart';
import 'package:errorx/l10n/l10n.dart';
import 'package:errorx/manager/hotkey_manager.dart';
import 'package:errorx/manager/manager.dart';
import 'package:errorx/plugins/app.dart';
import 'package:errorx/providers/config.dart';
import 'package:errorx/services/api_service.dart';
import 'package:errorx/services/websocket_service.dart';
import 'package:errorx/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controller.dart';
import 'models/models.dart';
import 'pages/pages.dart';

class Application extends ConsumerStatefulWidget {
  const Application({
    super.key,
  });

  @override
  ConsumerState<Application> createState() => ApplicationState();
}

class ApplicationState extends ConsumerState<Application> {
  late ColorSchemes systemColorSchemes;
  Timer? _autoUpdateGroupTaskTimer;
  Timer? _autoUpdateProfilesTaskTimer;
  Timer? _connectionCheckTimer;
  bool _isLoggedIn = true; // Set to true by default
  final ApiService _apiService = ApiService();

  final _pageTransitionsTheme = const PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: CommonPageTransitionsBuilder(),
      TargetPlatform.windows: CommonPageTransitionsBuilder(),
      TargetPlatform.linux: CommonPageTransitionsBuilder(),
      TargetPlatform.macOS: CommonPageTransitionsBuilder(),
    },
  );

  ColorScheme _getAppColorScheme({
    required Brightness brightness,
    int? primaryColor,
    required ColorSchemes systemColorSchemes,
  }) {
    if (primaryColor != null) {
      return ColorScheme.fromSeed(
        seedColor: Color(primaryColor),
        brightness: brightness,
      );
    } else {
      return systemColorSchemes.getColorSchemeForBrightness(brightness);
    }
  }

  @override
  void initState() {
    super.initState();
    _setupApplicationController();
    _setupApiService();
    _autoUpdateGroupTask();
    _autoUpdateProfilesTask();
    _startConnectionCheck();
  }

  void _setupApiService() {
    // Simplified setup since we don't need login/logout handling
  }
  
  void _startConnectionCheck() {
    // Simplified connection check without login verification
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _apiService.checkConnection();
    });
  }
  
  void _setupApplicationController() {
    // Create the controller immediately
    globalState.appController = AppController(context, ref);
    
    // After the UI is built, set it up properly
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentContext = globalState.navigatorKey.currentContext;
      if (currentContext != null) {
        globalState.appController = AppController(currentContext, ref);
      }
      
      await globalState.appController.init();
      globalState.appController.initLink();
      app?.initShortcuts();
      
      if (Platform.isAndroid) {
        try {
          final webSocketService = WebSocketService();
          await webSocketService.initialize();
        } catch (e) {
          commonPrint.log('Error initializing WebSocket service: $e');
        }
      }
    });
  }

  _autoUpdateGroupTask() {
    _autoUpdateGroupTaskTimer = Timer(const Duration(milliseconds: 20000), () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        globalState.appController.updateGroupsDebounce();
        _autoUpdateGroupTask();
      });
    });
  }

  _autoUpdateProfilesTask() {
    _autoUpdateProfilesTaskTimer = Timer(const Duration(minutes: 20), () async {
      await globalState.appController.autoUpdateProfiles();
      _autoUpdateProfilesTask();
    });
  }

  _buildPlatformState(Widget child) {
    if (system.isDesktop) {
      return WindowManager(
        child: TrayManager(
          child: HotKeyManager(
            child: ProxyManager(
              child: child,
            ),
          ),
        ),
      );
    }
    return AndroidManager(
      child: TileManager(
        child: child,
      ),
    );
  }

  _buildState(Widget child) {
    return AppStateManager(
      child: ClashManager(
        child: ConnectivityManager(
          onConnectivityChanged: () {
            globalState.appController.updateLocalIp();
            globalState.appController.addCheckIpNumDebounce();
          },
          child: child,
        ),
      ),
    );
  }

  _buildPlatformApp(Widget child) {
    if (system.isDesktop) {
      return WindowHeaderContainer(
        child: child,
      );
    }
    return VpnManager(
      child: child,
    );
  }

  _buildApp(Widget child) {
    return MessageManager(
      child: ThemeManager(
        child: child,
      ),
    );
  }

  _updateSystemColorSchemes(
    ColorScheme? lightDynamic,
    ColorScheme? darkDynamic,
  ) {
    systemColorSchemes = ColorSchemes(
      lightColorScheme: lightDynamic,
      darkColorScheme: darkDynamic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globalState.appController.updateSystemColorSchemes(systemColorSchemes);
    });
  }

  @override
  Widget build(context) {
    return _buildPlatformState(
      _buildState(
        Consumer(
          builder: (_, ref, child) {
            final locale =
                ref.watch(appSettingProvider.select((state) => state.locale));
            final themeProps = ref.watch(themeSettingProvider);
            return DynamicColorBuilder(
              builder: (lightDynamic, darkDynamic) {
                _updateSystemColorSchemes(lightDynamic, darkDynamic);
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  navigatorKey: globalState.navigatorKey,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate
                  ],
                  builder: (_, child) {
                    return AppEnvManager(
                      child: _buildPlatformApp(
                        _buildApp(child!),
                      ),
                    );
                  },
                  scrollBehavior: BaseScrollBehavior(),
                  title: appName,
                  locale: other.getLocaleForString(locale),
                  supportedLocales: AppLocalizations.delegate.supportedLocales,
                  themeMode: themeProps.themeMode,
                  theme: ThemeData(
                    useMaterial3: true,
                    pageTransitionsTheme: _pageTransitionsTheme,
                    colorScheme: _getAppColorScheme(
                      brightness: Brightness.light,
                      systemColorSchemes: systemColorSchemes,
                      primaryColor: themeProps.primaryColor,
                    ),
                  ),
                  darkTheme: ThemeData(
                    useMaterial3: true,
                    pageTransitionsTheme: _pageTransitionsTheme,
                    colorScheme: _getAppColorScheme(
                      brightness: Brightness.dark,
                      systemColorSchemes: systemColorSchemes,
                      primaryColor: themeProps.primaryColor,
                    ),
                  ),
                  home: const HomePage(), // Always show HomePage
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    linkManager.destroy();
    _autoUpdateGroupTaskTimer?.cancel();
    _autoUpdateProfilesTaskTimer?.cancel();
    _connectionCheckTimer?.cancel();
    await clashCore.destroy();
    await globalState.appController.savePreferences();
    await globalState.appController.handleExit();
    super.dispose();
  }
}