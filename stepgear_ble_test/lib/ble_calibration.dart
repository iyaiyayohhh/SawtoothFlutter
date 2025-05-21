import 'dart:async';
//import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stepgear_ble_test/angle_data.dart';
import 'package:stepgear_ble_test/ble_graph.dart';
import 'package:stepgear_ble_test/data_unpack.dart';
import 'package:collection/collection.dart';
//import 'globals.dart' as globals;

//import 'package:new_project/Callback.dart';
//import 'package:new_project/Providers/UsernameProvider.dart';
//import 'package:new_project/data/AngleData.dart';
//import 'package:provider/provider.dart';
//import 'package:simple_kalman/simple_kalman.dart';
//import 'package:new_project/global_calib.dart' as globals_calib;

class CalibrationPage extends StatelessWidget {
  final FlutterReactiveBle ble;
  const CalibrationPage({super.key, required this.ble});

  @override
  Widget build(BuildContext context) {
    return CalibrationPageScreen(ble: ble);
  }
}

class CalibrationPageScreen extends StatefulWidget {
  final FlutterReactiveBle ble;
  const CalibrationPageScreen({super.key, required this.ble});

  @override
  State<CalibrationPageScreen> createState() => _CalibrationPageScreenState();
}

class _CalibrationPageScreenState extends State<CalibrationPageScreen> {
  late final FlutterReactiveBle _ble;

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connectSubKnee;
  StreamSubscription<ConnectionStateUpdate>? _connectSubFoot;
  StreamSubscription<ConnectionStateUpdate>? _connectSubHips;
  StreamSubscription<List<int>>? _notifySubKnee;
  StreamSubscription<List<int>>? _notifySubFoot;
  StreamSubscription<List<int>>? _notifySubHips;

  String? kneeDeviceId;
  String? footDeviceId;
  String? hipsDeviceId;

  List<double> latestKneeData = [];
  List<double> latestFootData = [];
  List<double> latestHipsData = [];

  var _foundKnee = false;
  var _foundFoot = false;
  var _foundHips = false;

  List<double> valKneeProx = [];
  List<double> valKneeDist = [];
  List<double> valFootProx = [];
  List<double> valHipsProx = [];

  var averageKneeProx = 0.0;
  var averageKneeDist = 0.0;
  var averageFootProx = 0.0;
  var averageHipsProx = 0.0;

  Map<String, dynamic> kneejson = {};
  Map<String, dynamic> hipsjson = {};
  Map<String, dynamic> footjson = {};

  List<List<int>> rawKneeCalib = [];
  List<List<int>> rawFootCalib = [];
  List<List<int>> rawHipsCalib = [];

  double kneeProxCalib = 0.0;
  double kneeDistCalib = 0.0;
  double footProxCalib = 0.0;
  double hipsProxCalib = 0.0;

  var _valueKnee = '';
  var _valueFoot = '';
  var _valueHips = '';

