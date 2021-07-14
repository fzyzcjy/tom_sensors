package com.rzzsdxx.tom_sensors

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorManager
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

// NOTE ref:
//  1. flutter官方sensors库 https://github.com/flutter/plugins/blob/master/packages/sensors/android/src/main/java/io/flutter/plugins/sensors/SensorsPlugin.java
//  2. https://github.com/aeyrium/aeyrium-sensor
//  3. 传感器 https://developer.android.com/guide/topics/sensors/sensors_motion?hl=zh-cn#sensors-motion-rotate
class TomSensorsPlugin : FlutterPlugin {
    private var rotationChannel: EventChannel? = null

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        val context = binding.applicationContext
        setupEventChannels(context, binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        teardownEventChannels()
    }

    private fun setupEventChannels(context: Context, messenger: BinaryMessenger) {
        Log.i(TAG, "setupEventChannels")
        rotationChannel = EventChannel(messenger, ROTATION_CHANNEL_NAME)
        val rotationStreamHandler = StreamHandlerImpl(
                context.getSystemService(Context.SENSOR_SERVICE) as SensorManager,
                Sensor.TYPE_ROTATION_VECTOR)
        rotationChannel!!.setStreamHandler(rotationStreamHandler)
    }

    private fun teardownEventChannels() {
        Log.i(TAG, "teardownEventChannels")
        rotationChannel!!.setStreamHandler(null)
    }

    companion object {
        private const val ROTATION_CHANNEL_NAME = "com.rzzsdxx/tom_sensors/rotation"
        private const val TAG = "TomSensorsPlugin"
    }
}