/* semantics.c
 * jeff crocker
 */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "semantics.h"

void* sem_malloc(int size, bool zero) {
    void* new;
    zero ? (new = calloc(1, size)) : (new = malloc(size));
    if (!new) {
        fprintf(stderr, "Memory allocation failed in Semantic Analysis\n");
        exit(3);
    }
    return new;
}

/* TYPES AND ENVIRONS SECTION */

// hash with mod specific to semantic tables

unsigned long env_hash(char *s) {
    unsigned long hash = 5381;
    int c;
    while ((c = *s++))
        hash = ((hash << 5) + hash) + c;
    return hash % S_SIZE;
}

type_el* mk_type_el(btype t, type_el *s, type_el *n) {
    type_el *new = sem_malloc(sizeof (type_el), 0); // -1 indicates elems N/A
    new->bt = t;
    new->sib = s;
    new->next = n;
    new->elements = -1;
    return new;
}

// lisp flashbacks

void free_type_list(type_el* head) {
    if (!head) return;
    type_el *prev;

    while (head) {
        prev = head;
        head = head->next;
        free(prev);
    }

}

void print_type(type_el *curr, type_el *p) {
    if (!curr) return;
    switch (curr->bt) {
        case class_type:
            printf("class");
            break;
        case pointer_type:
            printf("*");
            break;
        case function_type:
            putchar('(');
            print_type_list(p, NULL);
            putchar(')');
            break;
        case array_type:
            putchar('[');
            printf("%d", curr-> elements);
            putchar(']');
            break;
        case int_type:
            printf("int");
            break;
        case void_type:
            printf("void");
            break;
        case class_instance:
            printf("class_instance");
            break;
        case char_type:
            printf("char");
            break;
        case double_type:
            printf("double");
            break;
        default:
            printf(" default %d", curr->bt);
    }
}

void print_type_list(type_el *head, type_el *params) {
    if (!head) return;
    type_el *curr;
    for (curr = head; curr; curr = curr->next)
        print_type(curr, params);

    if (head->sib) {
        putchar(',');
        print_type_list(head->sib, params);
    }
}

table_el* mk_table_el(token *t, type_el *ty, env *p, table_el *n) {
    table_el *new = sem_malloc(sizeof (table_el), 1);
    new->tok = t;
    new->type = ty;
    new->par_env = p;
    new->next = n;
    new->ch_env = NULL; // no child yet
    // other elements zeroed from calloc
    return new;
}

void free_table_list(table_el *head) {
    table_el *prev, *curr = head;
    while ((prev = curr)) {
        curr = curr->next;
        // tokens are freed in parse cleanup
        free_type_list(prev->type);
        free_type_list(prev->param_types);
    }
}

void free_types(type_el *curr) {
    if (!curr) return;
    if (curr->next) free_types(curr->next);
    if (curr->sib) free_types(curr->sib);
    free(curr);
}

env* mk_environ(env *parent, char *s, int depth) {
    env *new = sem_malloc(sizeof (env), 1);
    new->locals = sem_malloc(S_SIZE * sizeof (table_el*), 1);
    new->up = parent;
    new->ksize = ENV_KIDS;
    new->depth = depth;
    new->kids = sem_malloc(ENV_KIDS * sizeof (env*), 1);
    new->name = s;
    return new;
}

table_el* environ_lookup(env *e, char *key) {
    table_el* res = e->locals[env_hash(key)];
    while (res) {
        if (!strcmp(key, res->tok->text)) {
            return res;
        }
        res = res->next;
    }
    return NULL;
}

table_el* rec_environ_lookup(char *key) {
    env* curr = CurrEnv();
    table_el* res = NULL;
    while ((!res) && (curr)) {
        res = environ_lookup(curr, key);
        curr = curr->up;
    }
    return res;
}

env* child_env_lookup(env *e, char *key) {
    short i;
    for (i = 0; i < e->ksize; i++) {
        if (!strcmp(e->kids[i]->name, key))
            return e->kids[i];
    }
    return NULL;
}

