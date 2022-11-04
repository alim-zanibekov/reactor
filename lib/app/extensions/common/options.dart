import 'package:flutter_inappwebview/flutter_inappwebview.dart';

InAppWebViewGroupOptions inAppWebViewDefaultOptions() =>
    InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        mediaPlaybackRequiresUserGesture: false,
        horizontalScrollBarEnabled: false,
        transparentBackground: true,
        useShouldOverrideUrlLoading: true,
        verticalScrollBarEnabled: false,
        javaScriptEnabled: true,
        supportZoom: false,
      ),
      android: AndroidInAppWebViewOptions(
        useShouldInterceptRequest: true,
        allowContentAccess: true,
        supportMultipleWindows: false,
        allowFileAccess: false,
        geolocationEnabled: false,
      ),
    );
