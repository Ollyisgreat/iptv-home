package com.tvhome.launcher

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.util.Base64
import android.view.KeyEvent
import android.view.ViewGroup
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class MainActivity : Activity() {

    private lateinit var web: WebView
    private lateinit var video: VideoPlayer

    @SuppressLint("SetJavaScriptEnabled", "AddJavascriptInterface")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WebView.setWebContentsDebuggingEnabled(true)

        // Video sits underneath a transparent WebView, so the player UI is plain HTML
        val root = FrameLayout(this)
        root.setBackgroundColor(Color.BLACK)
        video = VideoPlayer(this) { js(it) }
        root.addView(video.view, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))

        web = WebView(this)
        web.setBackgroundColor(Color.TRANSPARENT)
        with(web.settings) {
            javaScriptEnabled = true
            domStorageEnabled = true          // localStorage keeps your dock + settings
            databaseEnabled = true
            allowFileAccess = true
            @Suppress("DEPRECATION")
            allowFileAccessFromFileURLs = true
            @Suppress("DEPRECATION")
            allowUniversalAccessFromFileURLs = true // lets the home screen call your Jellyfin server
            mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
            mediaPlaybackRequiresUserGesture = false
            // Fit the page to the TV exactly: no zoom, ignore system text-size setting
            useWideViewPort = false
            loadWithOverviewMode = false
            setSupportZoom(false)
            builtInZoomControls = false
            displayZoomControls = false
            textZoom = 100
        }
        web.setInitialScale(0)
        web.isFocusable = true
        web.isFocusableInTouchMode = true
        web.webViewClient = WebViewClient()
        web.webChromeClient = WebChromeClient()
        web.addJavascriptInterface(Bridge(this), "Launcher")
        web.addJavascriptInterface(video, "NativePlayer")
        root.addView(web, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        setContentView(root)
        web.loadUrl(HOME)
        web.requestFocus()
    }

    override fun onResume() {
        super.onResume()
        js("window.tvResume&&window.tvResume()")
    }

    override fun onStop() {
        super.onStop()
        video.onBackground()
    }

    override fun onDestroy() {
        video.release()
        web.destroy()
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        // Re-launching the app (e.g. the Home button remapped to TV Home) always lands on Explore
        if (web.url != HOME) web.loadUrl(HOME)
        else js("window.tvHome&&window.tvHome()")
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (web.url == HOME) {
            mediaKey(event.keyCode)?.let { name ->
                if (event.action == KeyEvent.ACTION_DOWN) js("window.tvKey&&window.tvKey('$name',${event.repeatCount})")
                return true
            }
        }
        when (event.keyCode) {
            KeyEvent.KEYCODE_MENU -> {
                if (event.action == KeyEvent.ACTION_UP) js("window.tvMenu&&window.tvMenu(1)")
                return true
            }
            KeyEvent.KEYCODE_BACK -> {
                if (event.action == KeyEvent.ACTION_UP) {
                    if (web.url != HOME && web.canGoBack()) web.goBack()
                    else if (web.url != HOME) web.loadUrl(HOME)
                    else js("window.tvBack&&window.tvBack()")
                }
                return true
            }
        }
        return super.dispatchKeyEvent(event)
    }

    private fun mediaKey(code: Int): String? = when (code) {
        KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE, KeyEvent.KEYCODE_HEADSETHOOK -> "playpause"
        KeyEvent.KEYCODE_MEDIA_PLAY -> "play"
        KeyEvent.KEYCODE_MEDIA_PAUSE -> "pause"
        KeyEvent.KEYCODE_MEDIA_STOP -> "stop"
        KeyEvent.KEYCODE_MEDIA_FAST_FORWARD -> "ff"
        KeyEvent.KEYCODE_MEDIA_REWIND -> "rw"
        KeyEvent.KEYCODE_MEDIA_NEXT -> "next"
        KeyEvent.KEYCODE_MEDIA_PREVIOUS -> "prev"
        KeyEvent.KEYCODE_CHANNEL_UP, KeyEvent.KEYCODE_PAGE_UP -> "chup"
        KeyEvent.KEYCODE_CHANNEL_DOWN, KeyEvent.KEYCODE_PAGE_DOWN -> "chdown"
        KeyEvent.KEYCODE_GUIDE -> "guide"
        KeyEvent.KEYCODE_INFO -> "info"
        else -> null
    }

    private fun js(code: String) {
        if (::web.isInitialized) web.post { web.evaluateJavascript(code, null) }
    }

    companion object {
        const val HOME = "file:///android_asset/index.html"
    }
}

