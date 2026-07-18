package com.safeher.app

import android.content.Intent
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "safeher/volume_control"
    private val EVENT_CHANNEL = "safeher/volume_events"
    private val WIDGET_CHANNEL = "safeher/widget"

    private var isArmed = false
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // -----------------------------
        // Widget Channel
        // -----------------------------
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIDGET_CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                else -> result.notImplemented()
            }
        }

        // If app was opened from widget
        if (intent?.action == "SAFEHER_WIDGET_SOS") {

            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                WIDGET_CHANNEL
            ).invokeMethod(
                "triggerSos",
                null
            )
        }

        // -----------------------------
        // Volume Method Channel
        // -----------------------------
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "setArmed" -> {

                    isArmed =
                        call.argument<Boolean>("armed") ?: false

                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        // -----------------------------
        // Volume Event Channel
        // -----------------------------
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {

            override fun onListen(
                arguments: Any?,
                sink: EventChannel.EventSink?
            ) {
                eventSink = sink
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    // Called when app is already open and widget is pressed again
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        setIntent(intent)

        if (intent.action == "SAFEHER_WIDGET_SOS") {

            MethodChannel(
                flutterEngine!!.dartExecutor.binaryMessenger,
                WIDGET_CHANNEL
            ).invokeMethod(
                "triggerSos",
                null
            )
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {

        val isVolumeKey =
            event.keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
            event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN

        if (
            isArmed &&
            isVolumeKey &&
            event.action == KeyEvent.ACTION_DOWN
        ) {

            eventSink?.success(
                if (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP)
                    "up"
                else
                    "down"
            )

            return true
        }

        return super.dispatchKeyEvent(event)
    }
}