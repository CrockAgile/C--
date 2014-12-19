#include "tac.h"
#include "parse.h"
#include "semantics.h"

void assign_sizes(struct pnode *n) {
    n->address->size = compute_size(n);

}

int compute_size(struct pnode *n) {
    if (!n) return 1;

    switch (n->type->bt) {
        case int_type:
        case bool_type:
            return 4;
            break;
        default:
            return 8;
    }
}

address* get_temp(int size) {

}

void reserve_addr(address *a, region r) {
    a->region = r;
    switch (r) {
        case GLOBAL:
            a->offset = global_offset;
            global_offset += a->size;
            break;
        case PARAM:
            a->offset = param_offset;
            param_offset += a->size;
            break;
        case LOCAL:
            a->offset = local_offset;
            local_offset += a->size;
            break;
    }
}

void code_generate(struct pnode *n) {

}

void print_op(FILE *stream, op *op) {

}

void print_code(FILE *stream, op *op) {

}

void op_append(op *src, op *des) {

}

void pre_tac(struct pnode * n, int code) {
    n->address = sem_malloc(sizeof(address),true);
    switch (code) {
        case identifier:
        case literal:
            assign_sizes(n);
            break;
    }
}

void post_tac(struct pnode * n, int code) {

}

void tac_traversal(struct pnode *n) {
    struct prodrule *curr;
    int i, nkids;
    if (!n) return;
    nkids = n->nkids;
    // prodrules are maintained in linked list
    for (curr = n->prule; curr; curr = curr->next)
        pre_tac(n, curr->code);

    for (i = 0; i < nkids; i++)
        tac_traversal(n->kids[i]);

    for (curr = n->prule; curr; curr = curr->next)
        post_tac(n, curr->code);
}