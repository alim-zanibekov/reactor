package ru.alimzanibekov.reactor

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.File
import java.io.FileNotFoundException

class MainActivity : FlutterActivity() {
    private val files = mutableListOf<File>()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result -> onMethodCall(call, result) }
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getUserAgent" -> {
                    result.success(System.getProperty("http.agent"))
                }
                "installApk" -> {
                    val filePath = call.argument<String>("filePath") ?: throw NullPointerException()
                    installApk(filePath)
                    result.success(true)
                }
                "getApkInfo" -> {
                    val filePath = call.argument<String>("filePath") ?: throw NullPointerException()
                    val info = packageManager.getPackageArchiveInfo(filePath, 0)
                        ?: throw NullPointerException()
                    result.success(
                        mapOf(
                            "versionName" to info.versionName,
                            "versionCode" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                                info.longVersionCode.toString()
                            } else {
                                @Suppress("DEPRECATION")
                                info.versionCode.toString()
                            }
                        )
                    )
                }
                else -> result.notImplemented()
            }
        } catch (e: Throwable) {
            result.error(e.javaClass.simpleName, e.message, null)
        }
    }

    private fun installApk(filePath: String) {
        val activity: Activity = this.activity
        val file = File(filePath)
        if (!file.exists())
            throw FileNotFoundException(filePath)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            if (canRequestPackageInstalls(activity)) {
                install(activity, file)
            } else {
                showSettingPackageInstall(activity, file)
            }
        } else {
            installBelow24(activity, file)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == installRequestCode) {
            if (resultCode == Activity.RESULT_OK) {
                files.forEach {
                    install(this.activity, it)
                }
                files.clear()
            }
        }
    }

    private fun showSettingPackageInstall(activity: Activity, file: File) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
            intent.data = Uri.parse("package:" + activity.packageName)
            intent.putExtra(Intent.EXTRA_RETURN_RESULT, true)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            files.add(file)
            activity.startActivityForResult(intent, installRequestCode)
        } else {
            throw RuntimeException("VERSION.SDK_INT < O")
        }
    }

    private fun canRequestPackageInstalls(activity: Activity): Boolean {
        return Build.VERSION.SDK_INT <= Build.VERSION_CODES.O || activity.packageManager.canRequestPackageInstalls()
    }

    private fun installBelow24(activity: Activity, file: File) {
        val intent = Intent(Intent.ACTION_VIEW)
        val uri = Uri.fromFile(file)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        intent.setDataAndType(uri, "application/vnd.android.package-archive")
        activity.startActivity(intent)
    }

    private fun install(activity: Activity, file: File) {
        val intent = Intent(Intent.ACTION_VIEW)
        val uri: Uri = FileProvider.getUriForFile(
            context,
            "${activity.packageName}.install",
            file
        )
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        intent.setDataAndType(uri, "application/vnd.android.package-archive")
        activity.startActivity(intent)
    }

    companion object {
        const val installRequestCode = 1470691
        const val channel = "channel:reactor"
    }
}
