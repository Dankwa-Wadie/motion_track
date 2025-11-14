import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'motion_ffi.dart';
import 'splash_screen.dart';


enum MovementState { idle, upAndDown, circular }

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MotionDetectorApp());
}

class MotionDetectorApp extends StatelessWidget {
  const MotionDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Edge Motion Detector",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
        home: const AppSplash(),
    );
  }
}

class MovementDetectorScreen extends StatefulWidget {
  const MovementDetectorScreen({super.key});

  @override
  State<MovementDetectorScreen> createState() => _MovementDetectorScreenState();
}

class _MovementDetectorScreenState extends State<MovementDetectorScreen>
    with SingleTickerProviderStateMixin {
  MovementState _currentState = MovementState.idle;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  AccelerometerEvent? _latestAccel;
  GyroscopeEvent? _latestGyro;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _startSensors();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _animController.dispose();
    super.dispose();
  }

  // -------------------------
  // SENSOR LISTENERS
  // -------------------------
  void _startSensors() {
    _accelSub = accelerometerEvents.listen((event) {
      _latestAccel = event;
      if (_latestGyro != null) {
        _detectMovement(event, _latestGyro!);
      }
    });

    _gyroSub = gyroscopeEvents.listen((event) {
      _latestGyro = event;
      if (_latestAccel != null) {
        _detectMovement(_latestAccel!, event);
      }
    });
  }

  // -------------------------
  // DETECTION USING FFI MODEL
  // -------------------------
  void _detectMovement(AccelerometerEvent accel, GyroscopeEvent gyro) {
    final score = inferMotion(accel.x, accel.y, accel.z);

    setState(() {
      if (score > 0.5) {
        _currentState = MovementState.upAndDown;
      } else {
        _currentState = MovementState.idle;
      }
    });
  }

  // UI LABELS & COLORS
  (String, IconData, Color) _getStateVisuals() {
    switch (_currentState) {
      case MovementState.upAndDown:
        return ("Up & Down Motion", Icons.arrow_upward_rounded, Colors.green);
      case MovementState.circular:
        return ("Circular Motion", Icons.sync_rounded, Colors.orange);
      default:
        return ("Idle", Icons.pause_circle_filled_rounded, Colors.grey);
    }
  }

  // -------------------------
  // MAIN UI BUILD
  // -------------------------
  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = _getStateVisuals();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edge Motion Detector"),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset("lib/assets/logo.png"),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 6,
      ),

      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),

            // Animated Icon
            ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.2).animate(_animController),
              child: Icon(icon, size: 120, color: color),
            ),

            const SizedBox(height: 14),

            Text(
              label,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 30),

            _buildSensorCard(),
            _buildFfiCard(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // REUSABLE CARDS
  // -------------------------
  Widget _buildSensorCard() {
    return _card(
      title: "Live Sensor Data",
      child: Text(
        _latestAccel == null
            ? "Waiting for sensor input…"
            : "Accel: x=${_latestAccel!.x.toStringAsFixed(2)}   "
            "y=${_latestAccel!.y.toStringAsFixed(2)}   "
            "z=${_latestAccel!.z.toStringAsFixed(2)}\n"
            "Gyro:  x=${_latestGyro?.x.toStringAsFixed(2) ?? "--"}   "
            "y=${_latestGyro?.y.toStringAsFixed(2) ?? "--"}   "
            "z=${_latestGyro?.z.toStringAsFixed(2) ?? "--"}",
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildFfiCard() {
    return _card(
      title: "Edge Impulse Model (FFI)",
      child: const Text(
        "Sensor values are passed into the C++ model through Dart FFI.\n"
            "Inference runs natively on-device for fast ML classification.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15),
      ),
    );
  }

  // Card UI Design
  Widget _card({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade50,
            Colors.deepPurple.shade100.withOpacity(.6),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Text(title,
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
