#import "TomSensorsPlugin.h"
#if __has_include(<tom_sensors/tom_sensors-Swift.h>)
#import <tom_sensors/tom_sensors-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "tom_sensors-Swift.h"
#endif

@implementation TomSensorsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftTomSensorsPlugin registerWithRegistrar:registrar];
}
@end
