package com.azmain.islamic_app

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val feedbackChannel = "com.azmain.islamic_app/feedback"
    private var toneGenerator: ToneGenerator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            feedbackChannel,
        ).setMethodCallHandler { call, result ->
            if (call.method != "playFeedback") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val sound = call.argument<Boolean>("sound") ?: false
            val vibration = call.argument<Boolean>("vibration") ?: false
            val strong = call.argument<Boolean>("strong") ?: false

            try {
                if (sound) playTasbihSound()
                if (vibration) vibrateForTasbih(strong)
                result.success(true)
            } catch (error: Exception) {
                result.error(
                    "FEEDBACK_FAILED",
                    error.message ?: "Could not play Tasbih feedback",
                    null,
                )
            }
        }
    }

    private fun playTasbihSound() {
        val generator = toneGenerator ?: ToneGenerator(AudioManager.STREAM_MUSIC, 80)
            .also { toneGenerator = it }

        // Use the media stream so the phone's normal media volume controls it.
        generator.startTone(ToneGenerator.TONE_PROP_BEEP, 95)
    }

    @Suppress("DEPRECATION")
    private fun vibrateForTasbih(strong: Boolean) {
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator ?: return
        if (!vibrator.hasVibrator()) return

        val durationMs = if (strong) 120L else 42L
        val amplitude = if (strong) 220 else 125

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(
                VibrationEffect.createOneShot(
                    durationMs,
                    amplitude,
                ),
            )
        } else {
            vibrator.vibrate(durationMs)
        }
    }

    override fun onDestroy() {
        toneGenerator?.release()
        toneGenerator = null
        super.onDestroy()
    }
}
