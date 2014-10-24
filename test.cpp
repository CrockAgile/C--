#include <iostream>

using namespace std;

class Foo {
private:
    int width;
public:
    bool setWidth(int width);
};

int main(int argc, char **argv)
{
    int x = 10;
    {
	int x = 20;
    }
    return 0;
}