#include <iostream>

using namespace std;

class Foo {
    int width;
};

int main(int argc, char **argv)
{
    {
	Foo bar;
	int x;
    }
    char y;
    cout << "Foobar" << endl;
    return 0;
}