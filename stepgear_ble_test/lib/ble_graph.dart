import 'dart:async';
//import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:scidart/numdart.dart';
import 'package:stepgear_ble_test/angle_data.dart';
import 'package:stepgear_ble_test/data_unpack.dart';
//import 'globals.dart' as globals;

//import 'package:new_project/Callback.dart';
//import 'package:new_project/Providers/UsernameProvider.dart';
//import 'package:new_project/data/AngleData.dart';
//import 'package:provider/provider.dart';
//import 'package:simple_kalman/simple_kalman.dart';
//import 'package:new_project/global_calib.dart' as globals_calib;

class GaitGraph extends StatelessWidget {
  final FlutterReactiveBle ble;
  final String kneeDeviceId;
  final String footDeviceId;
  final String hipsDeviceId;
  final double kneeProxCalib;
  final double kneeDistCalib;
  final double footProxCalib;
  final double hipsProxCalib;

  const GaitGraph({
    Key? key,
    required this.ble,
    required this.kneeDeviceId,
    required this.footDeviceId,
    required this.hipsDeviceId,
    required this.kneeProxCalib,
    required this.kneeDistCalib,
    required this.footProxCalib,
    required this.hipsProxCalib,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GaitGraphScreen(
      ble: ble,
      kneeDeviceId: kneeDeviceId,
      footDeviceId: footDeviceId,
      hipsDeviceId: hipsDeviceId,
      kneeProxCalib: kneeProxCalib,
      kneeDistCalib: kneeDistCalib,
      footProxCalib: footProxCalib,
      hipsProxCalib: hipsProxCalib,
    );
  }
}

class GaitGraphScreen extends StatefulWidget {
  final FlutterReactiveBle ble;
  final String kneeDeviceId;
  final String footDeviceId;
  final String hipsDeviceId;
  final double kneeProxCalib;
  final double kneeDistCalib;
  final double footProxCalib;
  final double hipsProxCalib;

  const GaitGraphScreen({
    Key? key,
    required this.ble,
    required this.kneeDeviceId,
    required this.footDeviceId,
    required this.hipsDeviceId,
    required this.kneeProxCalib,
    required this.kneeDistCalib,
    required this.footProxCalib,
    required this.hipsProxCalib,
  }) : super(key: key);

  @override
  State<GaitGraphScreen> createState() => _GaitGraphScreenState();
}

class _GaitGraphScreenState extends State<GaitGraphScreen> {
  late final FlutterReactiveBle _ble;

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

  //List<Map<String, dynamic>> _timeKnee = [];
  //List<Map<String, dynamic>> _timeHips = [];
  //List<Map<String, dynamic>> _timeFoot = [];

  List<Map<String, dynamic>> _unpackKnee = [];
  List<Map<String, dynamic>> _unpackHips = [];
  List<Map<String, dynamic>> _unpackFoot = [];

  List<FlSpot> _kneedataPoints = [];
  List<FlSpot> _footdataPoints = [];
  List<FlSpot> _hipsdataPoints = [];

  //var _listKneeTime = [];
  //var _listFootTime = [];
  //var _listHipsTime = [];

  List<Map<String, dynamic>> rawKneeData = [];
  List<Map<String, dynamic>> rawFootData = [];
  List<Map<String, dynamic>> rawHipsData = [];

  List<int> kneeData = [];
  List<int> footData = [];
  List<int> hipsData = [];

  List<int> footStateList = [];
  int footState = 0;

  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _ble = widget.ble;
    /*
    requestPermissions().then((_) {
      _scanSub = _ble.scanForDevices(withServices: []).listen(_onScanUpdate,
          onError: (e) {
        print('Scan Error $e');
      });
    });
    */

