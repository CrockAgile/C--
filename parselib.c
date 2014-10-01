#include "parselib.h"

struct pnode *alcnode(int rule, int kids, ...) {
    va_list args;

    struct pnode* new_pnode = (struct pnode*)malloc(sizeof(struct pnode));
    if(!new_pnode)
        return NULL;

    new_pnode->prodrule = rule;
    new_pnode->nkids = kids;

    new_pnode->kids = (struct pnode**)malloc(kids * sizeof(struct pnode*));
    int x;
    va_start( args, kids );
    for ( x = 0; x < kids; x++ ) {
        new_pnode->kids[x] = va_arg(args,struct pnode*);
        printf("%d\n",new_pnode->kids[x]->prodrule);
    }
    va_end( args );

    new_pnode->leaf = NULL;
    return new_pnode;
}
