package com.mrunit.etherly

import android.content.Context
import com.google.android.gms.cast.CastMediaControlIntent
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider
import com.google.android.gms.cast.framework.media.CastMediaOptions

/// Provides Google Cast framework options and receiver configuration.
class CastOptionsProvider : OptionsProvider {
    companion object {
        /// Default receiver ID or custom receiver ID if overridden.
        var customReceiverAppId: String? = null
    }

    override fun getCastOptions(context: Context): CastOptions {
        val appId = customReceiverAppId ?: CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID

        val mediaOptions = CastMediaOptions.Builder()
            .setNotificationOptions(null)
            .setMediaSessionEnabled(false)
            .build()

        return CastOptions.Builder()
            .setReceiverApplicationId(appId)
            .setCastMediaOptions(mediaOptions)
            .setStopReceiverApplicationWhenEndingSession(true)
            .build()
    }

    override fun getAdditionalSessionProviders(context: Context): List<SessionProvider>? {
        return null
    }
}
