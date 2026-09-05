package com.example.mobile.update

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.util.Log

/**
 * Receives [PackageInstaller] session status after [ApkPackageInstaller] commits.
 *
 * When the OS requires confirmation, launches the system confirmation Intent.
 * Does not invent silent success.
 */
class ApkInstallStatusReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ApkPackageInstaller.ACTION_INSTALL_STATUS) {
            return
        }

        val status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)
        val message = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)
        val sessionId = intent.getIntExtra(ApkPackageInstaller.EXTRA_SESSION_ID, -1)

        Log.i(
            TAG,
            "PackageInstaller status=$status sessionId=$sessionId message=${sanitize(message)}",
        )

        when (status) {
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                val confirmIntent = if (android.os.Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(Intent.EXTRA_INTENT)
                }
                if (confirmIntent != null) {
                    confirmIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    try {
                        context.startActivity(confirmIntent)
                        Log.i(TAG, "Launched PackageInstaller confirmation UI")
                    } catch (error: Exception) {
                        Log.e(TAG, "Failed to launch confirmation UI: ${error.javaClass.simpleName}")
                    }
                } else {
                    Log.w(TAG, "STATUS_PENDING_USER_ACTION without EXTRA_INTENT")
                }
            }
            PackageInstaller.STATUS_SUCCESS -> {
                Log.i(TAG, "PackageInstaller STATUS_SUCCESS")
            }
            PackageInstaller.STATUS_FAILURE_ABORTED -> {
                Log.w(TAG, "PackageInstaller cancelled/aborted by user or system")
            }
            PackageInstaller.STATUS_FAILURE_STORAGE -> {
                Log.w(TAG, "PackageInstaller insufficient storage")
            }
            PackageInstaller.STATUS_FAILURE_INVALID -> {
                Log.w(TAG, "PackageInstaller invalid APK")
            }
            PackageInstaller.STATUS_FAILURE_CONFLICT,
            PackageInstaller.STATUS_FAILURE_BLOCKED,
            PackageInstaller.STATUS_FAILURE_INCOMPATIBLE,
            PackageInstaller.STATUS_FAILURE -> {
                Log.w(TAG, "PackageInstaller failure status=$status")
            }
            else -> {
                Log.w(TAG, "PackageInstaller unhandled status=$status")
            }
        }
    }

    private fun sanitize(message: String?): String {
        if (message.isNullOrBlank()) return ""
        return message.take(160)
    }

    companion object {
        private const val TAG = "InfinityApkInstaller"
    }
}
