import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../variables.dart';

InAppWebViewGroupOptions inAppWebViewDefaultOptions() =>
    InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        debuggingEnabled: isInDebugMode,
        mediaPlaybackRequiresUserGesture: false,
        javaScriptCanOpenWindowsAutomatically: false,
        horizontalScrollBarEnabled: false,
        transparentBackground: true,
        useShouldOverrideUrlLoading: true,
        verticalScrollBarEnabled: false,
        javaScriptEnabled: true,
      ),
      android: AndroidInAppWebViewOptions(
        allowContentAccess: true,
        supportMultipleWindows: false,
        allowFileAccess: true,
        supportZoom: false,
      ),
    );