    _onConnected(widget.kneeDeviceId, 'knee');
    _onConnected(widget.footDeviceId, 'foot');
    _onConnected(widget.hipsDeviceId, 'hips');
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
        } else if (update.connectionState ==
            DeviceConnectionState.disconnected) {
          _foundHips = false;
        }
      });
    }
  }

  Future<void> _onConnected(String deviceId, String deviceType) async {
    final characteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse('0000ABF2-0000-1000-8000-00805F9B34FB'),
        serviceId: Uuid.parse('0000ABF0-0000-1000-8000-00805F9B34FB'),
        deviceId: deviceId);

    try {
      final mtu = await _ble.requestMtu(deviceId: deviceId, mtu: 23);
      print('MTU negotiated: $mtu');
    } catch (e) {
      print('Failed to negotiate MTU: $e');
    }

    if (deviceType == 'knee') {
      _notifySubKnee =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes1) {
        setState(() {
          kneeData = bytes1;
          if (_isRunning &
              kneeData.isNotEmpty &
              footData.isNotEmpty &
              hipsData.isNotEmpty) {
            rawKneeData.add({'data': bytes1, 'timestamp': DateTime.now()});

            //print('Knee: $bytes1');
          }

          /*
          
          kneejson = callbackUnpackK(bytes1, deviceType);
          //print('Kneejson: $kneejson');

          if (_isRunning == true &&
              footjson.isNotEmpty &&
              hipsjson.isNotEmpty) {
            List<double> kneeProx = kneejson['prox'];
            //List<double> kneeDist = kneejson['dist'];
            kneeProx.forEach(
              (knee_val) {
                Map<String, dynamic> kneePoint = {
                  'timestamp': DateTime.now(),
                  'data': knee_val,
                };
                _timeKnee.add(kneePoint);
                //print(kneePoint);
                /*
                _kneedataPoints
                    .add(FlSpot(_kneedataPoints.length.toDouble(), knee_val));
                    */
              },
            );
          }
          */
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
            rawFootData.add({
              'data': bytes2,
              'timestamp': DateTime.now(),
              'knee': kneeData,
            });
            //print('Foot: $bytes2');
            //print(rawFootData.last);
          }

          /*
          footjson = callbackUnpackF(bytes2, deviceType);
          //print(footjson);

          //print(kneejson['distal']);
          //print("foot: $footjson");
          if (_isRunning == true &&
              kneejson.isNotEmpty &&
              hipsjson.isNotEmpty) {
            List<double> footProx = footjson['prox'];
            //List<double> footDist = kneejson['dist'];
            footState = footjson['state'];

            footProx.forEach(
              (footval) {
                Map<String, dynamic> footPoint = {
                  'timestamp': DateTime.now(),
                  'data': footval,
                };
                _timeFoot.add(footPoint);
                //print(footPoint);
                /*
                _footdataPoints
                    .add(FlSpot(_footdataPoints.length.toDouble(), (footval)));
                    */
              },
            );
          }
          */
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
            rawHipsData.add({
              'data': bytes3,
              'timestamp': DateTime.now(),
              'knee': kneeData,
            });

            //print(rawHipsData.last);

            //print('Hips: $bytes3');
            //print('Hips: ${bytes3.length}');
          }

          /*
          hipsjson = callbackUnpackH(bytes3, deviceType);
          //final timestamphips = DateTime.now();

          if (_isRunning == true &&
              footjson.isNotEmpty &&
              kneejson.isNotEmpty) {
            List<double> hipsProx = hipsjson['prox'];
            //List<double> hipsDist = kneejson['prox'];

            hipsProx.forEach(
              (hipsval) {
                Map<String, dynamic> hipsPoint = {
                  'timestamp': DateTime.now(),
                  'data': hipsval,
                };
                _timeHips.add(hipsPoint);
                //print(hipsPoint);
                /*
                _hipsdataPoints
                    .add(FlSpot(_hipsdataPoints.length.toDouble(), hipsval));
                    */
              },
            );
          }
          */
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
      //final first_foot = _timeFoot[0];
      //final first_knee = _timeKnee[0];
      //final first_hips = _timeHips[0];

      //final delay_hips = first_hips['timestamp'].millisecondsSinceEpoch -
      // first_knee['timestamp'].millisecondsSinceEpoch;

      // final delay_foot = first_foot['timestamp'].millisecondsSinceEpoch -
      // first_knee['timestamp'].millisecondsSinceEpoch;
      /*
      for (var b in rawKneeData) {
        kneejson = callbackUnpackK(b, 'knee');
        if (kneejson.isNotEmpty) {
          List<double> kneeProx = kneejson['prox'];
          for (var knee_val in kneeProx) {
            Map<String, dynamic> kneePoint = {
              'timestamp': DateTime.now(),
              'data': knee_val,
            };
            _timeKnee.add(kneePoint);
          }
        }
        */
      //removing duplicate data points
      /*
      var meta_count_knee = 0;
      var knee_count = 0;
      var current_count_knee = 0;
      var one_ctr_knee = 0;
      for (var b in rawKneeData) {
        DateTime timestamp_knee = b['timestamp'];
        List<int> data_knee = b['data'];
        kneejson = callbackUnpackK(data_knee, 'knee');
        //print('knee: $kneejson');
        if (kneejson.isNotEmpty) {
          if (one_ctr_knee == 0) {
            knee_count = kneejson['counter'];
            one_ctr_knee = 1;
          }
          current_count_knee = kneejson['counter'];
          if (current_count_knee == knee_count) {
            knee_count = current_count_knee;
            if (meta_count_knee >= 3) {
              meta_count_knee = 0;
              List<double> kneeProx = kneejson['prox'];
              for (var knee_val in kneeProx) {
                Map<String, dynamic> kneePoint = {
                  'timestamp': timestamp_knee,
                  'data': knee_val,
                };
                //print(kneePoint);
                //print(meta_count_knee);
                _timeKnee.add(kneePoint);
              }
            }
            meta_count_knee += 1;
          } else {
            knee_count = current_count_knee;
          }
        }
      }

      // Process raw data for foot
      var foot_count = 0;
      var meta_count_foot = 0;
      var current_count_foot = 0;
      var one_ctr_foot = 0;
      for (var a in rawFootData) {
        DateTime timestamp_foot = a['timestamp'];
        List<int> data_foot = a['data'];
        footjson = callbackUnpackF(data_foot, 'foot');
        // List<double> footState = footjson['state'];
        //print('foot: $footjson');
        if (footjson.isNotEmpty) {
          if (one_ctr_foot == 0) {
            foot_count = footjson['counter'];
            one_ctr_foot = 1;
          }
          current_count_foot = footjson['counter'];
          if (current_count_foot == foot_count) {
            foot_count = current_count_foot;
            if (meta_count_foot >= 3) {
              meta_count_foot = 0;
              List<double> footProx = footjson['prox'];
              //print('foot: $footProx');
              for (var foot_val in footProx) {
                Map<String, dynamic> footPoint = {
                  'timestamp': timestamp_foot,
                  'data': foot_val,
                };
                print('foot: $foot_val');
                _timeFoot.add(footPoint);
              }
            }
            meta_count_foot += 1;
          } else {
            foot_count = current_count_foot;
          }
        }
      }
      */
      //print('hello');

      // Process raw data for hips
      for (var c in rawHipsData) {
        hipsjson = callbackUnpackHB(c['data'], 'hips');
        //print('hipsjson: $hipsjson');
        Map<String, dynamic> kneeHipDist = callbackUnpackK(c['knee'], 'knee');
        //print('kneeHipDist: $kneeHipDist');
        //print('hips: $hipsjson');
        if (hipsjson.isNotEmpty && kneeHipDist.isNotEmpty) {
          var hipsProx = hipsProxraw(hipsjson['prox']) - widget.hipsProxCalib;
          //print('hipsProx: $hipsProx');
          //hipsprox is hips device and the distal is knee prox
          var hipsDist =
              kneeDistraw(kneeHipDist['prox']) - widget.kneeProxCalib;
          Map<String, dynamic> hipsPoint = {
            'timestamp': c['timestamp'],
            'prox': hipsProx,
            'dist': hipsDist,
            'angle': hipsProx - hipsDist,
          };
          _unpackHips.add(hipsPoint);
          //print('hips: $hipsPoint');
        }
      }

      for (var b in rawKneeData) {
        kneejson = callbackUnpackK(b['data'], 'knee');
        if (kneejson.isNotEmpty) {
          var kneeProx = kneeProxraw(kneejson['prox']) - widget.kneeProxCalib;
          var kneeDist = kneeDistraw(kneejson['dist']) - widget.kneeDistCalib;
          //var kneeDist = kneejson['dist'];
          //var kneeProx = kneejson['prox'];

          Map<String, dynamic> kneePoint = {
            'timestamp': b['timestamp'],
            'prox': kneeProx,
            'dist': kneeDist,
            'angle': kneeDist - kneeProx,
          };
          _unpackKnee.add(kneePoint);
          //print('knee: $kneePoint');
        }
      }

      for (var a in rawFootData) {
        footjson = callbackUnpackF(a['data'], 'foot');
        Map<String, dynamic> footKneeDist = callbackUnpackK(a['knee'], 'knee');
        if (footjson.isNotEmpty && footKneeDist.isNotEmpty) {
          var footProx = footProxraw(footjson['prox']) - widget.footProxCalib;
          var footDist =
              kneeDistraw(footKneeDist['dist']) - widget.kneeDistCalib;
          footState = footjson['state'];
          footStateList.add(footState);
          Map<String, dynamic> footPoint = {
            'timestamp': a['timestamp'],
            'state': footState,
            'prox': footProx,
            'dist': footDist,
            'angle': ((footProx + 90) - footDist) - 180,
          };
          //print('foot: $footProx');
          _unpackFoot.add(footPoint);
          //print('foot: $footPoint');
        }
      }
      /*
      for (var c in rawHipsData) {
        hipsjson = callbackUnpackH(c, 'hips');
        if (hipsjson.isNotEmpty) {
          var hipsProx = hipsjson['prox'];
          Map<String, dynamic> hipsPoint = {
            'timestamp': DateTime.now(),
            'data': hipsProx,
          };
          _timeHips.add(hipsPoint);
        }
      }
      */

      // Clear the buffers after processing
      rawKneeData.clear();
      rawFootData.clear();
      rawHipsData.clear();

