package com.mrunit.etherly

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.mediarouter.media.MediaRouteSelector
import androidx.mediarouter.media.MediaRouter
import com.google.android.gms.cast.CastDevice
import com.google.android.gms.cast.CastMediaControlIntent
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import com.google.android.gms.common.images.WebImage
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/// Native Android helper handling Google Cast SDK discovery, session management, and platform channels.
class ChromeCast(private val context: Context) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val CONTROL_CHANNEL = "com.mrunit.etherly/cast_control"
        const val EVENTS_CHANNEL = "com.mrunit.etherly/cast_events"
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var castContext: CastContext? = null
    private var mediaRouter: MediaRouter? = null
    private var mediaRouteSelector: MediaRouteSelector? = null
    private var currentSession: CastSession? = null
    private var isListenerAdded = false
    private var lastDeviceListString = ""

    private val discoveredRoutes = mutableListOf<MediaRouter.RouteInfo>()
    private val mainHandler = Handler(Looper.getMainLooper())

    private val mediaRouterCallback = object : MediaRouter.Callback() {
        override fun onRouteAdded(router: MediaRouter, route: MediaRouter.RouteInfo) = updateDiscoveredDevices()
        override fun onRouteRemoved(router: MediaRouter, route: MediaRouter.RouteInfo) = updateDiscoveredDevices()
        override fun onRouteChanged(router: MediaRouter, route: MediaRouter.RouteInfo) = updateDiscoveredDevices()
    }

    private val sessionManagerListener = object : SessionManagerListener<CastSession> {
        override fun onSessionStarted(session: CastSession, sessionId: String) = onSessionConnected(session)
        override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) = onSessionConnected(session)
        override fun onSessionEnded(session: CastSession, error: Int) = onSessionDisconnected()
        override fun onSessionStartFailed(session: CastSession, error: Int) = onSessionDisconnected()
        override fun onSessionResumeFailed(session: CastSession, error: Int) = onSessionDisconnected()
        override fun onSessionStarting(session: CastSession) {}
        override fun onSessionResuming(session: CastSession, sessionId: String) {}
        override fun onSessionEnding(session: CastSession) {}
        override fun onSessionSuspended(session: CastSession, reason: Int) {}
    }

    private val remoteMediaClientCallback = object : RemoteMediaClient.Callback() {
        override fun onStatusUpdated() = sendPlaybackStateUpdate()
        override fun onMetadataUpdated() = sendPlaybackStateUpdate()
    }

    /// Registers platform channels with Flutter binary messenger.
    fun register(messenger: BinaryMessenger) {
        methodChannel = MethodChannel(messenger, CONTROL_CHANNEL).apply { setMethodCallHandler(this@ChromeCast) }
        eventChannel = EventChannel(messenger, EVENTS_CHANNEL).apply { setStreamHandler(this@ChromeCast) }
    }

    /// Unregisters channels and cleans up native session listeners to prevent leaks.
    fun unregister() {
        stopDiscovery()
        currentSession?.remoteMediaClient?.unregisterCallback(remoteMediaClientCallback)
        if (isListenerAdded) {
            castContext?.sessionManager?.removeSessionManagerListener(sessionManagerListener, CastSession::class.java)
            isListenerAdded = false
        }
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
        castContext = null
        mediaRouter = null
        mediaRouteSelector = null
        currentSession = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> handleInit(call, result)
            "startDiscovery" -> { startDiscovery(); result.success(true) }
            "stopDiscovery" -> { stopDiscovery(); result.success(true) }
            "connect" -> handleConnect(call, result)
            "disconnect" -> handleDisconnect(result)
            "loadMedia" -> handleLoadMedia(call, result)
            "play" -> handleMediaAction(result) { it.play() }
            "pause" -> handleMediaAction(result) { it.pause() }
            "stop" -> handleMediaAction(result) { it.stop() }
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

    override fun onCancel(arguments: Any?) { eventSink = null }

    private fun handleInit(call: MethodCall, result: MethodChannel.Result) {
        try {
            val appId = call.argument<String>("appId")
            if (!appId.isNullOrEmpty()) CastOptionsProvider.customReceiverAppId = appId

            castContext = CastContext.getSharedInstance(context)
            if (!isListenerAdded) {
                castContext?.sessionManager?.addSessionManagerListener(sessionManagerListener, CastSession::class.java)
                isListenerAdded = true
            }

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
        mainHandler.post { router.removeCallback(mediaRouterCallback) }
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

        val deviceString = deviceList.toString()
        if (deviceString != lastDeviceListString) {
            lastDeviceListString = deviceString
            emitEvent(mapOf("event" to "devicesChanged", "devices" to deviceList))
        }
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
        val client = currentSession?.remoteMediaClient ?: run {
            result.error("NO_SESSION", "No active Cast session", null)
            return
        }

        val urlStr = call.argument<String>("url") ?: run {
            result.error("INVALID_ARGS", "Media URL required", null)
            return
        }

        val title = call.argument<String>("title") ?: "Etherly Radio"
        val subtitle = call.argument<String>("subtitle") ?: ""
        val imageUrlStr = call.argument<String>("imageUrl")
        val contentType = call.argument<String>("contentType") ?: "audio/mpeg"

        val metadata = MediaMetadata(MediaMetadata.MEDIA_TYPE_MUSIC_TRACK).apply {
            putString(MediaMetadata.KEY_TITLE, title)
            if (subtitle.isNotEmpty()) putString(MediaMetadata.KEY_ARTIST, subtitle)
            if (!imageUrlStr.isNullOrEmpty()) addImage(WebImage(Uri.parse(imageUrlStr)))
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

    private inline fun handleMediaAction(result: MethodChannel.Result, action: (RemoteMediaClient) -> Unit) {
        val client = currentSession?.remoteMediaClient
        if (client != null) {
            action(client)
            result.success(true)
        } else {
            result.error("NO_SESSION", "No active Cast session", null)
        }
    }

    private fun handleSetVolume(call: MethodCall, result: MethodChannel.Result) {
        val session = currentSession ?: run {
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
        if (session != null) result.success(session.volume)
        else result.error("NO_SESSION", "No active Cast session", null)
    }

    private fun onSessionConnected(session: CastSession) {
        currentSession = session
        session.remoteMediaClient?.registerCallback(remoteMediaClientCallback)
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
        emitEvent(mapOf(
            "event" to "playbackState",
            "isPlaying" to (client?.isPlaying ?: false),
            "isLoading" to (client?.isBuffering ?: false)
        ))
    }

    private fun sendVolumeUpdate() {
        emitEvent(mapOf(
            "event" to "volumeChanged",
            "volume" to (currentSession?.volume ?: 1.0)
        ))
    }

    private fun emitEvent(event: Map<String, Any?>) {
        mainHandler.post { eventSink?.success(event) }
    }
}
