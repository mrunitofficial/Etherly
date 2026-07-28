package com.mrunit.etherly

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.os.Build
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class CreateShortcut(private val context: Context) {
    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result, currentIntent: Intent?) {
        when (call.method) {
            "isPinShortcutSupported" -> {
                result.success(ShortcutManagerCompat.isRequestPinShortcutSupported(context))
            }
            "pinStationShortcut" -> {
                val id = call.argument<String>("id")
                val name = call.argument<String>("name")
                val iconBytes = call.argument<ByteArray>("iconBytes")

                if (id.isNullOrEmpty() || name.isNullOrEmpty()) {
                    result.error("INVALID_ARGS", "Station ID and name are required", null)
                    return
                }

                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    putExtra("station_id", id)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                }

                val icon = if (iconBytes != null && iconBytes.isNotEmpty()) {
                    val bitmap = BitmapFactory.decodeByteArray(iconBytes, 0, iconBytes.size)
                    if (bitmap != null) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val adaptiveBitmap = createAdaptiveIconBitmap(bitmap)
                            IconCompat.createWithAdaptiveBitmap(adaptiveBitmap)
                        } else {
                            IconCompat.createWithBitmap(bitmap)
                        }
                    } else {
                        IconCompat.createWithResource(context, R.mipmap.ic_launcher)
                    }
                } else {
                    IconCompat.createWithResource(context, R.mipmap.ic_launcher)
                }

                val shortcut = ShortcutInfoCompat.Builder(context, "station_$id")
                    .setShortLabel(name)
                    .setLongLabel(name)
                    .setIcon(icon)
                    .setIntent(launchIntent)
                    .build()

                val success = ShortcutManagerCompat.requestPinShortcut(context, shortcut, null)
                result.success(success)
            }
            "getInitialStationId" -> {
                val stationId = currentIntent?.getStringExtra("station_id")
                currentIntent?.removeExtra("station_id")
                result.success(stationId)
            }
            else -> result.notImplemented()
        }
    }

    private fun createAdaptiveIconBitmap(source: Bitmap): Bitmap {
        val size = Math.max(source.width, source.height)
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)

        val cornerColor = source.getPixel(0, 0)
        canvas.drawColor(cornerColor)

        val scaleFactor = 0.70f
        val scaledWidth = (source.width * scaleFactor).toInt()
        val scaledHeight = (source.height * scaleFactor).toInt()

        val left = (size - scaledWidth) / 2f
        val top = (size - scaledHeight) / 2f
        val rect = RectF(left, top, left + scaledWidth, top + scaledHeight)

        val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
        canvas.drawBitmap(source, null, rect, paint)

        return output
    }
}
