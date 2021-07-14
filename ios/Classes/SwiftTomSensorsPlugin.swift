import Flutter
import UIKit
import CoreMotion

// NOTE ref
// 1. flutter官方sensors https://github.com/flutter/plugins/blob/master/packages/sensors/ios/Classes/FLTSensorsPlugin.m
// 2. aeyruium https://github.com/aeyrium/aeyrium-sensor/blob/master/ios/Classes/AeyriumSensorPlugin.m
// 3. Flutter EventChannel https://stackoverflow.com/questions/59693268/how-to-stream-data-from-swift-to-flutter-using-event-channel
// 4. ios的DeviceMotion https://developer.apple.com/documentation/coremotion/getting_processed_device-motion_data
public class SwiftTomSensorsPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let rotationChannel = FlutterEventChannel(name: "com.rzzsdxx/tom_sensors/rotation", binaryMessenger: registrar.messenger())
        rotationChannel.setStreamHandler(RotationStreamHandler())
    }
}

class RotationStreamHandler: NSObject, FlutterStreamHandler {
    var motion: CMMotionManager? = nil
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        
        if motion == nil { motion = CMMotionManager() }
        
        if let motion = motion {
            if !motion.isDeviceMotionAvailable {
                return FlutterError(code: "general-error", message: "!motion.isDeviceMotionAvailable", details: nil)
            }
            
            motion.deviceMotionUpdateInterval = 1.0 / 20.0 // NOTE 刷新率
            motion.showsDeviceMovementDisplay = true
            motion.startDeviceMotionUpdates(
                using: .xMagneticNorthZVertical,
                to: OperationQueue(),
                withHandler: { (data, error) in
                    if let data = data {
                        let yaw = data.attitude.yaw
                        let pitch = data.attitude.pitch
                        let roll = data.attitude.roll
                        
                        // https://stackoverflow.com/questions/44791531/convert-integer-array-to-data
                        let buf: [Double] = [yaw, pitch, roll]
                        let event = buf.withUnsafeBufferPointer {Data(buffer: $0)}
                        events(FlutterStandardTypedData(float64: event))
                    } else {
                        print("WARN RotationStreamHandler received data but is nil")
                    }
                }
            )
        } else {
            print("WARN RotationStreamHandler see motion==null")
        }
        
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        motion!.stopDeviceMotionUpdates()
        return nil
    }
}
