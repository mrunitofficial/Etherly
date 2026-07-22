package com.mrunit.etherly

import android.app.UiModeManager
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.annotation.NonNull
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    private val DEVICE_INFO_CHANNEL = "com.mrunit.etherly/device_info"
    private val SHORTCUT_CHANNEL = "com.mrunit.etherly/shortcut"

    private var shortcutChannel: MethodChannel? = null

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

        shortcutChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHORTCUT_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "isPinShortcutSupported" -> {
                        result.success(ShortcutManagerCompat.isRequestPinShortcutSupported(this@MainActivity))
                    }
                    "pinStationShortcut" -> {
                        val id = call.argument<String>("id")
                        val name = call.argument<String>("name")
                        val iconBytes = call.argument<ByteArray>("iconBytes")

                        if (id.isNullOrEmpty() || name.isNullOrEmpty()) {
                            result.error("INVALID_ARGS", "Station ID and name are required", null)
                            return@setMethodCallHandler
                        }

                        val launchIntent = Intent(this@MainActivity, MainActivity::class.java).apply {
                            action = Intent.ACTION_VIEW
                            putExtra("station_id", id)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                        }

                        val icon = if (iconBytes != null && iconBytes.isNotEmpty()) {
                            val bitmap = BitmapFactory.decodeByteArray(iconBytes, 0, iconBytes.size)
                            if (bitmap != null) {
                                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                                    val adaptiveBitmap = createAdaptiveIconBitmap(bitmap)
                                    IconCompat.createWithAdaptiveBitmap(adaptiveBitmap)
                                } else {
                                    IconCompat.createWithBitmap(bitmap)
                                }
                            } else {
                                IconCompat.createWithResource(this@MainActivity, R.mipmap.ic_launcher)
                            }
                        } else {
                            IconCompat.createWithResource(this@MainActivity, R.mipmap.ic_launcher)
                        }

                        val shortcut = ShortcutInfoCompat.Builder(this@MainActivity, "station_$id")
                            .setShortLabel(name)
                            .setLongLabel(name)
                            .setIcon(icon)
                            .setIntent(launchIntent)
                            .build()

                        val success = ShortcutManagerCompat.requestPinShortcut(this@MainActivity, shortcut, null)
                        result.success(success)
                    }
                    "getInitialStationId" -> {
                        val stationId = intent?.getStringExtra("station_id")
                        intent?.removeExtra("station_id")
                        result.success(stationId)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun createAdaptiveIconBitmap(source: Bitmap): Bitmap {
        val size = Math.max(source.width, source.height)
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = android.graphics.Canvas(output)

        val cornerColor = source.getPixel(0, 0)
        canvas.drawColor(cornerColor)

        val scaleFactor = 0.70f
        val scaledWidth = (source.width * scaleFactor).toInt()
        val scaledHeight = (source.height * scaleFactor).toInt()

        val left = (size - scaledWidth) / 2f
        val top = (size - scaledHeight) / 2f
        val rect = android.graphics.RectF(left, top, left + scaledWidth, top + scaledHeight)

        val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG or android.graphics.Paint.FILTER_BITMAP_FLAG)
        canvas.drawBitmap(source, null, rect, paint)

        return output
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



