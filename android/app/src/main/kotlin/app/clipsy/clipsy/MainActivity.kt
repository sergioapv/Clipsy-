package app.clipsy.clipsy

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /** Text shared to Clipsy (e.g. a YouTube link), until Dart takes it. */
    private var pendingShare: String? = null
    private var shareChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Screen pinning. For an app that isn't a device owner,
                    // Android asks the user to confirm ("Pin this app?").
                    "startLockTask" -> result.success(
                        runCatching { startLockTask() }.isSuccess,
                    )
                    "stopLockTask" -> {
                        runCatching { stopLockTask() }
                        result.success(null)
                    }
                    "isLockTaskActive" -> result.success(isLockTaskActive())
                    else -> result.notImplemented()
                }
            }
        shareChannel = MethodChannel(messenger, SHARE_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeShared" -> {
                        result.success(pendingShare)
                        pendingShare = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Not on recreation (e.g. rotation): that share was already handled.
        if (savedInstanceState == null) captureShare(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (captureShare(intent)) shareChannel?.invokeMethod("shared", null)
    }

    /** Keeps the text of a "Share to Clipsy" intent for Dart to take. */
    private fun captureShare(intent: Intent?): Boolean {
        if (intent?.action != Intent.ACTION_SEND) return false
        if (intent.type?.startsWith("text/") != true) return false
        val text = intent.getStringExtra(Intent.EXTRA_TEXT)?.trim()
        if (text.isNullOrEmpty()) return false
        pendingShare = text.take(2048)
        return true
    }

    private fun isLockTaskActive(): Boolean {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
    }

    private companion object {
        const val CHANNEL = "app.clipsy/device_lock"
        const val SHARE_CHANNEL = "app.clipsy/share"
    }
}