table_el* environ_insert(env *e, token *to, type_el *ty, type_el *plist, bool c, bool d) {
    if (!to->text) return NULL;
    unsigned long index = env_hash(to->text);
    table_el** des = &(e->locals[index]);
    table_el *res = environ_lookup(e, to->text);
    table_el *new = mk_table_el(to, ty, e, *des);
    new->cons = c;
    new->defd = d;
    new->param_types = plist;
    if (res) {
        if (res->defd) {
            fprintf(stderr, "error: redefinition of %s at %s:%d\n",
                    to->text, to->filename, to->lineno);
            fprintf(stderr, "previous definition at %s:%d\n",
                    res->tok->filename, res->tok->lineno);
            exit(3);
        } else {
            if (table_type_comp(new, res)) {
                fprintf(stderr, "Overwriting %s from %d with %d\n", to->text,
                        res->tok->lineno, to->lineno);
            } else {
                fprintf(stderr, "%s:%d Definition of \"%s\" does not match prototype and 120++ does not support overloading\n",
                        to->filename, to->lineno, to->text);
                fprintf(stderr, "Previous definition located at %s:%d\n",
                        res->tok->filename, res->tok->lineno);
                exit(3);
            }

        }

    }

    *des = new;
    return new;
}

env* add_env_child(env *parent, char *n) {
    short nkids = parent->nkids;
    env *new;
    if (!parent) return NULL;

    if (nkids == parent->ksize) {// at max capacity
        printf("growing child array\n");
        parent->kids = realloc(parent->kids, nkids * 2 * sizeof (env*));
        if (!parent->kids) exit(3);
        parent->ksize = 2 * nkids; // update with new sizes
    }
    new = mk_environ(parent, n, parent->depth + 1);
    parent->kids[parent->nkids++] = new;
    return new;
}

void free_environ(env *target) {
    if (sem_cleanup) { // artificial semantics need cleanup
        sem_cleanup = 0;
        env *gl = GetGlobal();
        token *t;
        t = environ_lookup(gl, "cin") -> tok;
        free(t);
        t = environ_lookup(gl, "cout") -> tok;
        free(t);
        t = environ_lookup(gl, "endl") -> tok;
        free(t);
        t = environ_lookup(gl, "string") -> tok;
        free(t);
        t = environ_lookup(gl, "fstream") -> tok;
        free(t);
    }
    if (!target) return;
    int i;
    short nkids;
    env *child;
    table_el *l;
    for (i = 0; i < S_SIZE; i++) {
        l = target->locals[i];
        if (l) {
            free_types(l->type);
            free_types(l->param_types);
        }
    }
    // dont free parent, handled in tree traversal
    nkids = target->nkids; // save for future compares
    for (i = 0; i <= nkids; i++) {
        child = target->kids[i];
        if (child) {
            free_environ(child);
        }
    }
    // now that all occupied indexes freed
    free(target->kids);
    free(target->locals);
    free(target);
}

env* GetGlobal() {
    if (!GlobalEnviron) { // singleton?
        GlobalEnviron = mk_environ(NULL, "Global", 0);

    }
    // 'GLOBAL' environ is special case environ
    // that has no parent and depth 0, i.e. root
    return GlobalEnviron;
}

env* CurrEnv() {
    if (!curr_env)
        curr_env = GetGlobal();
    return curr_env;
}

void print_environ(env *curr) {
    if (!curr) return;
    int i, nkids;
    table_el *res;
    printf("%*s%s:", (curr->depth + 1)*2, " ", curr->name);
    for (i = 0; i < S_SIZE; i++) {
        res = curr->locals[i];
        if (res) {
            printf(" '%s' (%d,%d,", res->tok->text, i, res->defd);
            print_type_list(res->type, res->param_types);
            printf(") |");
        }
    }
    putchar('\n');
    nkids = curr->nkids;
    for (i = 0; i <= nkids; i++)
        print_environ(curr->kids[i]);
}

void PushCurrEnv() {
    env_el *new = sem_malloc(sizeof (env_el), 0);
    env *old_curr = CurrEnv();
    new->env = old_curr;
    new->next = env_stack;
    env_stack = new;

    short temp, count = 0, nkids = old_curr->nkids;
    for (temp = nkids; temp > 0; temp /= 10)
        count++;
    char *name = sem_malloc(sizeof (char) * (count + 7), 1);
    sprintf(name, "temp %hd", nkids);
    curr_env = add_env_child(old_curr, name);
}

env* LinkCurrEnv(token *t) {
    table_el *res;
    env_el *new = sem_malloc(sizeof (env_el), 0);
    env *n, *old_curr = CurrEnv();
    new->env = old_curr;
    new->next = env_stack;
    env_stack = new;

    n = add_env_child(old_curr, t->text);
    res = environ_lookup(CurrEnv(), t->text);
    res->ch_env = n; // link new child

    curr_env = n;
    return n;
}

env* PopEnv() {
    env_el* del = env_stack;
    env_stack = env_stack->next;
    env *res = del->env;
    free(del);

    curr_env = res;
    return res;
}

