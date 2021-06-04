import 'dart:async';

import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// import 'package:flutter_user_agent/flutter_user_agent.dart';

import 'app/home.dart';
import 'core/auth/auth.dart';
import 'core/common/in-app-notifications-manager.dart';
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

  FlutterError.onError = (FlutterErrorDetails details) {
    if (isInDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };
  runZonedGuarded<Future<void>>(() async {
    runApp(Builder(
      builder: (context) {
        return FutureBuilder(
          future: Future.wait([
            Auth().init(),
            Preferences().init(),
            SentryReporter().init(),
            // FlutterUserAgent.init(),
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

  const App({Key key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  AppTheme _theme = Preferences().theme;
  StreamSubscription<String> _notificationsSubscription;

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
  Widget build(BuildContext context) {
    ThemeMode themeMode;
    if (_theme != AppTheme.AUTO) {
      themeMode = _theme == AppTheme.DARK ? ThemeMode.dark : ThemeMode.light;
    }
    // Headers.updateUserAgent(FlutterUserAgent.webViewUserAgent);

    return MaterialApp(
      theme: ThemeData(
        primaryColor: Color.fromRGBO(253, 178, 1, 1),
        accentColor: Color.fromRGBO(253, 207, 93, 1),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        accentColor: Color.fromRGBO(253, 207, 93, 1),
      ),
      themeMode: themeMode,
      builder: (context, child) {
        return ScrollConfiguration(behavior: EmptyBehavior(), child: child);
      },
      home: Scaffold(
        body: DoubleBackToCloseApp(
          child: Builder(builder: (context) {
            if (_notificationsSubscription != null) {
              _notificationsSubscription.cancel();
            }
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
