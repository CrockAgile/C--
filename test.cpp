#include <iostream>
using namespace std;

int f(int val, float t, float g, float q) {

    return 3.0;
}

int main() {
    float g, j;
    cout << "Enter a real number: ";
    cin >> g;
    cout << "f is " << f(g, j, "foo", j) << endl;
}
