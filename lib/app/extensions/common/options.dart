import 'package:flutter_inappwebview/flutter_inappwebview.dart';

InAppWebViewGroupOptions inAppWebViewDefaultOptions() =>
    InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        debuggingEnabled: true,
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
