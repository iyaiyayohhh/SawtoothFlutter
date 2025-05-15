//working sawtooth code
import 'dart:typed_data';

//import 'globals.dart' as globals;

var notify_uuid = '0000ABF2-0000-1000-8000-00805F9B34FB';
var service_uuid = '0000ABF0-0000-1000-8000-00805F9B34FB';

Map<String, dynamic> jsonData = {};
Map<String, dynamic> kneejsonData = {};
Map<String, dynamic> hipsjsonData = {};
Map<String, dynamic> footjsonData = {};
Map<String, dynamic> errorData = {'data': 'error'};

var indxH = 0;
var indxF = 0;
var indxK = 0;
var Hindx = 0; //outside the unpack loop
var Findx = 0; //outside the unpack loop
var Kindx = 0; //outside the unpack loop
var counterh = 0;
var counterf = 0;
var counterk = 0;

var jdataStates = [0, 0, 0, 0];
var footjdatadist = [0.0, 0.0, 0.0, 0.0];
var footjdataprox = 0.0;
var kneejdatadist = [0.0, 0.0, 0.0, 0.0];
var kneejdataprox = 0.0;
var hipsjdatadist = [0.0, 0.0, 0.0, 0.0];
var hipsjdataprox = 0.0;

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

void incrementIndx(d) {
  if (d == "hips") {
    indxH++;
    Hindx++;
  }
  if (d == "foot") {
    indxF++;
    Findx++;
  }
  if (d == "knee") {
    indxK++;
    Kindx++;
  }
}

void incrementCounter(d) {
  if (d == "hips") {
    counterh++;
  }
  if (d == "foot") {
    counterf++;
  }
  if (d == "knee") {
    counterk++;
  }
}

/*
Map<String, dynamic> callbackUnpackH(List<int> datax, devtype) {
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

      //comment out for sawtooth

      // if (paccelA < 0) {
      //   paccelA += 360;
      // }
      // if (daccelA < 0) {
      //   daccelA += 360;
      // }

      paccelA = 0.0;

      //print("before if globals.devtype");

      // Implement data unpacking logic
      if (devtype == 'hips') {
        //filter hips data
        //hipsjdataprox[globals.indx] = ComFitA(pgyroA, paccelA);
        hipsjdataprox[indxH] = pgyroA;
      }

      incrementIndx(devtype);
      if (indxH >= 4 && devtype == 'hips') {
        indxH = 0;
        hipsjsonData["counter"] = counterh;
        hipsjsonData["state"] = jdataStates;
        //hipsjsonData["prox"] = hipsjdataprox;
        hipsjsonData["prox"] = hipsjdataprox;
        hipsjsonData["dist"] = hipsjdatadist;
        counterh++;
        //print("$devtype jsonData: $hipsjsonData");
      }
    } //else {
    //print('Invalid data');
    //}
  }
  if (devtype == 'hips' && Hindx >= 4) {
    //print('hips: $hipsjsonData');
    Hindx = 0;
    return hipsjsonData;
  } else {
    return {
      "prox": hipsjdataprox, // Default to the current state of kneejdataprox
      "dist": hipsjdatadist, // Default to the current state of kneejdatadist
      "state": jdataStates,
      "counter": counterh,
    }; // Return an empty list if devtype is invalid
  }
}
*/
Map<String, dynamic> callbackUnpackHB(List<int> datax, devtype) {
  if (datax.length == 10) {
    List<int> data = datax;
    pgyroA = 0.0;
    paccelA = 0.0;
    dgyroA = 0.0;
    daccelA = 0.0;

    Uint8List newdata = Uint8List(data.length + 1);
    for (int i = 0; i < data.length; i++) {
      newdata[i] = data[i];
    }
    newdata[data.length] = 0x00;

    if (String.fromCharCode(datax[0]) == 'a') {
      var val = data.sublist(2, 4);
      pgyroA = unpack(val) / 10.0;
      val = data.sublist(4, 6);
      paccelA = 90.0 + (unpack(val) / 10.0);
      val = data.sublist(6, 8);
      dgyroA = unpack(val) / 10.0;
      val = data.sublist(8, 10);
      daccelA = 90.0 + (unpack(val) / 10.0);

      // Process hips data immediately
      if (devtype == 'hips') {
        hipsjdataprox = pgyroA; // Update the first index
        print(hipsjdataprox.runtimeType);
        hipsjdatadist[0] = XComFitA(hipsjdatadist[0], dgyroA, daccelA);

        hipsjsonData["counter"] = counterh;
        hipsjsonData["state"] = jdataStates;
        hipsjsonData["prox"] = hipsjdataprox;
        hipsjsonData["dist"] = hipsjdatadist;
        counterh++;
      }
    }
  }

  return hipsjsonData;
}

