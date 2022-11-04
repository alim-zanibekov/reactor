import 'dart:async';

import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app/home.dart';
import 'core/api/api.dart';
import 'core/auth/auth.dart';
import 'core/common/app-updater.dart';
import 'core/common/in-app-notifications-manager.dart';
import 'core/common/user-agent/user-agent.dart';
import 'core/external/error-reporter.dart';
import 'core/external/sentry.dart';
import 'core/preferences/preferences.dart';
import 'variables.dart';

final StreamController<AppTheme> _appTheme = StreamController<AppTheme>();

class EmptyBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  FlutterError.onError = (FlutterErrorDetails details) {
    if (isInDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      Zone.current.handleUncaughtError(
        details.exception,
        details.stack ?? StackTrace.current,
      );
    }
  };
  AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);

  runZonedGuarded<Future<void>>(() async {
    runApp(Builder(
      builder: (context) {
        return FutureBuilder(
          future: Future.wait([
            Auth().init(),
            Preferences()
                .init()
                .then((value) => Api.setHost(Preferences().host)),
            SentryReporter().init(),
            UserAgent.init(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              ErrorReporter.reportError(snapshot.error, null);
              print(snapshot.error);
            } else if (snapshot.data != null) {
              return App();
            }
            return Container(color: Color.fromRGBO(51, 51, 51, 1));
          },
        );
      },
    ));
  }, ErrorReporter.reportError);
}

class App extends StatefulWidget {
  static StreamSink<AppTheme> get appTheme => _appTheme;

  const App({Key? key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  AppTheme? _theme = Preferences().theme;
  StreamSubscription<String>? _notificationsSubscription;
  int _buildCount = 0;

  @override
  void initState() {
    super.initState();
    _appTheme.stream.listen((event) {
      setState(() {
        _theme = Preferences().theme;
      });
    });
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeMode? themeMode;
    if (_theme != AppTheme.AUTO) {
      themeMode = _theme == AppTheme.DARK ? ThemeMode.dark : ThemeMode.light;
    }
    if (UserAgent.userAgent != null) {
      AppHeaders.updateUserAgent(UserAgent.userAgent!);
    }

    return MaterialApp(
      theme: ThemeInfo.getTheme(),
      darkTheme: ThemeInfo.getThemeDark(),
      themeMode: themeMode,
      builder: (context, child) {
        return ScrollConfiguration(behavior: EmptyBehavior(), child: child!);
      },
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      home: Scaffold(
        body: DoubleBackToCloseApp(
          child: Builder(builder: (context) {
            if (_buildCount == 0) {
              AppUpdater().initialCheckUpdates(context);
            }
            _buildCount++;
            _notificationsSubscription?.cancel();
            _notificationsSubscription =
                InAppNotificationsManager.messages$.listen((String text) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(text)));
            });
            return AppPages();
          }),
          snackBar: const SnackBar(
            content: Text('Нажмите еще раз, чтобы выйти'),
          ),
        ),
      ),
    );
  }
}

class ThemeInfo {
  static const primaryColor = Color.fromRGBO(253, 207, 93, 1);

  static const MaterialColor primary =
      MaterialColor(_primaryPrimaryValue, <int, Color>{
    50: Color(0xFFFFF6E1),
    100: Color(0xFFFEE8B3),
    200: Color(0xFFFED980),
    300: Color(0xFFFEC94D),
    400: Color(0xFFFDBE27),
    500: Color(_primaryPrimaryValue),
    600: Color(0xFFFDAB01),
    700: Color(0xFFFCA201),
    800: Color(0xFFFC9901),
    900: Color(0xFFFC8A00),
  });
  static const int _primaryPrimaryValue = 0xFFFDB201;

  static const MaterialColor colors =
      MaterialColor(primaryDarkPrimaryValue, <int, Color>{
    50: Color(0xFFE4E4E4),
    100: Color(0xFFBCBCBC),
    200: Color(0xFF909090),
    300: Color(0xFF646464),
    400: Color(0xFF424242),
    500: Color(primaryDarkPrimaryValue),
    600: Color(0xFF1D1D1D),
    700: Color(0xFF181818),
    800: Color(0xFF141414),
    900: Color(0xFF0B0B0B),
  });
  static const int primaryDarkPrimaryValue = 0xFF212121;

  static final outlinedButtonSide =
      MaterialStateProperty.resolveWith<BorderSide?>(
    (Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed) ||
          states.contains(MaterialState.hovered) ||
          states.contains(MaterialState.selected)) {
        return BorderSide(
          color: ThemeInfo.primary.shade500,
          width: 1,
        );
      }
      return null;
    },
  );

  static ThemeData getTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: ThemeInfo.primary,
        accentColor: Color.fromRGBO(253, 207, 93, 1),
      ),
      indicatorColor: Color.fromRGBO(253, 207, 93, 1),
      primaryColor: Color.fromRGBO(253, 178, 1, 1),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.black87)
              .copyWith(side: outlinedButtonSide)),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.black87)),
    );
  }

  static ThemeData getThemeDark() {
    return ThemeData(
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: ThemeInfo.primary,
        accentColor: Color.fromRGBO(253, 207, 93, 1),
        brightness: Brightness.dark,
      ),
      indicatorColor: Color.fromRGBO(253, 207, 93, 1),
      brightness: Brightness.dark,
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.white)
              .copyWith(side: outlinedButtonSide)),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.white)),
    );
  }
}
