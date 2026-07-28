package com.mrunit.etherly

import android.app.UiModeManager
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    private val DEVICE_INFO_CHANNEL = "com.mrunit.etherly/device_info"
    private val SHORTCUT_CHANNEL = "com.mrunit.etherly/shortcut"

    private var shortcutChannel: MethodChannel? = null
    private var chromeCastHelper: ChromeCast? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_INFO_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isTv") {
                val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
                val isTv = uiModeManager.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION
                result.success(isTv)
            } else {
                result.notImplemented()
            }
        }

        val createShortcut = CreateShortcut(this)
        shortcutChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHORTCUT_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                createShortcut.handleMethodCall(call, result, intent)
            }
        }

        chromeCastHelper = ChromeCast(this).apply {
            register(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        chromeCastHelper?.unregister()
        chromeCastHelper = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val stationId = intent.getStringExtra("station_id")
        if (!stationId.isNullOrEmpty()) {
            intent.removeExtra("station_id")
            shortcutChannel?.invokeMethod("onStationShortcutOpened", stationId)
        }
    }
}
