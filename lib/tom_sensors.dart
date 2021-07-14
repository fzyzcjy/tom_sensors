import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const EventChannel _rotationEventChannel = EventChannel('com.rzzsdxx/tom_sensors/rotation');

@immutable
class RotationEvent {
  final double yaw;
  final double pitch;
  final double roll;

  double get yawDeg => rad2deg(yaw);

  double get pitchDeg => rad2deg(pitch);

  double get rollDeg => rad2deg(roll);

  RotationEvent(this.yaw, this.pitch, this.roll);

  @override
  String toString() => 'RotationEvent{yaw: $yaw, pitch: $pitch, roll: $roll}';
}

double rad2deg(double rad) => (rad * 180.0) / math.pi;

RotationEvent _listToRotationEvent(List<double> list) {
  assert(list.length == 3);
  final yaw = list[0];
  var pitch = list[1];
  final roll = list[2];

  if (_invertPitch()) pitch = -pitch;

  return RotationEvent(yaw, pitch, roll);
}

bool _invertPitch() {
  if (Platform.isIOS) return true;
  if (Platform.isAndroid) return false;
  throw Exception('unsupported platform ${Platform.operatingSystem}');
}

Stream<RotationEvent>? _rotationEvents;

// ref: https://github.com/flutter/plugins/blob/master/packages/sensors/lib/sensors.dart
Stream<RotationEvent> get rotationEvents {
  return _rotationEvents ??= _rotationEventChannel.receiveBroadcastStream().map(
        (dynamic event) => _listToRotationEvent((event as List<dynamic>).cast<double>()),
      );
}

/// 这里的"角度"参考了Android对orientation的表示：https://developer.android.com/reference/android/view/OrientationEventListener#onOrientationChanged(int)
/// "orientation is 0 degrees when the device is oriented in its natural position,
/// 90 degrees when its left side is at the top,
/// 180 degrees when it is upside down,
/// and 270 degrees when its right side is to the top"
enum EstimatedOrientation {
  ROTATION_0,
  ROTATION_90,
  ROTATION_180,
  ROTATION_270,
}

extension ExtEstimatedOrientation on EstimatedOrientation {
  int get degree => numQuarter * 90;

  int get numQuarter {
    switch (this) {
      case EstimatedOrientation.ROTATION_0:
        return 0;
      case EstimatedOrientation.ROTATION_90:
        return 1;
      case EstimatedOrientation.ROTATION_180:
        return 2;
      case EstimatedOrientation.ROTATION_270:
        return 3;
    }
  }
}

Stream<EstimatedOrientation>? _estimatedOrientationEvents;

Stream<EstimatedOrientation> get estimatedOrientationEvents {
  return _estimatedOrientationEvents ??= _createEstimatedOrientation();
}

// NOTE 小心：保证没人subscribe返回的Stream时，上游的stream也要被unsubscribe，否则Android/iOS会不停地高频率返回旋转数据，很浪费资源
Stream<EstimatedOrientation> _createEstimatedOrientation({Duration hysteresis = const Duration(milliseconds: 500)}) {
  EstimatedOrientation? emittedOri;
  EstimatedOrientation? proposedOri;
  DateTime? proposedOriStartTime;

  return rotationEvents
      .map<EstimatedOrientation?>((event) {
        final oriFromEvent = _estimateFromSingleEvent(event);

        // 无法确定当前怎么转的（比如非常接近平放），那就假装没看见
        if (oriFromEvent == null) {
          return null;
        }

        if (oriFromEvent != proposedOri) {
          proposedOri = oriFromEvent;
          proposedOriStartTime = DateTime.now();
        }

        if (emittedOri != proposedOri &&
            proposedOriStartTime != null &&
            DateTime.now().difference(proposedOriStartTime!) > hysteresis) {
          emittedOri = proposedOri;
          return emittedOri;
        }

        return null; // drop event
      })
      .where((e) => e != null)
      .map((e) => e!);
}

EstimatedOrientation? _estimateFromSingleEvent(RotationEvent event, {double thresholdDeg = 15.0}) {
  // 自己拿着[tom_sensors/example]这个App做一做实验，就知道各个参数的情况了
  // NOTE 注意android和ios的数据有时候是不一致的...

  final rollDeg = event.rollDeg;
  final pitchDeg = event.pitchDeg;

  if (rollDeg > thresholdDeg) return EstimatedOrientation.ROTATION_90;
  if (rollDeg < -thresholdDeg) return EstimatedOrientation.ROTATION_270;
  if (pitchDeg > thresholdDeg) return EstimatedOrientation.ROTATION_180;
  if (pitchDeg < -thresholdDeg) return EstimatedOrientation.ROTATION_0;
  return null;
}
