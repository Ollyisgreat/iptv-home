package com.tvhome.launcher

import android.app.Activity
import android.graphics.Color
import android.media.MediaCodecList
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.webkit.JavascriptInterface
import android.widget.FrameLayout
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.common.VideoSize
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.extractor.DefaultExtractorsFactory
import androidx.media3.extractor.ts.DefaultTsPayloadReaderFactory
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.CaptionStyleCompat
import androidx.media3.ui.PlayerView
import androidx.media3.ui.SubtitleView
import org.json.JSONArray
import org.json.JSONObject

/**
 * ExoPlayer drawn underneath the (transparent) home-screen WebView, so all the
 * player UI stays in HTML. Exposed to the page as window.NativePlayer.
 * Every player call is posted to the main thread; state is read from snapshots.
 */
@OptIn(UnstableApi::class)
class VideoPlayer(private val act: Activity, private val js: (String) -> Unit) : Player.Listener {

    private val main = Handler(Looper.getMainLooper())

    val view: PlayerView = PlayerView(act).apply {
        useController = false
        setShutterBackgroundColor(Color.BLACK)
        setKeepContentOnPlayerReset(false)
        isFocusable = false
        descendantFocusability = ViewGroup.FOCUS_BLOCK_DESCENDANTS
        visibility = View.GONE
        subtitleView?.apply {
            setApplyEmbeddedStyles(true)
            setFractionalTextSize(SubtitleView.DEFAULT_TEXT_SIZE_FRACTION * 1.15f)
            setStyle(CaptionStyleCompat(Color.WHITE, Color.TRANSPARENT, Color.TRANSPARENT,
                CaptionStyleCompat.EDGE_TYPE_OUTLINE, Color.BLACK, null))
        }
    }

    private val http = DefaultHttpDataSource.Factory()
        .setAllowCrossProtocolRedirects(true)
        .setConnectTimeoutMs(15_000)
        .setReadTimeoutMs(25_000)

    private var player: ExoPlayer? = null
    private var live = false
    private var retries = 0
    private var reconnecting = false
    private var generation = 0

    @Volatile private var stateJson = "{\"st\":1}"
    @Volatile private var tracksJson = EMPTY_TRACKS

    private fun ensurePlayer(): ExoPlayer {
        player?.let { return it }
        val extractors = DefaultExtractorsFactory()
            .setTsExtractorFlags(DefaultTsPayloadReaderFactory.FLAG_ALLOW_NON_IDR_KEYFRAMES or
                DefaultTsPayloadReaderFactory.FLAG_DETECT_ACCESS_UNITS)
            .setConstantBitrateSeekingEnabled(true)
        val sources = DefaultMediaSourceFactory(DefaultDataSource.Factory(act, http), extractors)
        val renderers = DefaultRenderersFactory(act).setEnableDecoderFallback(true)
        val load = DefaultLoadControl.Builder()
            .setBufferDurationsMs(15_000, 50_000, 1_500, 3_000)
            .build()
        val p = ExoPlayer.Builder(act, renderers)
            .setMediaSourceFactory(sources)
            .setLoadControl(load)
            .setAudioAttributes(AudioAttributes.Builder()
                .setUsage(C.USAGE_MEDIA)
                .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
                .build(), true)
            .setHandleAudioBecomingNoisy(true)
            .build()
        p.addListener(this)
        view.player = p
        player = p
        return p
    }

    /* ---------- called from JS ---------- */

    /** {url, live, startMs, ua, headers:{}, type:"hls"|"ts"|"", text:bool, subs:[{url,mime,lang,label}]} */
    @JavascriptInterface
    fun play(json: String) {
        val o = try { JSONObject(json) } catch (e: Exception) { return }
        main.post { doPlay(o) }
    }

