import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tom_sensors/tom_sensors.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  RotationEvent? _rotationEvent;
  EstimatedOrientation? _estimatedOrientation;

  // ignore: cancel_subscriptions
  List<StreamSubscription>? _subscriptions;

  @override
  void initState() {
    super.initState();
    _toggle();
  }

  // static String _fmt(String name, double rad, double deg) {
  //   return '${name.padLeft(8)}: ${rad.toStringAsFixed(3).padLeft(8)} (deg: ${deg.toStringAsFixed(2).padLeft(8)})\n';
  // }

  void _toggle() {
    setState(() {
      if (_subscriptions == null) {
        print('do subscribe');
        _subscriptions = [
          rotationEvents.listen((e) {
            // print('see rotationEvent $e');
            setState(() => _rotationEvent = e);
          }),
          estimatedOrientationEvents.listen((e) {
            // NOTE 如果太频繁看见，就不合理
            print('SEE estimatedOrientationEvent $e');
            setState(() => _estimatedOrientation = e);
          }),
        ];
      } else {
        print('do unsubscribe');
        for (final sub in _subscriptions!) {
          sub.cancel();
        }
        _subscriptions = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('TomSensors')),
        body: ListView(
          children: [
            ListTile(
              onTap: _toggle,
              title: Text('toggle'),
            ),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text('orientation'),
                ),
                Text('${_estimatedOrientation == null ? null : describeEnum(_estimatedOrientation!)}'),
              ],
            ),
            _buildRow('yaw', _rotationEvent?.yaw),
            _buildRow('pitch', _rotationEvent?.pitch),
            _buildRow('roll', _rotationEvent?.roll),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String name, double? value) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(name)),
        SizedBox(width: 120, child: Text('rad=${value?.toStringAsFixed(3)}')),
        SizedBox(width: 120, child: Text('deg=${value == null ? null : rad2deg(value).toStringAsFixed(1)}')),
      ],
    );
  }
}
