#ifndef parselib
#define parselib

#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>

struct pnode {
    int prodrule;
    int nkids;
    struct pnode **kids;
    struct token *leaf;
};

struct pnode *alcnode(int rule, int kids, ...);

enum {
    TYPEDEF_NAME_1
};

#endif
