#include "bits/stdc++.h"

using namespace std;

vector<string> splitString(string line, char c) {

    stringstream ss(line);
    vector<string> splits;
    string intermediate;
    while(getline(ss, intermediate, c)) {
        splits.push_back(intermediate);
    }
    return splits;
}