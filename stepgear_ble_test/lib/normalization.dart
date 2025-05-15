/*
import 'package:scidart/numdart.dart';
import 'package:equations/equations.dart';

//Cut Angle Data by Heelstrike
List<double> cutAngleData(
    List<double> angleData, int startIndex, int endIndex) {
  if (startIndex < 0 || endIndex >= angleData.length || startIndex > endIndex) {
    throw ArgumentError('Invalid start or end index');
  }
  return angleData.sublist(startIndex, endIndex + 1);
}

// Interpolate Cycle Data

Array interpolateCycle(Array cycle, int targetLength) {
  final xOriginal = List.generate(cycle.length, (i) => i.toDouble());
  final xNew = linspace(0, cycle.length - 1, num: targetLength);

  final nodes = List.generate(
    cycle.length,
    (i) => InterpolationNode(x: xOriginal[i], y: cycle[i]),
  );

  final interpolator = LinearInterpolation(nodes: nodes);

  final yNew = xNew.map((xi) => interpolator.compute(xi)).toList();

  return Array(yNew);
}

List<Array> normalizeCycles(List<Array> cycles, int targetLength) {
  return cycles.map((cycle) => interpolateCycle(cycle, targetLength)).toList();
}

int targetLength = 100;
List<Array> normKneeCycles = normalizeCycles(kneeCycles, targetLength);
List<Array> normHipCycles = normalizeCycles(hipCycles, targetLength);
List<Array> normAnkleCycles = normalizeCycles(ankleCycles, targetLength);

Array computeMeanCycle(List<Array> cycles) {
  int length = cycles[0].length;
  Array meanCycle = Array.fixed(length, initialValue: 0.0);
  for (var cycle in cycles) {
    meanCycle += cycle;
  }
  meanCycle /= cycles.length.toDouble();
  return meanCycle;
}

Array meanKneeCycle = computeMeanCycle(normKneeCycles);
Array meanHipCycle = computeMeanCycle(normHipCycles);
Array meanAnkleCycle = computeMeanCycle(normAnkleCycles);

*/