/* TREE TRAVERSALS SECTION */

void pre_semantics(struct prodrule *p, struct pnode* n) {
    struct pnode *t, *ddecl, *ident;
    btype bt;
    token* to;
    type_el* types, *head; // *head =NULL; table_el *res;
    table_el *id_table;
    switch (p->code / 10) {
        case start_state:
            iostream_included = 0;
            if (include_success) {
                include_success = 0;
                sem_cleanup = 1;
                // insert iostream instances
                token *cin_tok = mktoken(-1, "cin", 0, "iostream", "cin");
                type_el *tcin = mk_type_el(class_instance, NULL, NULL);
                environ_insert(CurrEnv(), cin_tok, tcin, NULL, true, true);
                token *cout_tok = mktoken(-1, "cout", 0, "iostream", "cout");
                type_el *tout = mk_type_el(class_instance, NULL, NULL);
                environ_insert(CurrEnv(), cout_tok, tout, NULL, true, true);
                token *endl_tok = mktoken(-1, "endl", 0, "iostream", "\n");
                type_el *tendl = mk_type_el(char_type, NULL, NULL);
                environ_insert(CurrEnv(), endl_tok, tendl, NULL, true, true);
                // insert iostream classes
                token *string_tok = mktoken(-1, "string", 0, "iostream", "string");
                type_el *string_type = mk_type_el(class_type, NULL, NULL);
                environ_insert(CurrEnv(), string_tok, string_type, NULL, true, true);
                token *fstream_tok = mktoken(-1, "fstream", 0, "iostream", "fstream");
                type_el *fstream_type = mk_type_el(class_type, NULL, NULL);
                environ_insert(CurrEnv(), fstream_tok, fstream_type, NULL, true, true);
            }
            break;
        case member_declaration:
            bt = n->kids[0]->t->code;
            pre_decl_list(bt, n->kids[1]);
            break;
        case class_specifier:
            types = mk_type_el(class_type, NULL, NULL);
            to = n->kids[0]->kids[1]->t; //spec->class_head->'name'
            environ_insert(CurrEnv(), to, types, NULL, false, true);
            LinkCurrEnv(to);
            break;
        case class_name:
            t = DownFind(n->par->kids[1], 8301); // instance name
            LinkCurrEnv(t->t)->name = strcat(strdup(t->t->text), " instance");
            break;
        case compound_statement:
            if (n->prule->code == 9101) {// function body
                LinkCurrEnv(func_loc->tok);
                type_el *head = NULL;
                param_decls(n->par->kids[1], &head);
                CurrEnv()->name = func_loc->tok->text;
            } else {
                PushCurrEnv();
            }
            break;
        case simple_declaration:
            bt = n->kids[0]->t->code;
            pre_decl_list(bt, n->kids[1]);
            break;
        case function_definition:
            head = NULL;
            bt = n->kids[0]->t->code;
            types = pre_declarator(n->kids[1], bt, &to);
            t = DownFind(n, 8702);
            proto_type(t, &head);
            func_loc = environ_insert(CurrEnv(), to, types, head, false, true);
            break;
        case param_decl_clause:
            head = NULL;
            ddecl = UpFind(n, 7905);
            ident = DownFind(ddecl->kids[0], 701);
            id_table = environ_lookup(CurrEnv(), ident->t->text);
            proto_type(n, &head);
            id_table->param_types = head;
            break;
    }
    switch (p->code) {
        case literal:
            assign_lit_type(p, n);
            break;
        case identifier:
            id_table = rec_environ_lookup(n->t->text);
            if (id_table) {
                n->type = id_table->type;
            }
            break;
    }
}

void post_semantics(struct prodrule *p, struct pnode* n) {
    switch (p->code / 10) {
        case class_specifier:
        case compound_statement:
            PopEnv();
            break;
    }
    type_check(p, n);
}

void semantic_traversal(struct pnode *p) {
    struct prodrule *curr;
    int i, nkids;
    if (!p) return;
    nkids = p->nkids;
    // prodrules are maintained in linked list
    for (curr = p->prule; curr; curr = curr->next)
        pre_semantics(curr, p);

    for (i = 0; i < nkids; i++)
        semantic_traversal(p->kids[i]);

    for (curr = p->prule; curr; curr = curr->next)
        post_semantics(curr, p);
}

void pre_decl_list(btype bt, struct pnode *i) {
    int c = i->prule->code;
    if (c == 7602 || c == 10002) {
        pre_decl_list(bt, i->kids[0]);
        pre_init_declarator(bt, i->kids[2]);
    } else {
        pre_init_declarator(bt, i->kids[0]);
    }
}

