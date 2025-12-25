import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const SprayerApp());
}

/* ================= APP ROOT ================= */
class SprayerApp extends StatelessWidget {
  const SprayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ControlPage(),
    );
  }
}

/* ================= LOGO ================= */
class NatureAgriLogo extends StatelessWidget {
  const NatureAgriLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.green.shade300, Colors.green.shade600],
              ),
            ),
            child: const Icon(Icons.eco, size: 46, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            "Smart Sprayer",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

/* ================= CONTROL PAGE ================= */
class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  final String baseUrl = "http://192.168.4.1/cmd?c=";

  bool pumpOn = false;
  bool isConnected = false;
  Timer? statusTimer;

  /* ---------- SEND COMMAND ---------- */
  Future<void> sendCmd(String cmd) async {
    HapticFeedback.lightImpact();
    try {
      await HttpClient()
          .getUrl(Uri.parse(baseUrl + cmd))
          .then((req) => req.close());
    } catch (_) {}
  }

  /* ---------- CONNECTION CHECK ---------- */
  Future<void> checkConnection() async {
    try {
      final req = await HttpClient()
          .getUrl(Uri.parse("http://192.168.4.1"))
          .timeout(const Duration(milliseconds: 700));
      await req.close();
      setState(() => isConnected = true);
    } catch (_) {
      setState(() => isConnected = false);
    }
  }

  @override
  void initState() {
    super.initState();
    statusTimer =
        Timer.periodic(const Duration(seconds: 2), (_) => checkConnection());
  }

  @override
  void dispose() {
    statusTimer?.cancel();
    super.dispose();
  }

  /* ---------- HOLD BUTTON (CONTINUOUS MOVE) ---------- */
  Widget holdButton(IconData icon, String cmd) {
    return GestureDetector(
      onTapDown: (_) => sendCmd(cmd),     // start moving
      onTapUp: (_) => sendCmd("S"),       // stop when released
      onTapCancel: () => sendCmd("S"),    // safety
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green.shade200,
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade300,
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(icon, size: 34, color: Colors.green.shade900),
      ),
    );
  }

  /* ---------- TOGGLE BUTTON (PUMP) ---------- */
  Widget toggleButton(IconData onIcon, IconData offIcon) {
    return GestureDetector(
      onTap: () {
        pumpOn = !pumpOn;
        sendCmd(pumpOn ? "PON" : "POFF");
        setState(() {});
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: pumpOn ? Colors.green.shade600 : Colors.green.shade300,
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade200,
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(
          pumpOn ? onIcon : offIcon,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }

  /* ---------- UI ---------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFDFF5E1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [

              /* LEFT: LOGO + STATUS */
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const NatureAgriLogo(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        isConnected ? Icons.wifi : Icons.wifi_off,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isConnected ? "Connected" : "Disconnected",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              /* CENTER: VEHICLE */
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  holdButton(Icons.keyboard_arrow_up, "F"),
                  Row(
                    children: [
                      holdButton(Icons.keyboard_arrow_left, "L"),
                      const SizedBox(width: 20),
                      holdButton(Icons.stop, "S"),
                      const SizedBox(width: 20),
                      holdButton(Icons.keyboard_arrow_right, "R"),
                    ],
                  ),
                  holdButton(Icons.keyboard_arrow_down, "B"),
                ],
              ),

              /* RIGHT: HEIGHT + PUMP */
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  holdButton(Icons.vertical_align_top, "UP"),
                  const SizedBox(height: 18),
                  holdButton(Icons.vertical_align_bottom, "DN"),
                  const SizedBox(height: 28),
                  toggleButton(Icons.opacity, Icons.opacity_outlined),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
