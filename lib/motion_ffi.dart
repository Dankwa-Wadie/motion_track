import 'dart:ffi';
import 'dart:io';

// Load native library
final DynamicLibrary _lib = Platform.isAndroid
    ? DynamicLibrary.open("libedge_inference.so")
    : DynamicLibrary.process();

// Native C type
typedef _NativeRunInference = Float Function(Float, Float, Float);

// Dart function type
typedef _RunInference = double Function(double, double, double);

// Lookup the function
final _RunInference runInference =
_lib.lookup<NativeFunction<_NativeRunInference>>("run_inference").asFunction();

// Helper
double inferMotion(double x, double y, double z) {
  return runInference(x, y, z);
}