    private fun doPlay(o: JSONObject) {
        val p = ensurePlayer()
        generation++
        live = o.optBoolean("live")
        retries = 0
        reconnecting = false

        val headers = HashMap<String, String>()
        o.optJSONObject("headers")?.let { h -> h.keys().forEach { k -> headers[k] = h.optString(k) } }
        http.setUserAgent(o.optString("ua").ifBlank { DEFAULT_UA })
        http.setDefaultRequestProperties(headers)

        val b = MediaItem.Builder().setUri(o.getString("url"))
        when (o.optString("type")) {
            "hls" -> b.setMimeType(MimeTypes.APPLICATION_M3U8)
            "ts" -> b.setMimeType(MimeTypes.VIDEO_MP2T)
        }
        o.optJSONArray("subs")?.let { arr ->
            val subs = ArrayList<MediaItem.SubtitleConfiguration>()
            for (i in 0 until arr.length()) {
                val s = arr.getJSONObject(i)
                subs.add(MediaItem.SubtitleConfiguration.Builder(Uri.parse(s.getString("url")))
                    .setMimeType(s.optString("mime").ifBlank { MimeTypes.TEXT_VTT })
                    .setLanguage(s.optString("lang").ifBlank { null })
                    .setLabel(s.optString("label").ifBlank { null })
                    .build())
            }
            b.setSubtitleConfigurations(subs)
        }

        tracksJson = EMPTY_TRACKS
        p.trackSelectionParameters = p.trackSelectionParameters.buildUpon()
            .clearOverrides()
            .setTrackTypeDisabled(C.TRACK_TYPE_AUDIO, false)
            .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, !o.optBoolean("text"))
            .build()
        val start = o.optLong("startMs", 0)
        if (start > 0) p.setMediaItem(b.build(), start) else p.setMediaItem(b.build())
        p.setPlaybackSpeed(1f)
        p.playWhenReady = true
        p.prepare()
        view.visibility = View.VISIBLE
        stayAwake()
        main.removeCallbacks(ticker)
        main.post(ticker)
    }

    @JavascriptInterface
    fun stop() {
        main.post {
            generation++
            player?.run { stop(); clearMediaItems() }
            view.visibility = View.GONE
            reconnecting = false
            stayAwake()
            tracksJson = EMPTY_TRACKS
            snapshot()
        }
    }

    @JavascriptInterface fun pause() { main.post { player?.pause() } }
    @JavascriptInterface fun resume() { main.post { player?.let { if (it.playbackState == Player.STATE_IDLE) it.prepare(); it.play() } } }
    @JavascriptInterface fun toggle() { main.post { player?.let { if (it.playWhenReady) it.pause() else { if (it.playbackState == Player.STATE_IDLE) it.prepare(); it.play() } } } }
    @JavascriptInterface fun seekTo(ms: Long) { main.post { player?.seekTo(ms.coerceAtLeast(0)) } }
    @JavascriptInterface fun setSpeed(speed: Double) { main.post { player?.setPlaybackSpeed(speed.toFloat()) } }

    @JavascriptInterface fun state(): String = stateJson
    @JavascriptInterface fun tracks(): String = tracksJson

    /** g = index into the groups list reported by tracks(), t = track inside that group */
    @JavascriptInterface
    fun selectTrack(g: Int, t: Int) {
        main.post {
            val p = player ?: return@post
            val groups = p.currentTracks.groups
            if (g < 0 || g >= groups.size) return@post
            val grp = groups[g]
            if (t < 0 || t >= grp.length) return@post
            p.trackSelectionParameters = p.trackSelectionParameters.buildUpon()
                .setTrackTypeDisabled(grp.type, false)
                .setOverrideForType(TrackSelectionOverride(grp.mediaTrackGroup, t))
                .build()
        }
    }

    @JavascriptInterface
    fun disableText() {
        main.post {
            val p = player ?: return@post
            p.trackSelectionParameters = p.trackSelectionParameters.buildUpon()
                .clearOverridesOfType(C.TRACK_TYPE_TEXT)
                .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
                .build()
        }
    }

    /** Position the video in screen pixels (for the guide's preview window). w<=0 = full screen. */
    @JavascriptInterface
    fun setRect(l: Int, t: Int, w: Int, h: Int) {
        main.post {
            view.layoutParams = if (w <= 0 || h <= 0) {
                FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
            } else {
                FrameLayout.LayoutParams(w, h).apply { leftMargin = l; topMargin = t; gravity = Gravity.TOP or Gravity.START }
            }
        }
    }

    /**
     * Same as setRect but in 1/10000ths of the screen, so it doesn't depend on how the
     * WebView scales CSS pixels (that differs between Fire TV models).
     */
    @JavascriptInterface
    fun setRectFrac(l: Int, t: Int, w: Int, h: Int) {
        main.post {
            val parent = view.parent as? View
            val pw = parent?.width?.takeIf { it > 0 } ?: act.resources.displayMetrics.widthPixels
            val ph = parent?.height?.takeIf { it > 0 } ?: act.resources.displayMetrics.heightPixels
            view.layoutParams = if (w <= 0 || h <= 0) {
                FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
            } else {
                FrameLayout.LayoutParams(pw * w / 10000, ph * h / 10000).apply {
                    leftMargin = pw * l / 10000; topMargin = ph * t / 10000; gravity = Gravity.TOP or Gravity.START
                }
            }
            view.requestLayout()
        }
    }

    @JavascriptInterface
    fun setResize(mode: String) {
        main.post {
            view.resizeMode = when (mode) {
                "fill" -> AspectRatioFrameLayout.RESIZE_MODE_FILL
                "zoom" -> AspectRatioFrameLayout.RESIZE_MODE_ZOOM
                else -> AspectRatioFrameLayout.RESIZE_MODE_FIT
            }
        }
    }

    /** Decoder MIME types on this device, so Jellyfin knows what can be direct-played. */
    @JavascriptInterface
    fun codecs(): String {
        val set = sortedSetOf<String>()
        try {
            for (info in MediaCodecList(MediaCodecList.ALL_CODECS).codecInfos) {
                if (!info.isEncoder) info.supportedTypes.forEach { set.add(it.lowercase()) }
            }
        } catch (_: Exception) {}
        return JSONArray(set.toList()).toString()
    }

    /* ---------- lifecycle ---------- */

    fun onBackground() {
        val p = player ?: return
        if (p.playWhenReady) {
            p.pause()
            snapshot()
            emit("background")
        }
    }

    fun release() {
        main.removeCallbacksAndMessages(null)
        player?.release()
        player = null
    }

    /* ---------- Player.Listener ---------- */

    override fun onPlaybackStateChanged(playbackState: Int) {
        if (player == null) return
        if (playbackState == Player.STATE_READY) { retries = 0; reconnecting = false }
        if (playbackState == Player.STATE_ENDED) {
            // a live TS stream "ending" means the server dropped us: reconnect
            if (live && reconnect("ended")) return
            stayAwake(); snapshot(); emit("ended"); return
        }
        stayAwake()
        snapshot()
        emit("state")
    }

    override fun onIsPlayingChanged(isPlaying: Boolean) {
        stayAwake()
        snapshot()
        emit("state")
    }

    override fun onPlayWhenReadyChanged(playWhenReady: Boolean, reason: Int) { stayAwake() }

    override fun onVideoSizeChanged(videoSize: VideoSize) { snapshot() }

    override fun onRenderedFirstFrame() { emit("firstframe") }

    override fun onTracksChanged(tracks: Tracks) {
        tracksJson = buildTracks(tracks)
        emit("tracks")
    }

    override fun onPlayerError(error: PlaybackException) {
        if (live && reconnect(error.errorCodeName, error.errorCode == PlaybackException.ERROR_CODE_BEHIND_LIVE_WINDOW)) return
        reconnecting = false
        stayAwake()
        snapshot()
        emit("error", JSONObject()
            .put("code", error.errorCode)
            .put("name", error.errorCodeName)
            .put("msg", error.cause?.message ?: error.message ?: ""))
    }

    private fun reconnect(why: String, behindWindow: Boolean = false): Boolean {
        if (retries >= 6) return false
        retries++
        reconnecting = true
        stayAwake()
        val gen = generation
        emit("retry", JSONObject().put("n", retries).put("why", why))
        main.postDelayed({
            val p = player ?: return@postDelayed
            if (gen != generation) return@postDelayed
            if (behindWindow || p.playbackState == Player.STATE_ENDED) p.seekToDefaultPosition()
            p.prepare()
            p.play()
        }, 700L * retries)
        return true
    }

    /* ---------- helpers ---------- */

    /**
     * No screensaver while something is meant to be playing: covers buffering, channel changes and
     * reconnects too, not just the moments frames are moving. Pausing lets the screensaver come back.
     */
    private fun stayAwake() {
        val p = player
        val on = p != null && view.visibility == View.VISIBLE && p.playWhenReady &&
            (reconnecting || p.playbackState == Player.STATE_BUFFERING || p.playbackState == Player.STATE_READY)
        if (on) act.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        else act.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private val ticker = object : Runnable {
        override fun run() {
            snapshot()
            if (player != null && view.visibility == View.VISIBLE) main.postDelayed(this, 250)
        }
    }

    private fun snapshot() {
        val p = player ?: run { stateJson = "{\"st\":1}"; return }
        val dur = p.duration
        val vs = p.videoSize
        stateJson = JSONObject()
            .put("st", p.playbackState)
            .put("playing", p.isPlaying)
            .put("pwr", p.playWhenReady)
            .put("pos", p.currentPosition)
            .put("dur", if (dur == C.TIME_UNSET) -1 else dur)
            .put("buf", p.bufferedPosition)
            .put("live", p.isCurrentMediaItemLive)
            .put("seek", p.isCurrentMediaItemSeekable)
            .put("w", vs.width)
            .put("h", vs.height)
            .put("speed", p.playbackParameters.speed.toDouble())
            .put("err", p.playerError?.errorCodeName ?: "")
            .toString()
    }

    private fun buildTracks(t: Tracks): String {
        val audio = JSONArray()
        val text = JSONArray()
        val video = JSONArray()
        t.groups.forEachIndexed { gi, g ->
            val arr = when (g.type) {
                C.TRACK_TYPE_AUDIO -> audio
                C.TRACK_TYPE_TEXT -> text
                C.TRACK_TYPE_VIDEO -> video
                else -> null
            } ?: return@forEachIndexed
            for (ti in 0 until g.length) {
                val f = g.getTrackFormat(ti)
                arr.put(JSONObject()
                    .put("g", gi).put("t", ti)
                    .put("label", f.label ?: "")
                    .put("lang", f.language ?: "")
                    .put("mime", f.sampleMimeType ?: "")
                    .put("codecs", f.codecs ?: "")
                    .put("ch", f.channelCount)
                    .put("w", f.width).put("h", f.height)
                    .put("sel", g.isTrackSelected(ti))
                    .put("ok", g.isTrackSupported(ti)))
            }
        }
        return JSONObject().put("audio", audio).put("text", text).put("video", video).toString()
    }

    private fun emit(type: String, extra: JSONObject? = null) {
        val o = extra ?: JSONObject()
        o.put("type", type)
        js("window.__np&&window.__np(${JSONObject.quote(o.toString())})")
    }

    companion object {
        const val DEFAULT_UA = "TVHome/2.0 (Linux; Android) ExoPlayerLib"
        const val EMPTY_TRACKS = "{\"audio\":[],\"text\":[],\"video\":[]}"
    }
}
