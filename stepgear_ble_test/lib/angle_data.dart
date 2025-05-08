double minKnee = -10.0;
double maxKnee = 150.0;
double minFoot = -45.0;
double maxFoot = 45.0;
double minHips = -30.0;
double maxHips = 60.0;

double kneeProxraw(double proxValuesKnee) {
  if (proxValuesKnee > 180.0) {
    proxValuesKnee = proxValuesKnee - 360;
  }
  return proxValuesKnee;
}

double kneeDistraw(double distValuesKnee) {
  if (distValuesKnee > 180.0) {
    distValuesKnee = distValuesKnee - 360;
  }
  return distValuesKnee;
}

double footProxraw(double proxValuesFoot) {
  if (proxValuesFoot > 180.0) {
    proxValuesFoot = proxValuesFoot - 360;
  }
  return proxValuesFoot + 90;
}

double hipsProxraw(double proxValuesHips) {
  if (proxValuesHips > 180.0) {
    proxValuesHips = proxValuesHips - 360;
  }
  return proxValuesHips;
}

double kneeangleOffset(double proxValuesKnee, double distValuesKnee) {
  //double proxValue = 0.0;
  //double distValue = 0.0;
  //double kneeAngle = 0.0;
  if (proxValuesKnee > 180.0) {
    proxValuesKnee = proxValuesKnee - 360;
  }

  if (distValuesKnee > 180.0) {
    distValuesKnee = distValuesKnee - 360;
  }

  double diffKnee = distValuesKnee - proxValuesKnee;

  //print('prox: $proxValuesKneeKnee');
  //print('dist: $distValuesKneeKnee');
  //print('diff: $diffKneeKnee');

  return diffKnee;
}

double footangleOffset(double proxValuesFoot, double distValuesFoot) {
  if (proxValuesFoot > 180.0) {
    proxValuesFoot = proxValuesFoot - 360;
  }
  proxValuesFoot = proxValuesFoot + 90;
  if (distValuesFoot > 180.0) {
    distValuesFoot = distValuesFoot - 360;
  }
  double diffFoot = (proxValuesFoot - distValuesFoot) - 170;

  //print('prox: $proxValuesFoot');
  //print('dist: $distValuesFoot');

  return diffFoot;
}

double hipangleCalc(double proxValuesHips, double distValuesHips) {
  if (proxValuesHips > 180) {
    proxValuesHips = proxValuesHips - 360;
  }
  if (distValuesHips > 180) {
    distValuesHips = distValuesHips - 360;
  }
  double diffHips = -1 * (proxValuesHips - distValuesHips);

  return diffHips;
}