/*
      if (_timeKnee.isNotEmpty) {
        final firstKneeTimestamp =
            _timeKnee.first['timestamp'].millisecondsSinceEpoch;
        _kneedataPoints = _timeKnee
            .map((point) => FlSpot(
                  (point['timestamp'].millisecondsSinceEpoch -
                          firstKneeTimestamp)
                      .toDouble(),
                  point['data'],
                ))
            .toList();
        //print('knee: $_kneedataPoints');
      }

      if (_timeFoot.isNotEmpty) {
        final firstFootTimestamp =
            _timeFoot.first['timestamp'].millisecondsSinceEpoch;
        _footdataPoints = _timeFoot
            .map((point) => FlSpot(
                  (point['timestamp'].millisecondsSinceEpoch -
                          firstFootTimestamp)
                      .toDouble(),
                  point['data'],
                ))
            .toList();
        //print('foot: $_footdataPoints');
      }
      if (_timeHips.isNotEmpty) {
        final firstHipsTimestamp =
            _timeHips.first['timestamp'].millisecondsSinceEpoch;
        _hipsdataPoints = _timeHips
            .map((point) => FlSpot(
                  (point['timestamp'].millisecondsSinceEpoch -
                          firstHipsTimestamp)
                      .toDouble(),
                  point['data'],
                ))
            .toList();
        print('hips: $_hipsdataPoints');
      }
*/

