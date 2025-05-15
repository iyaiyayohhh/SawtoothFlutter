/*
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

class GaitCSV extends StatelessWidget {
  const GaitCSV({super.key});

  @override
  Widget build(BuildContext context) {
    return const GaitCSVScreen();
  }
}

class GaitCSVScreen extends StatefulWidget {
  const GaitCSVScreen({super.key});

  @override
  State<GaitCSVScreen> createState() => _GaitCSVScreenState();
}

class _GaitCSVScreenState extends State<GaitCSVScreen> {
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

  List<Map<String, dynamic>> timeKnee = [];
  List<Map<String, dynamic>> timeHips = [];
  List<Map<String, dynamic>> timeFoot = [];

  List<Map<String, dynamic>> unpackKnee = [];
  List<Map<String, dynamic>> unpackHips = [];
  List<Map<String, dynamic>> unpackFoot = [];

  List<FlSpot> _kneedataPoints = [];
  List<FlSpot> _footdataPoints = [];
  List<FlSpot> _hipsdataPoints = [];

  List<Map<String, dynamic>> rawKneeData = [];
  List<Map<String, dynamic>> rawFootData = [];
  List<Map<String, dynamic>> rawHipsData = [];

  List<List<String>> kneelistOfLists = [];
  List<List<String>> footlistOfLists = [];
  List<List<String>> hipslistOfLists = [];

  List<List<String>> listOfLists = [];

  List<String> data1 = [];
  List<String> data2 = [];
  List<String> data3 = [];
  List<String> data4 = [];

  List<String> header = [
    'knee time',
    'state',
    'prox',
    'dist',
    'computed angle',
    'foot time',
    'state',
    'prox',
    'dist',
    'computed angle',
    'hips time',
    'state',
    'prox',
    'dist',
    'computed angle'
  ];

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
        } else if (update.connectionState ==
            DeviceConnectionState.disconnected) {
          _foundKnee = false;
        }
      });
    } else if (device.name == 'FOOTSPP_SERVER' && !_foundFoot) {
      _foundFoot = true;
      _connectSubFoot = _ble.connectToDevice(id: device.id).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          _OnConnected(device.id, 'foot');
        } else if (update.connectionState ==
            DeviceConnectionState.disconnected) {
          _foundFoot = false;
        }
      });
    } else if (device.name == 'HIPSSPP_SERVER' && !_foundHips) {
      _foundHips = true;
      _connectSubHips = _ble.connectToDevice(id: device.id).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          _OnConnected(device.id, 'hips');
        } else if (update.connectionState ==
            DeviceConnectionState.disconnected) {
          _foundHips = false;
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
          if (_foundKnee & _foundFoot & _foundHips) {
            rawKneeData.add({'data': bytes1, 'timestamp': DateTime.now()});
            //print('Knee: $bytes1');
          }

          /*
          
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
                timeKnee.add(knee_point);
                //print(knee_point);
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
          if (_foundKnee & _foundFoot & _foundHips) {
            rawFootData.add({'data': bytes2, 'timestamp': DateTime.now()});
            //print('Foot: $bytes2');
          }

          /*
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
                timeFoot.add(foot_point);
                //print(foot_point);
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
          if (_foundFoot & _foundKnee & _foundHips) {
            rawHipsData.add({'data': bytes3, 'timestamp': DateTime.now()});
            //print('Hips: $bytes3');
            //print('Hips: ${bytes3.length}');
          }

          /*
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
                timeHips.add(hips_point);
                //print(hips_point);
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
      //final first_foot = timeFoot[0];
      //final first_knee = timeKnee[0];
      //final first_hips = timeHips[0];

      //final delay_hips = first_hips['timestamp'].millisecondsSinceEpoch -
      // first_knee['timestamp'].millisecondsSinceEpoch;

      // final delay_foot = first_foot['timestamp'].millisecondsSinceEpoch -
      // first_knee['timestamp'].millisecondsSinceEpoch;
      /*
      for (var b in rawKneeData) {
        kneejson = callbackUnpackK(b, 'knee');
        if (kneejson.isNotEmpty) {
          List<double> knee_prox = kneejson['prox'];
          for (var knee_val in knee_prox) {
            Map<String, dynamic> knee_point = {
              'timestamp': DateTime.now(),
              'data': knee_val,
            };
            timeKnee.add(knee_point);
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
              List<double> knee_prox = kneejson['prox'];
              for (var knee_val in knee_prox) {
                Map<String, dynamic> knee_point = {
                  'timestamp': timestamp_knee,
                  'data': knee_val,
                };
                //print(knee_point);
                //print(meta_count_knee);
                timeKnee.add(knee_point);
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
        // List<double> foot_state = footjson['state'];
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
              List<double> foot_prox = footjson['prox'];
              //print('foot: $foot_prox');
              for (var foot_val in foot_prox) {
                Map<String, dynamic> foot_point = {
                  'timestamp': timestamp_foot,
                  'data': foot_val,
                };
                print('foot: $foot_val');
                timeFoot.add(foot_point);
              }
            }
            meta_count_foot += 1;
          } else {
            foot_count = current_count_foot;
          }
        }
      }
      */

      // Process raw data for hips
      for (var c in rawHipsData) {
        hipsjson = callbackUnpackHB(c['data'], 'hips');
        //print('hips: $hipsjson');
        if (hipsjson.isNotEmpty) {
          var hips_prox = hipsjson['prox'];
          var hips_dist = hipsjson['dist'];
          Map<String, dynamic> hips_point = {
            'timestamp': c['timestamp'],
            'prox': hips_prox,
            'dist': hips_dist,
          };
          unpackHips.add(hips_point);
        }
      }

      for (var b in rawKneeData) {
        kneejson = callbackUnpackK(b['data'], 'knee');
        if (kneejson.isNotEmpty) {
          var knee_prox = kneejson['prox'];
          var knee_dist = kneejson['dist'];
          Map<String, dynamic> knee_point = {
            'timestamp': b['timestamp'],
            'prox': knee_prox,
            'dist': knee_dist,
          };
          unpackKnee.add(knee_point);
        }
      }

      for (var a in rawFootData) {
        footjson = callbackUnpackF(a['data'], 'foot');
        if (footjson.isNotEmpty) {
          var foot_prox = footjson['prox'];
          var foot_dist = footjson['dist'];
          foot_state = footjson['state'];
          Map<String, dynamic> foot_point = {
            'timestamp': a['timestamp'],
            'state': foot_state,
            'prox': foot_prox,
            'dist': foot_dist,
          };
          unpackFoot.add(foot_point);
        }
      }
      /*
      for (var c in rawHipsData) {
        hipsjson = callbackUnpackH(c, 'hips');
        if (hipsjson.isNotEmpty) {
          var hips_prox = hipsjson['prox'];
          Map<String, dynamic> hips_point = {
            'timestamp': DateTime.now(),
            'data': hips_prox,
          };
          timeHips.add(hips_point);
        }
      }
      */

      // Clear the buffers after processing
      rawKneeData.clear();
      rawFootData.clear();
      rawHipsData.clear();
