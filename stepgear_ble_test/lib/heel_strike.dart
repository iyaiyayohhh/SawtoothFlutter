int possibleHeelstrike(List<int> footStates) {
  int firstIndex = -1; // To track the first index of 1 before the pattern

  for (int i = 5; i < footStates.length; i++) {
    // Check if the current value is 1 and the previous 4 footStates are all 0
    if (footStates[i] == 1 &&
        footStates[i - 1] == 0 &&
        footStates[i - 2] == 0 &&
        footStates[i - 3] == 0 &&
        footStates[i - 4] == 0) {
      // Ensure this is not the first index of 1
      if (firstIndex != -1) {
        return i; // Return the index of the valid 1
      }
    }

    // Track the first index of 1
    if (footStates[i] == 1 && firstIndex == -1) {
      firstIndex = i;
    }
  }

  return -1; // Return -1 if no such pattern is found
}