// heelstrike detection
      //int heelstrikeIndex = possibleHeelstrike(footState, _listFootTime);

      _kneedataPoints = _unpackKnee
          .map((point) => FlSpot(
                //point['timestamp'].millisecondsSinceEpoch.toDouble(),
                _unpackKnee.indexOf(point).toDouble(),
                point['angle'],
              ))
          .toList();
      _footdataPoints = _unpackFoot
          .map((point) => FlSpot(
                //point['timestamp'].millisecondsSinceEpoch.toDouble(),
                _unpackFoot.indexOf(point).toDouble(),
                point['angle'],
              ))
          .toList();

      _hipsdataPoints = _unpackHips
          .map((point) => FlSpot(
                _unpackHips.indexOf(point).toDouble(),
                //point['timestamp'].millisecondsSinceEpoch.toDouble(),
                point['angle'],
              ))
          .toList();
      //print('hips: $_hipsdataPoints');
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
                        //isCurved: true,
                        isCurved: false,
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
                        //isCurved: true,
                        isCurved: false,
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
                        //isCurved: true,
                        isCurved: false,
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
            heroTag: 'start1',
            onPressed: _isRunning ? null : _startGeneratingData,
            child: const Text('Start'),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            heroTag: 'stop1',
            onPressed: _isRunning ? _stopGeneratingData : null,
            child: const Text('Stop'),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}
