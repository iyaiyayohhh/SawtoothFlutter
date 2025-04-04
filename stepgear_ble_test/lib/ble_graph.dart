import 'dart:async';
//import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:stepgear_ble_test/data_unpack.dart';
//import 'globals.dart' as globals;

//import 'package:new_project/Callback.dart';
//import 'package:new_project/Providers/UsernameProvider.dart';
//import 'package:new_project/data/AngleData.dart';
//import 'package:provider/provider.dart';
//import 'package:simple_kalman/simple_kalman.dart';
//import 'package:new_project/global_calib.dart' as globals_calib;

class GaitGraph extends StatelessWidget {
  const GaitGraph({super.key});

  @override
  Widget build(BuildContext context) {
    return const GaitGraphScreen();
  }
}

class GaitGraphScreen extends StatefulWidget {
  const GaitGraphScreen({super.key});

  @override
  State<GaitGraphScreen> createState() => _GaitGraphScreenState();
}

class _GaitGraphScreenState extends State<GaitGraphScreen> {
  final _ble = FlutterReactiveBle();

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connectSubKnee;
  StreamSubscription<ConnectionStateUpdate>? _connectSubFoot;
  StreamSubscription<ConnectionStateUpdate>? _connectSubHips;
  StreamSubscription<List<int>>? _notifySubKnee;
  StreamSubscription<List<int>>? _notifySubFoot;
  StreamSubscription<List<int>>? _notifySubHips;

  List<double> latestKneeData = [];
  List<double> latestFootData = [];
  List<double> latestHipsData = [];

  var _foundKnee = false;
  var _foundFoot = false;
  var _foundHips = false;

  double minKnee = -10.0;
  double maxKnee = 150.0;
  double minFoot = -40.0;
  double maxFoot = 40.0;
  double minHips = -30.0;
  double maxHips = 60.0;

  List<double> valKnee = [];
  List<double> valFoot = [];
  List<double> valHips = [];

  List<double> cleanvalKnee = [];
  List<double> cleanvalFoot = [];
  List<double> cleanvalHips = [];

  List<double> averageKnee = [];
  List<double> averageFoot = [];
  List<double> averageHips = [];

  Map<String, dynamic> kneejson = {};
  Map<String, dynamic> hipsjson = {};
  Map<String, dynamic> footjson = {};

  List<Map<String, dynamic>> time_knee = [];
  List<Map<String, dynamic>> time_hips = [];
  List<Map<String, dynamic>> time_foot = [];

  List<FlSpot> _kneedataPoints = [];
  List<FlSpot> _footdataPoints = [];
  List<FlSpot> _hipsdataPoints = [];

  var list_kneetime = [];
  var list_foottime = [];
  var list_hipstime = [];