  List<int> footState = [];

  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _ble = widget.ble;
    requestPermissions().then((_) {
      _scanSub = _ble.scanForDevices(withServices: []).listen(_onScanUpdate,
          onError: (e) {
        print('Scan Error $e');
      });
    });
  }

  @override
  void dispose() {
    //maintain connections to next page
    //_notifySubKnee?.cancel();
    //_notifySubFoot?.cancel();
    //_notifySubHips?.cancel();
    //_connectSubKnee?.cancel();
    //_connectSubFoot?.cancel();
    //_connectSubHips?.cancel();
    _scanSub?.cancel();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();
  }

  void _onScanUpdate(DiscoveredDevice device) {
    if (device.name == 'KNEESPP_SERVER' && !_foundKnee) {
      _foundKnee = true;
      _connectSubKnee = _ble.connectToDevice(id: device.id).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          _onConnected(device.id, 'knee');
          kneeDeviceId = device.id;
          //store device id for next page
        } else if (update.connectionState ==
            DeviceConnectionState.disconnected) {
          _foundKnee = false;
        }
      });
    } else if (device.name == 'FOOTSPP_SERVER' && !_foundFoot) {
      _foundFoot = true;
      _connectSubFoot = _ble.connectToDevice(id: device.id).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          _onConnected(device.id, 'foot');
          footDeviceId = device.id;
        } else if (update.connectionState ==
            DeviceConnectionState.disconnected) {
          _foundFoot = false;
        }
      });
    } else if (device.name == 'HIPSSPP_SERVER' && !_foundHips) {
      _foundHips = true;
      _connectSubHips = _ble.connectToDevice(id: device.id).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          _onConnected(device.id, 'hips');
          hipsDeviceId = device.id;
        } else if (update.connectionState ==
            DeviceConnectionState.disconnected) {
          _foundHips = false;
        }
      });
    }
  }

  void _onConnected(String deviceId, String deviceType) {
    final characteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse('0000ABF2-0000-1000-8000-00805F9B34FB'),
        serviceId: Uuid.parse('0000ABF0-0000-1000-8000-00805F9B34FB'),
        deviceId: deviceId);

    if (deviceType == 'knee') {
      _notifySubKnee =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes1) {
        setState(() {
          if (_foundKnee & _foundFoot & _foundHips) {
            rawKneeCalib.add(bytes1);
            //print('Knee: $bytes1');
          }
        });
      });
    } else if (deviceType == 'foot') {
      _notifySubFoot =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes2) {
        setState(() {
          if (_foundKnee & _foundFoot & _foundHips) {
            rawFootCalib.add(bytes2);
            //print('Foot: $bytes2');
          }
        });
      });
    } else if (deviceType == 'hips') {
      _notifySubHips =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes3) {
        setState(() {
          if (_foundFoot & _foundKnee & _foundHips) {
            rawHipsCalib.add(bytes3);
            //print('Hips: $bytes3');
            //print('Hips: ${bytes3.length}');
          }
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

      // Process raw data for hips

      for (var b in rawKneeCalib) {
        kneejson = callbackUnpackK(b, 'knee');
        //print('kneejson: $kneejson');
        if (kneejson.isNotEmpty) {
          var kneeProx = kneeProxraw(kneejson['prox']);
          var kneeDist = kneeDistraw(kneejson['dist']);
          valKneeProx.add(kneeProx);
          valKneeDist.add(kneeDist);
        }
      }
      //print(valKneeProx);
      averageKneeProx = valKneeProx.average;
      averageKneeDist = valKneeDist.average;
      _valueKnee = (averageKneeDist - averageKneeProx).toStringAsFixed(2);
      //print('Knee: $_valueKnee Prox: $averageKneeProx Dist: $averageKneeDist');

      for (var a in rawFootCalib) {
        footjson = callbackUnpackF(a, 'foot');
        //print('footjson: $footjson');
        if (footjson.isNotEmpty) {
          var footProx = footProxraw(footjson['prox']);
          var footStateValue = footjson['state'];
          valFootProx.add(footProx);
          footState.add(footStateValue);
        }
      }
      averageFootProx = valFootProx.average;
      _valueFoot =
          (((averageFootProx + 90) - averageKneeDist) - 180).toStringAsFixed(2);

      for (var c in rawHipsCalib) {
        hipsjson = callbackUnpackHB(c, 'hips');
        //print('hips: $hipsjson');
        if (hipsjson.isNotEmpty) {
          var hipsProx = hipsProxraw(hipsjson['prox']);
          valHipsProx.add(hipsProx);
        }
      }
      averageHipsProx = valHipsProx.average;
      _valueHips = (averageKneeProx - averageHipsProx).toStringAsFixed(2);

      // Clear the buffers after processing
      rawKneeCalib.clear();
      rawFootCalib.clear();
      rawHipsCalib.clear();
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
            _valueKnee.isEmpty
                ? const CircularProgressIndicator()
                : Text(
                    "Knee:  $_valueKnee Prox: $averageKneeProx Dist: $averageKneeDist",
                    style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(
              height: 20,
              width: 20,
            ),
            Text('Knee Prox Calib: $kneeProxCalib',
                style: Theme.of(context).textTheme.titleLarge),
            Slider(
              value: kneeProxCalib,
              min: -20,
              max: 20,
              divisions: 80,
              label: kneeProxCalib.round().toString(),
              onChanged: (_isRunning
                  ? null
                  : (value) {
                      setState(() {
                        kneeProxCalib = value;
                      });
                    }),
            ),
            const SizedBox(
              height: 20,
              width: 20,
            ),
            _valueFoot.isEmpty
                ? const CircularProgressIndicator()
                : Text(
                    "Foot:  $_valueFoot Prox: $averageFootProx Dist: $averageKneeDist",
                    style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(
              height: 20,
              width: 20,
            ),
            Text('Foot Prox Calib: $footProxCalib',
                style: Theme.of(context).textTheme.titleLarge),
            Slider(
              value: footProxCalib,
              min: -20,
              max: 20,
              divisions: 80,
              label: footProxCalib.round().toString(),
              onChanged: (_isRunning
                  ? null
                  : (value) {
                      setState(() {
                        footProxCalib = value;
                      });
                    }),
            ),
            const SizedBox(
              height: 20,
              width: 20,
            ),
            _valueHips.isEmpty
                ? const CircularProgressIndicator()
                : Text(
                    "Hips:  $_valueHips Prox: $averageHipsProx Dist: $averageKneeProx",
                    style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(
              height: 20,
              width: 20,
            ),
            Text('Hips Prox Calib: $hipsProxCalib',
                style: Theme.of(context).textTheme.titleLarge),
            Slider(
              value: hipsProxCalib,
              min: -20,
              max: 20,
              divisions: 80,
              label: hipsProxCalib.round().toString(),
              onChanged: (_isRunning
                  ? null
                  : (value) {
                      setState(() {
                        hipsProxCalib = value;
                      });
                    }),
            ),
            const SizedBox(
              height: 20,
              width: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : _startGeneratingData,
                  child: const Text('Start'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? _stopGeneratingData : null,
                  child: const Text('Stop'),
                ),
              ],
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => GaitGraph(
                                ble: widget.ble,
                                kneeDeviceId: kneeDeviceId!,
                                footDeviceId: footDeviceId!,
                                hipsDeviceId: hipsDeviceId!,
                                kneeProxCalib: kneeProxCalib,
                                footProxCalib: footProxCalib,
                                hipsProxCalib: hipsProxCalib,
                                kneeDistCalib: kneeDistCalib,
                              )));
                },
                child: const Text('Gait Graph')),

            /*
            ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => GaitGraph()));
                },
                child: const Text('Save')),
                */
          ],
        ),
      ),
    );
  }
}