void pre_init_declarator(btype bt, struct pnode* i) {
    token* to = NULL;
    type_el* inittype = pre_declarator(i->kids[0], bt, &to);
    bool defined = pre_optional_init(i->kids[1]);
    environ_insert(CurrEnv(), to, inittype, NULL, false, defined);
}

type_el* pre_declarator(struct pnode* d, btype ty, token** t) {
    type_el * tmp;
    if (!d) return mk_type_el(ty, NULL, NULL);
    // recursively build type linked list
    switch (d->prule->code) {
        case 7802: // append pointer type to type list
            return mk_type_el(
                    pointer_type,
                    NULL,
                    pre_declarator(d->kids[1], ty, t));
            break;
        case 8001:
            return mk_type_el(
                    pointer_type,
                    NULL,
                    pre_declarator(d->par->kids[1], ty, t));
            break;
        case 7905: // function prototype
            return mk_type_el(
                    function_type,
                    NULL,
                    pre_declarator(d->kids[0], ty, t));
            break;
        case 7906: // append array type to type list
            // set the size of the array
            tmp = mk_type_el(
                    array_type,
                    NULL,
                    pre_declarator(d->kids[0], ty, t));
            tmp->elements = *(int*) (d->kids[2]->t->lval);
            return tmp;
            break;
        case 8301:
            *t = d->t; // found token
            return NULL;
        case 7801:
            return mk_type_el(
                    ty,
                    NULL,
                    pre_declarator(d->kids[0], ty, t));
            break;
        case 7901: // skipped elements
        case 14602:
            return pre_declarator(d->kids[0], ty, t);
            break;
        default:
            printf("ERROR, hit unexpected prodrule while typing%d\n", d->prule->code);
            exit(3);
    }
}

bool pre_optional_init(struct pnode* c) {
    if (c == NULL)
        return false;
    return true;
}

void param_decls(struct pnode *p, type_el **head) {
    struct prodrule *curr;
    type_el *new, *c = *head;
    int i;
    if (!p) return;
    for (curr = p->prule; curr; curr = curr->next) {
        new = param_decl(curr, p);
        if (new) {
            new = mk_type_el(new->bt, new->sib, new->next);
            if (c) {
                while (c->sib)
                    c = c->sib;
                c->sib = new;
            } else {
                *head = new;
            }
        }
    }

    for (i = 0; i < p->nkids; i++)
        param_decls(p->kids[i], head);
}

type_el* param_decl(struct prodrule* pr, struct pnode* pn) {
    btype bt;
    type_el* types = NULL;
    token *to;
    if (pr->code / 10 == parameter_declarator) {
        bt = pn->kids[0]->t->code;
        types = pre_declarator(pn->kids[1], bt, &to);
        environ_insert(CurrEnv(), to, types, NULL, false, true);
    }
    return types;
}

bool type_comp(type_el *a, type_el *b) {
    while (a) {
        if (!b) return false;
        if (a->bt != b->bt) return false;
        a = a->next;
        b = b->next;
    }
    return b ? false : true;
}

bool table_type_comp(table_el* a, table_el* b) {
    if (!type_comp(a->type, b->type)) return false;
    if (!type_comp(a->param_types, b->param_types)) return false;
    return true;
}

struct pnode *UpFind(struct pnode *c, int code) {
    struct prodrule *curr;
    while ((c = c->par)) {
        for (curr = c->prule; curr; curr = curr->next) {
            if (curr->code == code) return c;
        }
    }
    return NULL;
}

struct pnode *DownFind(struct pnode *c, int code) {
    if (!c) return NULL;
    struct prodrule *curr;
    int i;
    struct pnode *d;
    for (curr = c->prule; curr; curr = curr->next) {
        if (curr->code == code)
            return c;
    }

    for (i = 0; i < c->nkids; i++) {
        d = DownFind(c->kids[i], code);
        if (d) return d;
    }
    return NULL;
}

token *FindToken(struct pnode *c) {
    int i;
    token *t;
    if (c->t) {
        return c->t;
    }

    for (i = 0; i < c->nkids; i++) {
        t = FindToken(c->kids[i]);
        if (t) return t;
    }
    return NULL;
}