  List<int> foot_state = [];

  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _scanSub = _ble.scanForDevices(withServices: []).listen(_onScanUpdate);
  }

  @override
  void dispose() {
    _notifySubKnee?.cancel();
    _notifySubFoot?.cancel();
    _notifySubHips?.cancel();
    _connectSubKnee?.cancel();
    _connectSubFoot?.cancel();
    _connectSubHips?.cancel();
    _scanSub?.cancel();
    super.dispose();
  }

  void _onScanUpdate(DiscoveredDevice device) {
    if (device.name == 'KNEESPP_SERVER' && !_foundKnee) {
      _foundKnee = true;
      _connectSubKnee = _ble.connectToDevice(id: device.id).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          _OnConnected(device.id, 'knee');
        }
      });
    } else if (device.name == 'FOOTSPP_SERVER' && !_foundFoot) {
      _foundFoot = true;
      _connectSubFoot = _ble.connectToDevice(id: device.id).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          _OnConnected(device.id, 'foot');
        }
      });
    } else if (device.name == 'HIPSSPP_SERVER' && !_foundHips) {
      _foundHips = true;
      _connectSubHips = _ble.connectToDevice(id: device.id).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          _OnConnected(device.id, 'hips');
        }
      });
    }
  }

  void _OnConnected(String deviceId, String deviceType) {
    final characteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse('0000ABF2-0000-1000-8000-00805F9B34FB'),
        serviceId: Uuid.parse('0000ABF0-0000-1000-8000-00805F9B34FB'),
        deviceId: deviceId);

    if (deviceType == 'knee') {
      _notifySubKnee =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes1) {
        setState(() {
          //callback is the old function
          //valKnee = callback(bytes1, deviceType);
          //kneejson returns map
          kneejson = callbackUnpackK(bytes1, deviceType);
          //print('Kneejson: $kneejson');
          if (_isRunning == true &&
              footjson.isNotEmpty &&
              hipsjson.isNotEmpty) {
            List<double> knee_prox = kneejson['prox'];
            //List<double> knee_dist = kneejson['dist'];
            knee_prox.forEach(
              (knee_val) {
                Map<String, dynamic> knee_point = {
                  'timestamp': DateTime.now(),
                  'data': knee_val,
                };
                time_knee.add(knee_point);
                //print(knee_point);
                /*
                _kneedataPoints
                    .add(FlSpot(_kneedataPoints.length.toDouble(), knee_val));
                    */
              },
            );
          }
        });
      });
    } else if (deviceType == 'foot') {
      _notifySubFoot =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes2) {
        setState(() {
          footjson = callbackUnpackF(bytes2, deviceType);
          //print(footjson);

          //print(kneejson['distal']);
          //print("foot: $footjson");
          if (_isRunning == true &&
              kneejson.isNotEmpty &&
              hipsjson.isNotEmpty) {
            List<double> foot_prox = footjson['prox'];
            //List<double> foot_dist = kneejson['dist'];
            foot_state = footjson['state'];

            foot_prox.forEach(
              (footval) {
                Map<String, dynamic> foot_point = {
                  'timestamp': DateTime.now(),
                  'data': footval,
                };
                time_foot.add(foot_point);
                //print(foot_point);
                /*
                _footdataPoints
                    .add(FlSpot(_footdataPoints.length.toDouble(), (footval)));
                    */
              },
            );
          }
        });
      });
    } else if (deviceType == 'hips') {
      _notifySubHips =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes3) {
        setState(() {
          hipsjson = callbackUnpackH(bytes3, deviceType);
          //final timestamphips = DateTime.now();

          if (_isRunning == true &&
              footjson.isNotEmpty &&
              kneejson.isNotEmpty) {
            List<double> hips_prox = hipsjson['prox'];
            //List<double> hips_dist = kneejson['prox'];

            hips_prox.forEach(
              (hipsval) {
                Map<String, dynamic> hips_point = {
                  'timestamp': DateTime.now(),
                  'data': hipsval,
                };
                time_hips.add(hips_point);
                //print(hips_point);
                /*
                _hipsdataPoints
                    .add(FlSpot(_hipsdataPoints.length.toDouble(), hipsval));
                    */
              },
            );
          }
          //}
        });
      });
    }
  }

  /*

  void _gaitcyclegraph() {
    setState(() {
     
    });
  }
  */
  void _startGeneratingData() {
    setState(() {
      _isRunning = true;
    });
  }

  void _stopGeneratingData() {
    setState(() {
      _isRunning = false;
      //_gaitcyclegraph();
      final first_foot = time_foot[0];
      final first_knee = time_knee[0];
      final first_hips = time_hips[0];

      final delay_hips = first_hips['timestamp'].millisecondsSinceEpoch -
          first_knee['timestamp'].millisecondsSinceEpoch;

      final delay_foot = first_foot['timestamp'].millisecondsSinceEpoch -
          first_knee['timestamp'].millisecondsSinceEpoch;

      _kneedataPoints = time_knee
          .map((point) => FlSpot(
                //point['timestamp'].millisecondsSinceEpoch.toDouble(),
                time_knee.indexOf(point).toDouble(),
                point['data'],
              ))
          .toList();
      _footdataPoints = time_foot
          .map((point) => FlSpot(
                //point['timestamp'].millisecondsSinceEpoch.toDouble(),
                time_foot.indexOf(point).toDouble(),
                point['data'],
              ))
          .toList();
      _hipsdataPoints = time_hips
          .map((point) => FlSpot(
                time_hips.indexOf(point).toDouble(),
                //point['timestamp'].millisecondsSinceEpoch.toDouble(),
                point['data'],
              ))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${DateTime.now()}'),
        //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
            ),
            const SizedBox(
              height: 20,
              width: 20,
            ),
            const Text(
              'Knee Flexion and Extension',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 20,
              width: 20,
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              child: AspectRatio(
                aspectRatio: 1.8,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: _kneedataPoints,
                        isCurved: true,
                        dotData: FlDotData(
                          show: false,
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
              width: 20,
            ),
            const Text(
              'Ankle Flexion and Extension',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 20,
              width: 20,
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              child: AspectRatio(
                aspectRatio: 1.8,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: _footdataPoints,
                        isCurved: true,
                        dotData: FlDotData(
                          show: false,
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
              width: 20,
            ),
            const Text(
              'Hip Flexion and Extension',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 20,
              width: 20,
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              child: AspectRatio(
                aspectRatio: 1.8,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: _hipsdataPoints,
                        isCurved: true,
                        dotData: FlDotData(
                          show: false,
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 100,
              width: 20,
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _isRunning ? null : _startGeneratingData,
            child: Text('Start'),
          ),
          SizedBox(width: 20),
          FloatingActionButton(
            onPressed: _isRunning ? _stopGeneratingData : null,
            child: Text('Stop'),
          ),
          SizedBox(width: 20),
        ],
      ),
    );
  }
}
