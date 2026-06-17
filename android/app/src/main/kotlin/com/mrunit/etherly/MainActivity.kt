package com.mrunit.etherly

import android.app.UiModeManager
import android.content.Context
import android.content.res.Configuration
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.mrunit.etherly/device_info"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isTv") {
                val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
                val isTv = uiModeManager.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION
                result.success(isTv)
            } else {
                result.notImplemented()
            }
        }
    }
}

