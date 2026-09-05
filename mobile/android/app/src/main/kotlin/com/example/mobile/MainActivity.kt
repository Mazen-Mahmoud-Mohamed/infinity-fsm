package com.example.mobile

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.provider.Settings
import android.util.Log
import androidx.core.view.WindowCompat
import com.example.mobile.update.ApkPackageInstaller
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity is required by local_auth for biometric prompts.
class MainActivity : FlutterFragmentActivity() {
    private val clockChannelName = "com.infinity.fsm/monotonic_clock"
    private val apkInstallerChannelName = "com.infinity.fsm/apk_installer"
    private val installerTag = "InfinityApkInstaller"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Edge-to-edge: let Flutter paint behind system bars; colors come from
        // SystemUiOverlayStyle (AppSystemUi) so dark mode has no white nav strip.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, clockChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "elapsedRealtimeMs") {
                    result.success(SystemClock.elapsedRealtime())
                } else {
                    result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, apkInstallerChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canRequestPackageInstalls" -> {
                        val allowed = packageManager.canRequestPackageInstalls()
                        Log.i(
                            installerTag,
                            "canRequestPackageInstalls=$allowed sdk=${Build.VERSION.SDK_INT}",
                        )
                        result.success(allowed)
                    }
                    "openUnknownSourcesSettings" -> {
                        openUnknownSourcesSettings()
                        result.success(
                            mapOf(
                                "status" to "settings_opened",
                                "sdkInt" to Build.VERSION.SDK_INT,
                                "canRequestPackageInstalls" to
                                    packageManager.canRequestPackageInstalls(),
                            ),
                        )
                    }
                    "installApk" -> {
                        val apkPath = call.argument<String>("apkPath")
                        if (apkPath.isNullOrBlank()) {
                            result.success(
                                mapOf(
                                    "status" to "failed",
                                    "code" to "missing_artifact",
                                    "sdkInt" to Build.VERSION.SDK_INT,
                                    "canRequestPackageInstalls" to
                                        packageManager.canRequestPackageInstalls(),
                                ),
                            )
                            return@setMethodCallHandler
                        }

                        // Permission UX is owned by Flutter (throttle / resume).
                        // Native only reports permission_required without opening Settings here.
                        val installResult = ApkPackageInstaller.install(this, apkPath)
                        result.success(installResult)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun openUnknownSourcesSettings() {
        val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }
}