/*
      if (timeKnee.isNotEmpty) {
        final firstKneeTimestamp =
            timeKnee.first['timestamp'].millisecondsSinceEpoch;
        _kneedataPoints = timeKnee
            .map((point) => FlSpot(
                  (point['timestamp'].millisecondsSinceEpoch -
                          firstKneeTimestamp)
                      .toDouble(),
                  point['data'],
                ))
            .toList();
        //print('knee: $_kneedataPoints');
      }

      if (timeFoot.isNotEmpty) {
        final firstFootTimestamp =
            timeFoot.first['timestamp'].millisecondsSinceEpoch;
        _footdataPoints = timeFoot
            .map((point) => FlSpot(
                  (point['timestamp'].millisecondsSinceEpoch -
                          firstFootTimestamp)
                      .toDouble(),
                  point['data'],
                ))
            .toList();
        //print('foot: $_footdataPoints');
      }
      if (timeHips.isNotEmpty) {
        final firstHipsTimestamp =
            timeHips.first['timestamp'].millisecondsSinceEpoch;
        _hipsdataPoints = timeHips
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

      _kneedataPoints = timeKnee
          .map((point) => FlSpot(
                //point['timestamp'].millisecondsSinceEpoch.toDouble(),
                timeKnee.indexOf(point).toDouble(),
                point['data'],
              ))
          .toList();
      _footdataPoints = timeFoot
          .map((point) => FlSpot(
                //point['timestamp'].millisecondsSinceEpoch.toDouble(),
                timeFoot.indexOf(point).toDouble(),
                point['data'],
              ))
          .toList();

      _hipsdataPoints = timeHips
          .map((point) => FlSpot(
                timeHips.indexOf(point).toDouble(),
                //point['timestamp'].millisecondsSinceEpoch.toDouble(),
                point['data'],
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
*/
