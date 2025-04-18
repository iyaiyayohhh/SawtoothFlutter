/*

import 'dart:typed_data';
import 'globals.dart' as globals;

Map<String, dynamic> jsonData = {};
Map<String, dynamic> kneejsonData = {};
Map<String, dynamic> hipsjsonData = {};
Map<String, dynamic> footjsonData = {};
Map<String, dynamic> errorData = {'data': 'error'};

var jdataStates = [0, 0, 0, 0];
var footjdatadist = [0.0, 0.0, 0.0, 0.0];
var footjdataprox = [0.0, 0.0, 0.0, 0.0];
var kneejdatadist = [0.0, 0.0, 0.0, 0.0];
var kneejdataprox = [0.0, 0.0, 0.0, 0.0];
var hipsjdatadist = [0.0, 0.0, 0.0, 0.0];
var hipsjdataprox = [0.0, 0.0, 0.0, 0.0];

double pgyroA = 0.0;
double paccelA = 0.0;
double dgyroA = 0.0;
double daccelA = 0.0;

//Complimentary Filter na Normal

class ComplimentaryFilter {
  double angle = 0.0;
  double previousGyroAngle = 0.0;
  double dt = 0.0;

  ComplimentaryFilter();

  // Update method to fuse accelerometer and gyroscope data
  double update(double accelAngle, double gyroRate) {
    // The gyroscope integration
    double gyroAngle = previousGyroAngle + gyroRate * dt;

    // Complimentary filter formula
    angle = 0.98 * gyroAngle + 0.02 * accelAngle;

    // Update previous gyro angle
    previousGyroAngle = gyroAngle;

    return angle;
  }
}

// Complimentary Filters by Sir Ron
double ans = 0.0;
double alpha_1 = 0.03;
double alpha_2 = 1 - alpha_1;
double beta_1 = 0.02;
double beta_2 = 1 - beta_1;

double XComFitA(double previousGyroAngle, double gyro, double accel) {
  ans = ((previousGyroAngle + gyro) * alpha_1) + (accel * alpha_2);
  return ans;
}

double XComFitB(double previousGyroAngle, double gyro, double accel) {
  ans = ((previousGyroAngle + gyro) * beta_1) + (accel * beta_2);
  return ans;
}

double ComFitA(double gyro, double accel) {
  ans = ((gyro + accel) * alpha_1) + (accel * alpha_2);
  return ans;
}

double ComFitB(double gyro, double accel) {
  ans = ((accel + gyro) * beta_1) + (accel * beta_2);
  return ans;
}

//struct unpack function
int unpack(List<int> binaryData) {
  //print("binary data: $binaryData");
  dynamic byteList = Uint8List.fromList(binaryData);
  //print("byteList: $byteList");
  ByteData byteData = ByteData.sublistView(byteList);
  //print("byteData: $byteData");
  int shortVal = byteData.getInt16(0, Endian.little);
  //print("devtype:" + globals.devtype + " shortVal: $shortVal");
  return shortVal;
}

void incrementIndx() {
  globals.indx++;
}

void incrementCounter() {
  globals.counterx++;
}

Map<String, dynamic> callbackUnpack(List<int> datax, devtype) {
  if (datax.length == 10) {
    List<int> data = [0, 0, 0, 0];
    data = datax;
    //print("data: $data");
    pgyroA = 0.0;
    paccelA = 0.0;
    dgyroA = 0.0;
    daccelA = 0.0;

    //extend data
    //print("data = $datax");
    Uint8List newdata = Uint8List(data.length + 1);
    for (int i = 0; i < data.length; i++) {
      newdata[i] = data[i];
    }
    newdata[data.length] = 0x00;
    //print("new data = $newdata");
    if (String.fromCharCode(datax[0]) == 'a') {
      //print("after if data[0] = a");
      var val = data.sublist(2, 4);
      //print("Val: $val");
      pgyroA = unpack(val) / 10.0;
      //print("after pgyro unpack");
      val = data.sublist(4, 6);
      paccelA = 90.0 + (unpack(val) / 10.0);
      //print("after paccelA unpack");
      val = data.sublist(6, 8);
      dgyroA = unpack(val) / 10.0;
      //print("after dgryo unpack");
      val = data.sublist(8, 10);
      daccelA = 90.0 + (unpack(val) / 10.0);
      //print("after if daccelunpack");
      //+360 for all positive data
      //print("pgyroA: $pgyroA");
      //print("dgyroA: $dgyroA");
      if (paccelA < 0) {
        paccelA += 360;
      }
      if (daccelA < 0) {
        daccelA += 360;
      }
      //print("before if globals.devtype");

      // Implement data unpacking logic
      if (devtype == 'foot') {
        //filter foot data
        footjdataprox[globals.indx] = ComFitA(pgyroA, paccelA);
        jdataStates[globals.indx] = datax[1];
        //print("foot prox: $footjdataprox and foot dist  $footjdatadist");
      } else if (devtype == 'knee') {
        //filter knee data
        //print("new data = $newdata");
        kneejdataprox[globals.indx] =
            XComFitA(kneejdataprox[globals.indx], pgyroA, paccelA);
        kneejdatadist[globals.indx] =
            XComFitA(kneejdatadist[globals.indx], dgyroA, daccelA);
        //print("knee prox: $kneejdataprox and knee dist = $kneejdatadist");
      } else if (devtype == 'hips') {
        //filter hips data
        hipsjdataprox[globals.indx] = ComFitA(pgyroA, paccelA);
      }
      globals.indx += 1;
      if (globals.indx >= 4 && devtype == 'foot') {
        footjsonData["counter"] = globals.counterx;
        footjsonData["state"] = jdataStates;
        footjsonData["prox"] = footjdataprox;
        footjsonData["dist"] = footjdatadist;
        globals.indx = 0;
        globals.counterx++;
        //print("$devtype jsonData: $footjsonData");
      }
      if (globals.indx >= 4 && devtype == 'knee') {
        kneejsonData["counter"] = globals.counterx;
        kneejsonData["state"] = jdataStates;
        kneejsonData["prox"] = kneejdataprox;
        kneejsonData["dist"] = kneejdatadist;
        globals.indx = 0;
        globals.counterx++;
        //print("$devtype jsonData: $kneejsonData");
      }
      if (globals.indx >= 4 && devtype == 'hips') {
        hipsjsonData["counter"] = globals.counterx;
        hipsjsonData["state"] = jdataStates;
        hipsjsonData["prox"] = hipsjdataprox;
        hipsjsonData["dist"] = hipsjdatadist;
        globals.indx = 0;
        globals.counterx++;
        //print("$devtype jsonData: $hipsjsonData");
      }
    } else {
      print('Invalid data');
    }
  }

  if (devtype == 'knee') {
    return kneejsonData;
  } else if (devtype == 'foot') {
    //print('foot: $footjdataprox');
    return footjsonData;
  } else if (devtype == 'hips') {
    //print('hips: $hipsjdataprox');
    return hipsjsonData;
  } else {
    return errorData; // Return an empty list if devtype is invalid
  }
}


*/
