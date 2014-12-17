int *foo(int **x[]);

int main() {
    return foo(8);
}

int *foo(int **x[]) {
    return (int *)x;
}
