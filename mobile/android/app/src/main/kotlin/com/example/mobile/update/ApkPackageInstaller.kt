package com.example.mobile.update

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import java.io.File
import java.io.IOException

/**
 * Streams a verified APK into [PackageInstaller.Session] and commits it.
 *
 * Uses official Android APIs only. Never claims silent success when the OS
 * still requires a confirmation UI (STATUS_PENDING_USER_ACTION).
 */
object ApkPackageInstaller {
    private const val TAG = "InfinityApkInstaller"
    const val ACTION_INSTALL_STATUS = "com.example.mobile.UPDATE.APK_INSTALL_STATUS"
    const val EXTRA_SESSION_ID = "session_id"

    /**
     * @return result map for Flutter MethodChannel
     */
    fun install(context: Context, apkPath: String): Map<String, Any?> {
        val sdkInt = Build.VERSION.SDK_INT
        val canInstall = context.packageManager.canRequestPackageInstalls()
        Log.i(TAG, "install start sdk=$sdkInt canRequestPackageInstalls=$canInstall")

        if (!canInstall) {
            Log.i(TAG, "install blocked: unknown-sources permission not granted")
            return mapOf(
                "status" to "permission_required",
                "code" to "install_permission_required",
                "sdkInt" to sdkInt,
                "canRequestPackageInstalls" to false,
                "requireUserAction" to "required",
            )
        }

        val apkFile = File(apkPath)
        if (!apkFile.exists() || !apkFile.isFile) {
            Log.w(TAG, "install failed: missing apk")
            return failure("missing_artifact", sdkInt, canInstall)
        }
        if (apkFile.length() <= 0L) {
            Log.w(TAG, "install failed: empty apk")
            return failure("invalid_apk", sdkInt, canInstall)
        }

        val installer = context.packageManager.packageInstaller
        val params = PackageInstaller.SessionParams(
            PackageInstaller.SessionParams.MODE_FULL_INSTALL,
        )
        params.setAppPackageName(context.packageName)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            params.setInstallReason(PackageManager.INSTALL_REASON_USER)
        }

        var requireUserActionDecision = "unspecified"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // API 31+: request NOT_REQUIRED when the OS allows for same-app updates.
            // Android may still force a confirmation UI; STATUS_PENDING_USER_ACTION handles that.
            try {
                params.setRequireUserAction(
                    PackageInstaller.SessionParams.USER_ACTION_NOT_REQUIRED,
                )
                requireUserActionDecision = "not_required_requested"
                Log.i(TAG, "setRequireUserAction=USER_ACTION_NOT_REQUIRED")
            } catch (error: Exception) {
                requireUserActionDecision = "required"
                Log.w(TAG, "setRequireUserAction unavailable: ${error.javaClass.simpleName}")
            }
        } else {
            requireUserActionDecision = "required"
            Log.i(TAG, "API < 31: user action required by platform policy")
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            try {
                params.setRequestUpdateOwnership(true)
                Log.i(TAG, "setRequestUpdateOwnership=true")
            } catch (error: Exception) {
                Log.w(TAG, "setRequestUpdateOwnership unavailable: ${error.javaClass.simpleName}")
            }
        }

        var sessionId = -1
        var session: PackageInstaller.Session? = null
        try {
            sessionId = installer.createSession(params)
            Log.i(TAG, "PackageInstaller session created id=$sessionId")
            session = installer.openSession(sessionId)

            session.openWrite("infinity_update.apk", 0, apkFile.length()).use { out ->
                apkFile.inputStream().use { input ->
                    val buffer = ByteArray(64 * 1024)
                    while (true) {
                        val read = input.read(buffer)
                        if (read < 0) break
                        out.write(buffer, 0, read)
                    }
                    session.fsync(out)
                }
            }

            val statusIntent = Intent(context, ApkInstallStatusReceiver::class.java).apply {
                action = ACTION_INSTALL_STATUS
                setPackage(context.packageName)
                putExtra(EXTRA_SESSION_ID, sessionId)
            }

            val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                sessionId,
                statusIntent,
                pendingFlags,
            )

            session.commit(pendingIntent.intentSender)
            Log.i(
                TAG,
                "PackageInstaller session committed id=$sessionId " +
                    "requireUserActionDecision=$requireUserActionDecision",
            )

            // Commit accepted. Final OS status arrives asynchronously via the receiver.
            // Do not claim silent success here.
            return mapOf(
                "status" to "session_committed",
                "code" to "session_committed",
                "sdkInt" to sdkInt,
                "canRequestPackageInstalls" to true,
                "requireUserAction" to requireUserActionDecision,
                "sessionId" to sessionId,
            )
        } catch (error: SecurityException) {
            Log.e(TAG, "install security failure: ${error.javaClass.simpleName}")
            abandonQuietly(installer, sessionId, session)
            return failure("permission_denied", sdkInt, canInstall, sessionId)
        } catch (error: IOException) {
            Log.e(TAG, "install io failure: ${error.javaClass.simpleName}")
            abandonQuietly(installer, sessionId, session)
            val code = if (error.message?.contains("space", ignoreCase = true) == true) {
                "insufficient_storage"
            } else {
                "install_failed"
            }
            return failure(code, sdkInt, canInstall, sessionId)
        } catch (error: Exception) {
            Log.e(TAG, "install failure: ${error.javaClass.simpleName}")
            abandonQuietly(installer, sessionId, session)
            return failure("install_failed", sdkInt, canInstall, sessionId)
        } finally {
            try {
                session?.close()
            } catch (_: Exception) {
                // ignore
            }
        }
    }

    private fun failure(
        code: String,
        sdkInt: Int,
        canInstall: Boolean,
        sessionId: Int = -1,
    ): Map<String, Any?> {
        return mapOf(
            "status" to "failed",
            "code" to code,
            "sdkInt" to sdkInt,
            "canRequestPackageInstalls" to canInstall,
            "requireUserAction" to "required",
            "sessionId" to if (sessionId >= 0) sessionId else null,
        )
    }

    private fun abandonQuietly(
        installer: PackageInstaller,
        sessionId: Int,
        session: PackageInstaller.Session?,
    ) {
        try {
            session?.abandon()
        } catch (_: Exception) {
            // ignore
        }
        if (sessionId >= 0) {
            try {
                installer.abandonSession(sessionId)
            } catch (_: Exception) {
                // ignore
            }
        }
    }
}