/*
Map<String, dynamic> callbackUnpackF(List<int> datax, devtype) {
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

      //comment out for sawtooth

      // if (paccelA < 0) {
      //   paccelA += 360;
      // }
      // if (daccelA < 0) {
      //   daccelA += 360;
      // }

      paccelA = 0.0;

      //print("before if globals.devtype");

      // Implement data unpacking logic
      if (devtype == 'foot') {
        //filter foot data
        //footjdataprox[globals.indx] = ComFitA(pgyroA, paccelA);
        footjdataprox[indxF] = pgyroA;
        jdataStates[indxF] = datax[1];
        //print("foot prox: $footjdataprox and foot dist  $footjdatadist");
      }

      incrementIndx(devtype);

      if (indxF >= 4 && devtype == 'foot') {
        indxF = 0;
        footjsonData["counter"] = counterf;
        footjsonData["state"] = jdataStates;
        footjsonData["prox"] = footjdataprox;
        footjsonData["dist"] = footjdatadist;
        counterf++;
        //print("$devtype jsonData: $footjsonData");
      }
    } //else {
    //print('Invalid data');
    //}
  }

  if (devtype == 'foot' && Findx >= 4) {
    //print('foot: $footjdataprox');
    Findx = 0;
    return footjsonData;
  } else {
    return {
      "prox": footjdataprox, // Default to the current state of kneejdataprox
      "dist": footjdatadist, // Default to the current state of kneejdatadist
      "state": jdataStates,
      "counter": counterf,
    }; // Return an empty list if devtype is invalid
  }
}
*/
Map<String, dynamic> callbackUnpackF(List<int> datax, devtype) {
  if (datax.length == 10) {
    List<int> data = datax;
    pgyroA = 0.0;
    paccelA = 0.0;
    dgyroA = 0.0;
    daccelA = 0.0;

    Uint8List newdata = Uint8List(data.length + 1);
    for (int i = 0; i < data.length; i++) {
      newdata[i] = data[i];
    }
    newdata[data.length] = 0x00;

    if (String.fromCharCode(datax[0]) == 'a') {
      var val = data.sublist(2, 4);
      pgyroA = unpack(val) / 10.0;
      val = data.sublist(4, 6);
      paccelA = 90.0 + (unpack(val) / 10.0);
      val = data.sublist(6, 8);
      dgyroA = unpack(val) / 10.0;
      val = data.sublist(8, 10);
      daccelA = 90.0 + (unpack(val) / 10.0);

      // Process foot data immediately
      if (devtype == 'foot') {
        footjdataprox = pgyroA; // Update the first index
        footjdatadist[0] = XComFitA(footjdatadist[0], dgyroA, daccelA);

        footjsonData["counter"] = counterf;
        footjsonData["state"] = jdataStates;
        footjsonData["prox"] = footjdataprox;
        footjsonData["dist"] = footjdatadist;
        counterf++;
      }
    }
  }

  return footjsonData;
}

/*
Map<String, dynamic> callbackUnpackK(List<int> datax, devtype) {
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

      //comment out for sawtooth

      // if (paccelA < 0) {
      //   paccelA += 360;
      // }
      // if (daccelA < 0) {
      //   daccelA += 360;
      // }

      paccelA = 0.0;

      //print("before if globals.devtype");

      // Implement data unpacking logic
      if (devtype == 'knee') {
        //filter knee data
        kneejdataprox[indxK] = pgyroA;
        kneejdatadist[indxK] = XComFitA(kneejdatadist[indxK], dgyroA, daccelA);
        //print("knee prox: $kneejdataprox and knee dist = $kneejdatadist");
      }

      incrementIndx(devtype);

      if (indxK >= 4 && devtype == 'knee') {
        indxK = 0;
        kneejsonData["counter"] = counterk;
        kneejsonData["state"] = jdataStates;
        kneejsonData["prox"] = kneejdataprox;
        kneejsonData["dist"] = kneejdatadist;
        counterk++;
        //print("$devtype jsonData: $kneejsonData");
      }
    } //else {
    //print('Invalid data');
    //}
  }

  if (devtype == 'knee' && Kindx >= 4) {
    Kindx = 0;
    return kneejsonData;
  } else {
    return {
      "prox": kneejdataprox, // Default to the current state of kneejdataprox
      "dist": kneejdatadist, // Default to the current state of kneejdatadist
      "state": jdataStates,
      "counter": counterk,
    }; // Return an empty list if devtype is invalid
  }
}
*/
Map<String, dynamic> callbackUnpackK(List<int> datax, devtype) {
  if (datax.length == 10) {
    List<int> data = datax;
    pgyroA = 0.0;
    paccelA = 0.0;
    dgyroA = 0.0;
    daccelA = 0.0;

    Uint8List newdata = Uint8List(data.length + 1);
    for (int i = 0; i < data.length; i++) {
      newdata[i] = data[i];
    }
    newdata[data.length] = 0x00;

    if (String.fromCharCode(datax[0]) == 'a') {
      var val = data.sublist(2, 4);
      pgyroA = unpack(val) / 10.0;
      val = data.sublist(4, 6);
      paccelA = 90.0 + (unpack(val) / 10.0);
      val = data.sublist(6, 8);
      dgyroA = unpack(val) / 10.0;
      val = data.sublist(8, 10);
      daccelA = 90.0 + (unpack(val) / 10.0);

      // Process knee data immediately
      if (devtype == 'knee') {
        kneejdataprox = pgyroA; // Update the first index
        kneejdatadist[0] = XComFitA(kneejdatadist[0], dgyroA, daccelA);

        kneejsonData["counter"] = counterk;
        kneejsonData["state"] = jdataStates;
        kneejsonData["prox"] = kneejdataprox;
        kneejsonData["dist"] = kneejdatadist;
        counterk++;
      }
    }
  }

  return kneejsonData;
}
