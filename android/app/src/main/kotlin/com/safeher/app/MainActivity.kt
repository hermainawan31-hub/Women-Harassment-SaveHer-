package com.safeher.app

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "safeher/volume_control"
    private val EVENT_CHANNEL = "safeher/volume_events"

    // Only intercept volume keys while the Flutter side has explicitly
    // armed SOS confirmation — otherwise volume buttons behave normally.
    private var isArmed = false
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Flutter tells native code when to start/stop intercepting volume keys.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setArmed" -> {
                        isArmed = call.argument<Boolean>("armed") ?: false
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Native code streams each volume press to Flutter while armed.
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val isVolumeKey = event.keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
                event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN

        if (isArmed && isVolumeKey && event.action == KeyEvent.ACTION_DOWN) {
            eventSink?.success(
                if (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP) "up" else "down"
            )
            // Swallow the event: prevents the device's actual volume from
            // changing and stops the on-screen volume slider from appearing,
            // so pressing volume to confirm SOS stays discreet.
            return true
        }

        return super.dispatchKeyEvent(event)
    }
}