#include "parselib.h"

int main(){
    struct pnode A,B,C;
    A.prodrule = 10;
    B.prodrule = 12;
    C.prodrule = 11;
    alcnode(1,3,&A,&C,&B);
    return 0;
}
