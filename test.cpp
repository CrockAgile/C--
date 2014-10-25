#include <iostream>

using namespace std;

class Foo {
private:
    int width;
public:
    bool setWidth(int width);
};

void stuff(){
    cout << "stuff here" << endl;
}

int main(int argc, char **argv)
{
    stuff();
    int x = 10;
    {
	    int x = 20;
    }
    Foo b;

    return 0;
}
