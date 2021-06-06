package ru.alimzanibekov.reactor

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant


class MainActivity : FlutterActivity() {
    private val userAgentChannel = "channel:reactor"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, userAgentChannel)
                .setMethodCallHandler { call, result ->
                    if (call.method.equals("getUserAgent"))
                        result.success(System.getProperty("http.agent"))
                    else
                        result.notImplemented()
                }
    }
}
