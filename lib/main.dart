import 'dart:async';

import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactor/core/external/sentry.dart';

import 'app/page/pages.dart';
import 'core/auth/auth.dart';
import 'core/common/retry-netwok-image.dart';
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
  final sentryReporter = SentryReporter()..init();

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
        AppNetworkImageWithRetry.init();
        return FutureBuilder(
          future: Future.wait([Auth().init(), Preferences().init()]),
          builder: (context, future) {
            return future.data != null
                ? StreamBuilder(
                    stream: _appTheme.stream,
                    builder: (_, theme) => App(theme: Preferences().theme),
                  )
                : Container(color: Color.fromRGBO(51, 51, 51, 1));
          },
        );
      },
    ));
  }, sentryReporter.reportError);
}

class App extends StatelessWidget {
  static StreamSink<AppTheme> get appTheme => _appTheme;

  final AppTheme theme;

  const App({Key key, this.theme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeMode themeMode;
    if (theme != AppTheme.AUTO) {
      themeMode = theme == AppTheme.DARK ? ThemeMode.dark : ThemeMode.light;
    }
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
        return ScrollConfiguration(
          behavior: EmptyBehavior(),
          child: child,
        );
      },
      home: Scaffold(
        body: DoubleBackToCloseApp(
          child: AppPages(),
          snackBar: const SnackBar(
            content: Text('Нажмите еще раз, чтобы выйти'),
          ),
        ),
      ),
    );
  }
}