/** Exposed to the home screen as window.Launcher */
class Bridge(private val act: Activity) {
    private val pm get() = act.packageManager

    @JavascriptInterface
    fun getApps(): String {
        val seen = LinkedHashMap<String, String>()
        for (cat in listOf(Intent.CATEGORY_LEANBACK_LAUNCHER, Intent.CATEGORY_LAUNCHER)) {
            val query = Intent(Intent.ACTION_MAIN).addCategory(cat)
            @Suppress("DEPRECATION")
            for (ri in pm.queryIntentActivities(query, 0)) {
                val pkg = ri.activityInfo.packageName
                if (pkg == act.packageName || seen.containsKey(pkg)) continue
                seen[pkg] = ri.loadLabel(pm).toString()
            }
        }
        val arr = JSONArray()
        seen.entries.sortedBy { it.value.lowercase() }.forEach {
            arr.put(JSONObject().put("pkg", it.key).put("label", it.value))
        }
        return arr.toString()
    }

    /** The wide TV banner an app ships with (perfect for the home bar), or "" if it has none. */
    @JavascriptInterface
    fun getBanner(pkg: String): String = try {
        val ai = pm.getApplicationInfo(pkg, 0)
        val d: Drawable? = pm.getApplicationBanner(ai) ?: run {
            val launch = pm.getLeanbackLaunchIntentForPackage(pkg)
            launch?.let { pm.getActivityBanner(it) }
        }
        if (d == null) "" else toDataUrl(d, 400)
    } catch (e: Exception) { "" }

    @JavascriptInterface
    fun getIcon(pkg: String): String = try {
        toDataUrl(pm.getApplicationIcon(pkg), 128)
    } catch (e: Exception) { "" }

    @JavascriptInterface
    fun launch(pkg: String): Boolean {
        val intent = (pm.getLeanbackLaunchIntentForPackage(pkg) ?: pm.getLaunchIntentForPackage(pkg))
            ?: return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        act.runOnUiThread { try { act.startActivity(intent) } catch (_: Exception) {} }
        return true
    }

    /**
     * Open another app at a specific page (e.g. a Netflix title). Tries the exact screen first,
     * then any activity in that app that accepts the link. Returns false if nothing took it.
     */
    @JavascriptInterface
    fun openLink(pkg: String, uri: String, component: String, extrasJson: String): Boolean {
        val extras = try { JSONObject(extrasJson.ifBlank { "{}" }) } catch (e: Exception) { JSONObject() }
        fun make(withComponent: Boolean) = Intent(Intent.ACTION_VIEW, Uri.parse(uri)).apply {
            if (withComponent && component.isNotBlank()) setClassName(pkg, component) else setPackage(pkg)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            extras.keys().forEach { k -> putExtra(k, extras.optString(k)) }
        }
        for (intent in listOf(make(true), make(false))) {
            @Suppress("DEPRECATION")
            if (pm.queryIntentActivities(intent, 0).isEmpty()) continue
            var ok = false
            val done = CountDownLatch(1)
            act.runOnUiThread {
                try { act.startActivity(intent); ok = true } catch (_: Exception) {}
                done.countDown()
            }
            done.await(2, TimeUnit.SECONDS)
            if (ok) return true
        }
        return false
    }

    @JavascriptInterface
    fun openSystemSettings() {
        act.runOnUiThread {
            try { act.startActivity(Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) } catch (_: Exception) {}
        }
    }

    private fun toDataUrl(d: Drawable, maxW: Int): String {
        var w = if (d.intrinsicWidth > 0) d.intrinsicWidth else maxW
        var h = if (d.intrinsicHeight > 0) d.intrinsicHeight else maxW
        if (w > maxW) { h = h * maxW / w; w = maxW }
        val bmp = Bitmap.createBitmap(w, h.coerceAtLeast(1), Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        d.setBounds(0, 0, w, h)
        d.draw(c)
        val out = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.PNG, 100, out)
        bmp.recycle()
        return "data:image/png;base64," + Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
    }
}
