package com.mrunit.etherly

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.mediarouter.media.MediaControlIntent
import androidx.mediarouter.media.MediaRouteSelector
import androidx.mediarouter.media.MediaRouter
import com.google.android.gms.common.images.WebImage
import com.google.android.gms.cast.CastDevice
import com.google.android.gms.cast.CastMediaControlIntent
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/// Helper class that manages Android Google Cast framework interactions and platform channels.
class ChromeCast(private val context: Context) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        private const val CONTROL_CHANNEL = "com.mrunit.etherly/cast_control"
        private const val EVENTS_CHANNEL = "com.mrunit.etherly/cast_events"
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private var mediaRouter: MediaRouter? = null
    private var mediaRouteSelector: MediaRouteSelector? = null
    private var castContext: CastContext? = null
    private var currentSession: CastSession? = null

    private val discoveredRoutes = mutableListOf<MediaRouter.RouteInfo>()

    private val mediaRouterCallback = object : MediaRouter.Callback() {
        override fun onRouteAdded(router: MediaRouter, route: MediaRouter.RouteInfo) {
            updateDiscoveredDevices()
        }

        override fun onRouteRemoved(router: MediaRouter, route: MediaRouter.RouteInfo) {
            updateDiscoveredDevices()
        }

        override fun onRouteChanged(router: MediaRouter, route: MediaRouter.RouteInfo) {
            updateDiscoveredDevices()
        }
    }

    private val sessionManagerListener = object : SessionManagerListener<CastSession> {
        override fun onSessionStarted(session: CastSession, sessionId: String) {
            onSessionConnected(session)
        }

        override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) {
            onSessionConnected(session)
        }

        override fun onSessionEnding(session: CastSession) {
            // Preparing for disconnection
        }

        override fun onSessionEnded(session: CastSession, error: Int) {
            onSessionDisconnected()
        }

        override fun onSessionStartFailed(session: CastSession, error: Int) {
            onSessionDisconnected()
        }

        override fun onSessionResumeFailed(session: CastSession, error: Int) {
            onSessionDisconnected()
        }

        override fun onSessionStarting(session: CastSession) {}
        override fun onSessionResuming(session: CastSession, sessionId: String) {}
        override fun onSessionSuspended(session: CastSession, reason: Int) {}
    }

    private val remoteMediaClientCallback = object : RemoteMediaClient.Callback() {
        override fun onStatusUpdated() {
            sendPlaybackStateUpdate()
        }

        override fun onMetadataUpdated() {
            sendPlaybackStateUpdate()
        }
    }

    /// Registers the platform channels with Flutter binary messenger.
    fun register(messenger: BinaryMessenger) {
        methodChannel = MethodChannel(messenger, CONTROL_CHANNEL).apply {
            setMethodCallHandler(this@ChromeCast)
        }
        eventChannel = EventChannel(messenger, EVENTS_CHANNEL).apply {
            setStreamHandler(this@ChromeCast)
        }
    }

    /// Unregisters and cleans up channels.
    fun unregister() {
        stopDiscovery()
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> handleInit(call, result)
            "startDiscovery" -> {
                startDiscovery()
                result.success(true)
            }
            "stopDiscovery" -> {
                stopDiscovery()
                result.success(true)
            }
            "connect" -> handleConnect(call, result)
            "disconnect" -> handleDisconnect(result)
            "loadMedia" -> handleLoadMedia(call, result)
            "play" -> handlePlay(result)
            "pause" -> handlePause(result)
            "stop" -> handleStop(result)
            "setVolume" -> handleSetVolume(call, result)
            "getVolume" -> handleGetVolume(result)
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        updateDiscoveredDevices()
        sendSessionStateUpdate()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun handleInit(call: MethodCall, result: MethodChannel.Result) {
        try {
            val appId = call.argument<String>("appId")
            if (!appId.isNullOrEmpty()) {
                CastOptionsProvider.customReceiverAppId = appId
            }

            castContext = CastContext.getSharedInstance(context)
            castContext?.sessionManager?.addSessionManagerListener(sessionManagerListener, CastSession::class.java)

            mediaRouter = MediaRouter.getInstance(context)
            val receiverAppId = appId ?: CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID
            mediaRouteSelector = MediaRouteSelector.Builder()
                .addControlCategory(CastMediaControlIntent.categoryForCast(receiverAppId))
                .build()

            currentSession = castContext?.sessionManager?.currentCastSession
            currentSession?.remoteMediaClient?.registerCallback(remoteMediaClientCallback)

            startDiscovery()
            result.success(true)
        } catch (e: Exception) {
            result.error("INIT_FAILED", e.localizedMessage, null)
        }
    }

    private fun startDiscovery() {
        val router = mediaRouter ?: return
        val selector = mediaRouteSelector ?: return
        mainHandler.post {
            router.removeCallback(mediaRouterCallback)
            router.addCallback(selector, mediaRouterCallback, MediaRouter.CALLBACK_FLAG_REQUEST_DISCOVERY)
            updateDiscoveredDevices()
        }
    }

    private fun stopDiscovery() {
        val router = mediaRouter ?: return
        mainHandler.post {
            router.removeCallback(mediaRouterCallback)
        }
    }

    private fun updateDiscoveredDevices() {
        val router = mediaRouter ?: return
        val selector = mediaRouteSelector ?: return

        discoveredRoutes.clear()
        for (route in router.routes) {
            if (!route.isDefault && route.matchesSelector(selector)) {
                discoveredRoutes.add(route)
            }
        }

        val deviceList = discoveredRoutes.map { route ->
            val castDevice = CastDevice.getFromBundle(route.extras)
            mapOf(
                "id" to route.id,
                "name" to route.name,
                "model" to (castDevice?.modelName ?: route.description)
            )
        }

        emitEvent(mapOf(
            "event" to "devicesChanged",
            "devices" to deviceList
        ))
    }

    private fun handleConnect(call: MethodCall, result: MethodChannel.Result) {
        val targetId = call.argument<String>("id")
        if (targetId.isNullOrEmpty()) {
            result.error("INVALID_ARGS", "Target device id required", null)
            return
        }

        val route = discoveredRoutes.find { it.id == targetId }
        if (route != null) {
            mediaRouter?.selectRoute(route)
            result.success(true)
        } else {
            result.error("DEVICE_NOT_FOUND", "No matching Cast route found for id: $targetId", null)
        }
    }

    private fun handleDisconnect(result: MethodChannel.Result) {
        try {
            castContext?.sessionManager?.endCurrentSession(true)
            onSessionDisconnected()
            result.success(true)
        } catch (e: Exception) {
            result.error("DISCONNECT_FAILED", e.localizedMessage, null)
        }
    }

    private fun handleLoadMedia(call: MethodCall, result: MethodChannel.Result) {
        val client = currentSession?.remoteMediaClient
        if (client == null) {
            result.error("NO_SESSION", "No active Cast session", null)
            return
        }

        val urlStr = call.argument<String>("url")
        if (urlStr.isNullOrEmpty()) {
            result.error("INVALID_ARGS", "Media URL required", null)
            return
        }

        val title = call.argument<String>("title") ?: "Etherly Radio"
        val subtitle = call.argument<String>("subtitle") ?: ""
        val imageUrlStr = call.argument<String>("imageUrl")
        val contentType = call.argument<String>("contentType") ?: "audio/mpeg"

        val metadata = MediaMetadata(MediaMetadata.MEDIA_TYPE_MUSIC_TRACK).apply {
            putString(MediaMetadata.KEY_TITLE, title)
            if (subtitle.isNotEmpty()) {
                putString(MediaMetadata.KEY_ARTIST, subtitle)
            }
            if (!imageUrlStr.isNullOrEmpty()) {
                addImage(WebImage(Uri.parse(imageUrlStr)))
            }
        }

        val mediaInfo = MediaInfo.Builder(urlStr)
            .setStreamType(MediaInfo.STREAM_TYPE_LIVE)
            .setContentType(contentType)
            .setMetadata(metadata)
            .build()

        client.load(mediaInfo, true, 0)
        sendPlaybackStateUpdate()
        result.success(true)
    }

    private fun handlePlay(result: MethodChannel.Result) {
        val client = currentSession?.remoteMediaClient
        if (client != null) {
            client.play()
            result.success(true)
        } else {
            result.error("NO_SESSION", "No active Cast session", null)
        }
    }

    private fun handlePause(result: MethodChannel.Result) {
        val client = currentSession?.remoteMediaClient
        if (client != null) {
            client.pause()
            result.success(true)
        } else {
            result.error("NO_SESSION", "No active Cast session", null)
        }
    }

    private fun handleStop(result: MethodChannel.Result) {
        val client = currentSession?.remoteMediaClient
        if (client != null) {
            client.stop()
            result.success(true)
        } else {
            result.error("NO_SESSION", "No active Cast session", null)
        }
    }

    private fun handleSetVolume(call: MethodCall, result: MethodChannel.Result) {
        val session = currentSession
        if (session == null) {
            result.error("NO_SESSION", "No active Cast session", null)
            return
        }

        val volume = call.argument<Double>("volume") ?: 1.0
        try {
            session.volume = volume
            result.success(true)
        } catch (e: Exception) {
            result.error("SET_VOLUME_FAILED", e.localizedMessage, null)
        }
    }

    private fun handleGetVolume(result: MethodChannel.Result) {
        val session = currentSession
        if (session != null) {
            result.success(session.volume)
        } else {
            result.error("NO_SESSION", "No active Cast session", null)
        }
    }

    private fun onSessionConnected(session: CastSession) {
        currentSession = session
        session.remoteMediaClient?.registerCallback(remoteMediaClientCallback)

        val castDevice = session.castDevice
        sendSessionStateUpdate()
        sendPlaybackStateUpdate()
        sendVolumeUpdate()
    }

    private fun onSessionDisconnected() {
        currentSession?.remoteMediaClient?.unregisterCallback(remoteMediaClientCallback)
        currentSession = null
        sendSessionStateUpdate()
        sendPlaybackStateUpdate()
    }

    private fun sendSessionStateUpdate() {
        val session = currentSession
        val connected = session != null && session.isConnected
        val device = session?.castDevice
        val route = mediaRouter?.selectedRoute

        emitEvent(mapOf(
            "event" to "sessionState",
            "connected" to connected,
            "deviceId" to (route?.id ?: device?.deviceId ?: ""),
            "deviceName" to (device?.friendlyName ?: route?.name ?: "")
        ))
    }


    private fun sendPlaybackStateUpdate() {
        val client = currentSession?.remoteMediaClient
        val isPlaying = client?.isPlaying ?: false
        val isBuffering = client?.isBuffering ?: false

        emitEvent(mapOf(
            "event" to "playbackState",
            "isPlaying" to isPlaying,
            "isLoading" to isBuffering
        ))
    }

    private fun sendVolumeUpdate() {
        val session = currentSession
        val volume = session?.volume ?: 1.0

        emitEvent(mapOf(
            "event" to "volumeChanged",
            "volume" to volume
        ))
    }

    private fun emitEvent(event: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(event)
        }
    }
}
