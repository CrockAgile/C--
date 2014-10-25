#include <iostream>

using namespace std;

class Foo {
private:
    int width;
public:
    bool setWidth(int width);
};

void foo(){
    cout << "foo here" << endl;
}

int main(int argc, char **argv)
{
    foo();
    int x = 10;
    {
	    int x = 20;
    }
    Foo b;

    return 0;
}
