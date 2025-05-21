import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:stepgear_ble_test/ble_calibration.dart';
//import 'package:stepgear_ble_test/ble_graph.dart';

class Intropage extends StatelessWidget {
  final FlutterReactiveBle ble;
  const Intropage({Key? key, required this.ble}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intro Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to the Intro Page!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            /*
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GaitGraph(),
                  ),
                );
              },
              child: const Text('Next'),
            ),
            */
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CalibrationPage(ble: ble),
                    ),
                  );
                },
                child: const Text('Calibrate')),
          ],
        ),
      ),
    );
  }
}
