package app.clipsy.clipsy

import android.app.ActivityManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
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
    }

    private fun isLockTaskActive(): Boolean {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
    }

    private companion object {
        const val CHANNEL = "app.clipsy/device_lock"
    }
}