void proto_type(struct pnode *r, type_el **head) {
    if (!r) return;
    struct prodrule *curr;
    type_el *c = *head, *new;
    int i;
    for (curr = r->prule; curr; curr = curr->next) {
        new = indiv_protos(curr, r);
        if (*head == NULL) {
            *head = new;
        } else {
            c = *head;
            while ((c->next)) {
                c = c->next;
            }
            c->next = new;
        }
    }
    for (i = 0; i < r->nkids; i++) {
        proto_type(r->kids[i], head);
    }

}

type_el *indiv_protos(struct prodrule *pr, struct pnode *n) {
    btype bt;
    type_el* types = NULL;
    token *to;
    if (pr->code / 10 == parameter_declarator) {
        bt = n->kids[0]->t->code;
        types = pre_declarator(n->kids[1], bt, &to);
    }
    return types;
}

void assign_lit_type(struct prodrule *p, struct pnode *n) {
    switch (p->next->next->code) {
        case 901:
            n->type = mk_type_el(int_type, NULL, NULL);
            break;
        case 1001:
            n->type = mk_type_el(char_type, NULL, NULL);
            break;
        case 1101:
            n->type = mk_type_el(double_type, NULL, NULL);
            break;
        case 1201:
            n->type = mk_type_el(string_type, NULL, NULL);
            break;
        case 1301:
        case 1302:
            n->type = mk_type_el(bool_type, NULL, NULL);
            break;
    }
}

void type_err(char *s, struct pnode *c) {
    token *t = FindToken(c);
    fprintf(stderr, "%s:%d error: invalid type for %s\n",
            t->filename, t->lineno, s);
    exit(3);
}

void multi_type(struct pnode *n) {
    switch (n->type->bt) {
        case void_type:
        case class_type:
        case class_instance:
        case pointer_type:
        case array_type:
        case function_type:
        case string_type:
            type_err("multiplication", n);
            break;
        case int_type:
        case bool_type:
        case char_type:
        case double_type:
            break;
    }
}

void mod_type(struct pnode *n) {
    switch (n->type->bt) {
        case void_type:
        case class_type:
        case class_instance:
        case pointer_type:
        case array_type:
        case function_type:
        case string_type:
        case bool_type:
        case double_type:
            type_err("modular arithmetic", n);
            break;
        case int_type:
        case char_type:
            break;
    }
}

void add_type(struct pnode *n) {
    switch (n->type->bt) {
        case void_type:
        case class_type:
        case class_instance:
        case array_type:
        case function_type:
        case string_type:
            type_err("addition", n);
            break;
        case int_type:
        case char_type:
        case pointer_type:
        case bool_type:
        case double_type:
            break;
    }
}

void SL_check(struct pnode *n) {

}

void SR_check(struct pnode *n) {

}

bool canBool(btype t) {
    switch (t) {
        case void_type:
        case class_type:
        case class_instance:
        case array_type:
        case function_type:
            return false;
            break;
        case string_type:
        case int_type:
        case char_type:
        case pointer_type:
        case bool_type:
        case double_type:
            return true;
            break;
    }
    return false;
}

void up_expr_type(struct pnode *n, char k) {
    switch (k) {
        case '*':
        case '+':
            if ((n->kids[0]->type->bt == double_type)
                    || (n->kids[2]->type->bt == double_type)) {
                n->type = mk_type_el(double_type, NULL, NULL);
            } else {
                n->type = mk_type_el(int_type, NULL, NULL);
            }
            break;
        case '%':
            n->type = mk_type_el(int_type, NULL, NULL);
            break;
    }
}

void type_check(struct prodrule *p, struct pnode *n) {
    switch (p->code) {
        case mul_expr:
        case div_expr:
            multi_type(n->kids[0]);
            multi_type(n->kids[2]);
            up_expr_type(n, '*');
            break;
        case mod_expr:
            mod_type(n->kids[0]);
            mod_type(n->kids[2]);
            up_expr_type(n, '%');
            break;
        case add_expr:
        case sub_expr:
            add_type(n->kids[0]);
            add_type(n->kids[2]);
            up_expr_type(n, '+');
            break;
        case SL_expr:
            SL_check(n);
            break;
        case SR_expr:
            SR_check(n);
            break;
        case LT_expr:
        case GT_expr:
        case LE_expr:
        case GE_expr:
        case EE_expr:
        case NE_expr:
        case OR_expr:
        case AND_expr:
        case NOT_expr:
            if (!(canBool(n->kids[0]->type->bt)))
                type_err("boolean logic", n->kids[0]);
            if (!canBool(n->kids[2]->type->bt))
                type_err("boolean logic", n->kids[2]);
            break;
        case par_expr:
            n->type = n->kids[1]->type;
            break;
    }
}
