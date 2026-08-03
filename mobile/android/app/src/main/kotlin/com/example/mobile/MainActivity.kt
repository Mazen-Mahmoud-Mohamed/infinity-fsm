package com.example.mobile

import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity is required by local_auth for biometric prompts.
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "com.infinity.fsm/monotonic_clock"

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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "elapsedRealtimeMs") {
                    result.success(SystemClock.elapsedRealtime())
                } else {
                    result.notImplemented()
                }
            }
    }
}
