package com.kknutrivet.shop

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val hapticsChannel = "com.kknutrivet.shop/haptics"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, hapticsChannel)
            .setMethodCallHandler { call, result ->
                try {
                    performHaptic(call.method)
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            }
    }

    private fun vibrator(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)
                ?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    /**
     * Uses the device vibrator directly so taps are felt even on OEM devices
     * where View.performHapticFeedback(CLOCK_TICK / VIRTUAL_KEY) is a no-op.
     */
    private fun performHaptic(type: String) {
        val v = vibrator() ?: return
        if (!v.hasVibrator()) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val effect = when (type) {
                "selection" -> VibrationEffect.EFFECT_TICK
                "light" -> VibrationEffect.EFFECT_CLICK
                "medium" -> VibrationEffect.EFFECT_CLICK
                "heavy" -> VibrationEffect.EFFECT_HEAVY_CLICK
                "success" -> VibrationEffect.EFFECT_DOUBLE_CLICK
                else -> VibrationEffect.EFFECT_CLICK
            }
            v.vibrate(VibrationEffect.createPredefined(effect))
            return
        }

        val (ms, amplitude) = when (type) {
            "selection" -> 10L to 60
            "light" -> 15L to 90
            "medium" -> 22L to 150
            "heavy" -> 35L to 255
            "success" -> 30L to 180
            else -> 15L to 90
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            v.vibrate(VibrationEffect.createOneShot(ms, amplitude))
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(ms)
        }
    }
}
