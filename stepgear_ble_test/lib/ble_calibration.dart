import 'dart:async';
//import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scidart/numdart.dart';
import 'package:stepgear_ble_test/angle_data.dart';
import 'package:stepgear_ble_test/ble_graph.dart';
import 'package:stepgear_ble_test/data_unpack.dart';
import 'package:collection/collection.dart';

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
  final TextEditingController _kneeProxCalibController =
      TextEditingController();
  final TextEditingController _footProxCalibController =
      TextEditingController();
  final TextEditingController _hipsProxCalibController =
      TextEditingController();
  final TextEditingController _kneeDistCalibController =
      TextEditingController();

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

  List<int> kneeData = [];
  List<int> footData = [];
  List<int> hipsData = [];

  var kneeProx = 0.0;
  var kneeDist = 0.0;
  var footProx = 0.0;
  var footDist = 0.0;
  var hipsProx = 0.0;
  var hipsDist = 0.0;

  var _valueKnee = '';
  var _valueFoot = '';
  var _valueHips = '';

  List<int> footState = [];

  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _ble = widget.ble;
    _kneeProxCalibController.text = kneeProxCalib.toString();
    _footProxCalibController.text = footProxCalib.toString();
    _hipsProxCalibController.text = hipsProxCalib.toString();
    _kneeDistCalibController.text = kneeDistCalib.toString();
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
    _kneeProxCalibController.dispose();
    _kneeDistCalibController.dispose();
    _footProxCalibController.dispose();
    _hipsProxCalibController.dispose();
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
          kneeData = bytes1;
          if (_isRunning &
              kneeData.isNotEmpty &
              footData.isNotEmpty &
              hipsData.isNotEmpty) {
            rawKneeCalib.add(bytes1);
            kneejson = callbackUnpackK(bytes1, 'knee');
            if (kneejson.isNotEmpty) {
              kneeProx = kneeProxraw(kneejson['prox']);
              kneeDist = kneeDistraw(kneejson['dist']);
              _valueKnee = (kneeDist - kneeProx).toStringAsFixed(2);
            }

            //print('Knee: $bytes1');
          }
        });
      });
    } else if (deviceType == 'foot') {
      _notifySubFoot =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes2) {
        setState(() {
          footData = bytes2;
          if (_isRunning &
              kneeData.isNotEmpty &
              footData.isNotEmpty &
              hipsData.isNotEmpty) {
            rawFootCalib.add(bytes2);
            //print('Foot: $bytes2');
            footjson = callbackUnpackF(bytes2, 'foot');
            Map<String, dynamic> footKneeDist =
                callbackUnpackK(kneeData, 'knee');
            if (footjson.isNotEmpty && footKneeDist.isNotEmpty) {
              footProx = footProxraw(footjson['prox']);
              footDist = kneeDistraw(footKneeDist['dist']);
              _valueFoot =
                  (((footProx + 90) - footDist) - 180).toStringAsFixed(2);
            }
          }
        });
      });
    } else if (deviceType == 'hips') {
      _notifySubHips =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes3) {
        setState(() {
          hipsData = bytes3;
          if (_isRunning &
              kneeData.isNotEmpty &
              footData.isNotEmpty &
              hipsData.isNotEmpty) {
            rawHipsCalib.add(bytes3);
            hipsjson = callbackUnpackHB(bytes3, 'hips');
            Map<String, dynamic> kneeHipDist =
                callbackUnpackK(kneeData, 'knee');

            if (hipsjson.isNotEmpty && kneeHipDist.isNotEmpty) {
              hipsProx = hipsProxraw(hipsjson['prox']);
              hipsDist = kneeDistraw(kneeHipDist['prox']);
              _valueHips = (hipsDist - hipsProx).toStringAsFixed(2);
            }
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
                : Text("Knee:  $_valueKnee Prox: $kneeProx Dist: $kneeDist",
                    style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(
              height: 20,
              width: 20,
            ),
            Text('Knee Prox Calib: $kneeProxCalib',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _kneeProxCalibController,
                enabled: !_isRunning,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Enter knee prox calib'),
                onChanged: (value) {
                  final parsed = double.tryParse(value);
                  if (parsed != null) {
                    setState(() {
                      kneeProxCalib = parsed;
                    });
                  }
                },
              ),
            ),
            const SizedBox(
              height: 20,
              width: 20,
            ),
            Text('Knee Dist Calib: $kneeDistCalib',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _kneeDistCalibController,
                enabled: !_isRunning,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Enter knee dist value'),
                onChanged: (value) {
                  final parsed = double.tryParse(value);
                  if (parsed != null) {
                    setState(() {
                      kneeDistCalib = parsed;
                    });
                  }
                },
              ),
            ),
            const SizedBox(
              height: 20,
              width: 20,
            ),
            _valueFoot.isEmpty
                ? const CircularProgressIndicator()
                : Text("Foot:  $_valueFoot Prox: $footProx Dist: $footDist",
                    style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(
              height: 20,
              width: 20,
            ),
            Text('Foot Prox Calib: $footProxCalib',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _footProxCalibController,
                enabled: !_isRunning,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Enter foot prox value'),
                onChanged: (value) {
                  final parsed = double.tryParse(value);
                  if (parsed != null) {
                    setState(() {
                      footProxCalib = parsed;
                    });
                  }
                },
              ),
            ),
            const SizedBox(
              height: 20,
              width: 20,
            ),
            _valueHips.isEmpty
                ? const CircularProgressIndicator()
                : Text("Hips:  $_valueHips Prox: $hipsProx Dist: $hipsDist",
                    style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(
              height: 20,
              width: 20,
            ),
            Text('Hips Prox Calib: $hipsProxCalib',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _hipsProxCalibController,
                enabled: !_isRunning,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Enter hips prox value'),
                onChanged: (value) {
                  final parsed = double.tryParse(value);
                  if (parsed != null) {
                    setState(() {
                      hipsProxCalib = parsed;
                    });
                  }
                },
              ),
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
