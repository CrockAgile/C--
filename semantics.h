#ifndef SEMANTICS_H
#define	SEMANTICS_H

#include "parse.h"

enum SemanticNodes {
    // nodes that require scope actions
    class_specifier = 950,
    compound_statement = 510,
    selection_statement = 530,
    iteration_statement = 550,
};

void TreeScan(struct pnode*);
void preorder_semantics();
void postorder_semantics();

#endif	

