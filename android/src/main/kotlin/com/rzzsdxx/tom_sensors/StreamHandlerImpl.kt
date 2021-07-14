package com.rzzsdxx.tom_sensors

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink

// NOTE ref https://github.com/flutter/plugins/blob/master/packages/sensors/android/src/main/java/io/flutter/plugins/sensors/StreamHandlerImpl.java
class StreamHandlerImpl(private val sensorManager: SensorManager, sensorType: Int) : EventChannel.StreamHandler {
    private var sensorEventListener: SensorEventListener? = null
    private val sensor: Sensor = sensorManager.getDefaultSensor(sensorType)

    override fun onListen(arguments: Any?, events: EventSink) {
        Log.i(TAG, "onListen")
        sensorEventListener = createSensorEventListener(events)
        sensorManager.registerListener(sensorEventListener, sensor, SensorManager.SENSOR_DELAY_NORMAL)
    }

    override fun onCancel(arguments: Any?) {
        Log.i(TAG, "onCancel")
        sensorManager.unregisterListener(sensorEventListener)
    }

    private fun createSensorEventListener(events: EventSink): SensorEventListener {
        return object : SensorEventListener {
            override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
            override fun onSensorChanged(event: SensorEvent) {
//                Log.t(TAG, "onSensorChanged values=${event.values?.contentToString()}")

                // NOTE ref https://github.com/aeyrium/aeyrium-sensor/blob/master/android/src/main/java/com/aeyrium/sensor/AeyriumSensorPlugin.java
                // TODO 参考的aeyrium还有一个[SensorManager.remapCoordinateSystem]操作，我们要做吗？

                val rotationMatrix = FloatArray(9)
                SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)

                val orientation = FloatArray(3)
                SensorManager.getOrientation(rotationMatrix, orientation)

                events.success(orientation.map(Float::toDouble))
            }
        }
    }

    companion object {
        private const val TAG = "StreamHandlerImpl"
    }
}