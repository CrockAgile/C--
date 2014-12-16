#include "parse.h"

extern token yytoken;
extern char* yytext;
extern int yylineno;

// had to move token update to parse category
// due to my high coupling from bad design
int update_yytoken(int code, void* lval) {

    //free(yytoken.text);
    yytoken.text = strdup(yytext);
    yytoken.code = code;
    yytoken.lineno = yylineno;
    yytoken.lval = lval;

    yylval = create_pnode(&yytoken);

    return code;
}

int lval_update_yytoken(int code, void* lval, char* orig) {

    yytoken.text = strdup(orig);
    yytoken.code = code;
    yytoken.lineno = yylineno;
    yytoken.lval = lval;

    yylval = create_pnode(&yytoken);

    return code;
}

struct pnode *alcnode(int rule, int kids, ...) {
    va_list args;

    struct pnode* new_pnode = (struct pnode*)malloc(sizeof(struct pnode));
    if(!new_pnode) return NULL;

    struct prodrule* new_prule = (struct prodrule*)calloc(1,sizeof(struct prodrule));
    if(!new_prule) return NULL;
    new_prule->code = rule;
    new_pnode->prule = new_prule;
    new_pnode->nkids = kids;

    new_pnode->kids = (struct pnode**)malloc((kids + 1) * sizeof(struct pnode*));
    new_pnode->kids[kids] = NULL;
    if(!new_pnode->kids) return NULL;
    int x;
    va_start( args, kids );
    for ( x = 0; x < kids; x++ ) {
        struct pnode *kid = va_arg(args,struct pnode*);
        new_pnode->kids[x] = kid;
        if (kid) // assign parent
            new_pnode->kids[x]->par = new_pnode;
    }
    va_end( args );
    new_pnode->t = NULL;
    return new_pnode;
}

struct pnode* create_pnode(token* curr_yytoken) {
    token* yytoken_copy = (token*)malloc(sizeof(token));
    if(!yytoken_copy) return 0;

    yytoken_copy->code = curr_yytoken->code;
    yytoken_copy->text = curr_yytoken->text;
    yytoken_copy->lineno = curr_yytoken->lineno;
    yytoken_copy->filename = curr_yytoken->filename;
    yytoken_copy->lval = curr_yytoken->lval;

    struct pnode *new_pnode = (struct pnode*)malloc(sizeof(struct pnode));

    if(!new_pnode)
        return 0;

    new_pnode->prule = NULL;
    new_pnode->nkids = 0;
    new_pnode->kids = NULL;
    new_pnode->t = yytoken_copy;

    return new_pnode;
}

void treeprint(struct pnode *p, int depth) {
    int i;
    char *curr;
    if (p == NULL) { // epsilon reduces I make the child ptr NULL
        printf("%*s epsilon expression\n", depth*2, " ");
        return;
    }

    if (p->t) { // 'original text' (type code)
        if(p->prule) {
          struct prodrule* pr = p->prule;
          humanreadable(pr,&curr);
          printf("%*s '%s' prule:%d ", depth*2, " ", p->t->text,p->prule->code);
          while(pr->next) {
            pr = pr->next;
            free(curr);
            humanreadable(pr,&curr);
            printf(" %s", curr);
          }
          free(curr);
          putchar('\n');
        } else {
            printf("%*s '%s' \n", depth*2, " ", p->t->text);
        }
    }
    else { // print "abridged" version of $$ = $1 chains
        struct prodrule* lastprod = p->prule;
        humanreadable(lastprod,&curr);
        printf("%*s %s", depth*2, " ", curr);
        while(lastprod->next) {
            lastprod = lastprod->next;
            free(curr);
            humanreadable(lastprod,&curr);
            printf(" %s",curr);
        }
        free(curr);
        putchar('\n');
        // print only detailed version if more than 1 transition
        //printf("%*s %s <-%d %s : %d\n", depth*2, " ", last,i,first,p->nkids);
    }
    for (i = 0; i < p->nkids; i++)
        treeprint(p->kids[i], depth+1);
    return;
}

void freetree(struct pnode *p) {
    if(!p) // null children guard
        return;
    int i;

    for( i=0; i<p->nkids; i++ ) {
        freetree(p->kids[i]);
    }
    if(p->t){ // terminal -> free terminal data
        free(p->t->text);
        if(p->t->lval)
            free(p->t->lval);
        free(p->t);
    }
    struct prodrule* curr = p->prule, *prev;
    while( curr ) { // free prodrule stack
        prev = curr;
        curr = curr->next;
        free(prev);
    }
    free(p->kids);
    free(p);
}

char* craft_readable(char* base, int prodrule) {
    int s = strlen(base);
    int suffix;
    int suff_len = 6; // start at 6 b/c always add " rule "
    for( suffix = prodrule % SUFF_SIZE; suffix; suffix /= 10) {
        suff_len++;
    }
    suffix = prodrule % SUFF_SIZE;
    char* buf = (char*)malloc(s + suff_len + 1);
    if (!buf)
        exit(2);
    strcpy(buf,base);
    sprintf(&buf[s]," rule %d",suffix);
    buf[s+suff_len] = '\0';
    return buf;
}

void humanreadable(struct prodrule* prule, char **dest) {
    switch(prule->code / 100) {
     case 1:
         *dest = craft_readable("typedef" ,prule->code);
        break;
     case 2:
         *dest = craft_readable("namespace" ,prule->code);
        break;
     case 3:
         *dest = craft_readable("original" ,prule->code);
        break;
     case 4:
         *dest = craft_readable("class_name" ,prule->code);
        break;
     case 5:
         *dest = craft_readable("enum_name" ,prule->code);
        break;
     case 6:
         *dest = craft_readable("template_name" ,prule->code);
        break;
     case 7:
         *dest = craft_readable("identifier" ,prule->code);
        break;
     case 8:
         *dest = craft_readable("literal" ,prule->code);
        break;
     case 9:
         *dest = craft_readable("integer_lit" ,prule->code);
        break;
     case 10:
         *dest = craft_readable("character_lit" ,prule->code);
        break;
     case 11:
         *dest = craft_readable("floating_lit" ,prule->code);
        break;
     case 12:
         *dest = craft_readable("string_lit" ,prule->code);
        break;
     case 13:
         *dest = craft_readable("boolean_lit" ,prule->code);
        break;
     case 14:
         *dest = craft_readable("translation_unit" ,prule->code);
        break;
     case 15:
         *dest = craft_readable("primary_expr" ,prule->code);
        break;
     case 16:
         *dest = craft_readable("id_expr" ,prule->code);
        break;
     case 17:
         *dest = craft_readable("unqualified_id" ,prule->code);
        break;
     case 18:
         *dest = craft_readable("qualified_id" ,prule->code);
        break;
     case 19:
         *dest = craft_readable("nested_name_spec" ,prule->code);
        break;
     case 20:
         *dest = craft_readable("postfix_expr" ,prule->code);
        break;
     case 21:
         *dest = craft_readable("expr_list" ,prule->code);
        break;
     case 22:
         *dest = craft_readable("unary_expr" ,prule->code);
        break;
     case 23:
         *dest = craft_readable("unary_op" ,prule->code);
        break;
    case 24:
     *dest = craft_readable("new_expr" ,prule->code);
            break;
    case 25:
     *dest = craft_readable("new_placement" ,prule->code);
        break;
    case 26:
     *dest = craft_readable("new_type_id" ,prule->code);
        break;
    case 27:
     *dest = craft_readable("new_declarator" ,prule->code);
        break;
    case 28:
     *dest = craft_readable("direct_new_declarator" ,prule->code);
        break;
    case 29:
     *dest = craft_readable("new_initializer" ,prule->code);
        break;
    case 30:
     *dest = craft_readable("delete_expr" ,prule->code);
        break;
    case 31:
     *dest = craft_readable("cast_expr" ,prule->code);
        break;
    case 32:
     *dest = craft_readable("pm_expr" ,prule->code);
        break;
    case 33:
     *dest = craft_readable("multi_expr" ,prule->code);
        break;
    case 34:
     *dest = craft_readable("add_expr" ,prule->code);
        break;
    case 35:
     *dest = craft_readable("shift_expr" ,prule->code);
        break;
    case 36:
     *dest = craft_readable("relation_expr" ,prule->code);
        break;
    case 37:
     *dest = craft_readable("equal_expr" ,prule->code);
        break;
    case 38:
     *dest = craft_readable("and_expr" ,prule->code);
        break;
    case 39:
     *dest = craft_readable("xor_expr" ,prule->code);
        break;
    case 40:
     *dest = craft_readable("or_expr" ,prule->code);
        break;
    case 41:
     *dest = craft_readable("logic_and_expr" ,prule->code);
        break;
    case 42:
     *dest = craft_readable("logic_or_expr" ,prule->code);
        break;
    case 43:
     *dest = craft_readable("condition_expr" ,prule->code);
        break;
    case 44:
     *dest = craft_readable("assign_expr" ,prule->code);
        break;
    case 45:
     *dest = craft_readable("assign_op" ,prule->code);
        break;
    case 46:
     *dest = craft_readable("expr" ,prule->code);
        break;
    case 47:
     *dest = craft_readable("const_expr" ,prule->code);
        break;
    case 48:
     *dest = craft_readable("statement" ,prule->code);
        break;
    case 49:
     *dest = craft_readable("labeled_stmt" ,prule->code);
        break;
    case 50:
     *dest = craft_readable("expr_stmt" ,prule->code);
        break;
    case 51:
     *dest = craft_readable("compound_stmt" ,prule->code);
        break;
    case 52:
     *dest = craft_readable("stmt_sequence" ,prule->code);
        break;
    case 53:
     *dest = craft_readable("selection_stmt" ,prule->code);
        break;
    case 54:
     *dest = craft_readable("condition" ,prule->code);
        break;
    case 55:
     *dest = craft_readable("iteration_stmt" ,prule->code);
        break;
    case 56:
     *dest = craft_readable("for_init_stmt" ,prule->code);
        break;
    case 57:
     *dest = craft_readable("jump_stmt" ,prule->code);
        break;
    case 58:
     *dest = craft_readable("declare_stmt" ,prule->code);
        break;
    case 59:
     *dest = craft_readable("declare_seq" ,prule->code);
        break;
    case 60:
     *dest = craft_readable("declare" ,prule->code);
        break;
    case 61:
     *dest = craft_readable("block_declare" ,prule->code);
        break;
    case 62:
     *dest = craft_readable("simple_declare" ,prule->code);
        break;
    case 63:
     *dest = craft_readable("declare_specifier" ,prule->code);
        break;
    case 64:
     *dest = craft_readable("declare_specifier_seq" ,prule->code);
        break;
    case 65:
     *dest = craft_readable("storage_class_specifier" ,prule->code);
        break;
    case 66:
     *dest = craft_readable("function_specifier" ,prule->code);
        break;
    case 67:
     *dest = craft_readable("type_specifier" ,prule->code);
        break;
    case 68:
     *dest = craft_readable("simple_type_specifier" ,prule->code);
        break;
    case 69:
     *dest = craft_readable("type_name" ,prule->code);
        break;
    case 70:
     *dest = craft_readable("elaborated_type_specifier" ,prule->code);
        break;
    case 71:
     *dest = craft_readable("enum_name" ,prule->code);
        break;
    case 72:
     *dest = craft_readable("enum_specifier" ,prule->code);
        break;
    case 73:
     *dest = craft_readable("enumerator_list" ,prule->code);
        break;
    case 74:
     *dest = craft_readable("enumerator_def" ,prule->code);
        break;
    case 75:
     *dest = craft_readable("enumerator" ,prule->code);
        break;
    case 76:
     *dest = craft_readable("init_decl_list" ,prule->code);
        break;
    case 77:
     *dest = craft_readable("init_decl" ,prule->code);
        break;
    case 78:
     *dest = craft_readable("declarator" ,prule->code);
        break;
    case 79:
     *dest = craft_readable("direct_declarator" ,prule->code);
        break;
    case 80:
     *dest = craft_readable("ptr_op" ,prule->code);
        break;
    case 81:
     *dest = craft_readable("cv_qualifier_seq" ,prule->code);
        break;
    case 82:
     *dest = craft_readable("cv_qualifier" ,prule->code);
        break;
    case 83:
     *dest = craft_readable("declarator_id" ,prule->code);
        break;
    case 84:
     *dest = craft_readable("type_id" ,prule->code);
        break;
    case 85:
     *dest = craft_readable("type_specifier_seq" ,prule->code);
        break;
    case 86:
     *dest = craft_readable("abstract_declarator" ,prule->code);
        break;
    case 87:
     *dest = craft_readable("parameter_decl_clause" ,prule->code);
        break;
    case 88:
     *dest = craft_readable("parameter_decl_list" ,prule->code);
        break;
    case 89:
     *dest = craft_readable("parameter_decl" ,prule->code);
        break;
    case 90:
     *dest = craft_readable("function_definition" ,prule->code);
        break;
    case 91:
     *dest = craft_readable("function_body" ,prule->code);
        break;
    case 92:
     *dest = craft_readable("initializer" ,prule->code);
        break;
    case 93:
     *dest = craft_readable("initializer_clause" ,prule->code);
        break;
    case 94:
     *dest = craft_readable("initializer_list" ,prule->code);
        break;
    case 95:
     *dest = craft_readable("class_specifier" ,prule->code);
        break;
    case 96:
     *dest = craft_readable("class_head" ,prule->code);
        break;
    case 97:
     *dest = craft_readable("class_key" ,prule->code);
        break;
    case 98:
     *dest = craft_readable("member_specification" ,prule->code);
        break;
    case 99:
     *dest = craft_readable("member_declaration" ,prule->code);
        break;
    case 100:
     *dest = craft_readable("member_declarator_list" ,prule->code);
        break;
    case 101:
     *dest = craft_readable("member_declarator" ,prule->code);
        break;
    case 102:
     *dest = craft_readable("const_initializer" ,prule->code);
        break;
    case 103:
     *dest = craft_readable("base_clause" ,prule->code);
        break;
    case 104:
     *dest = craft_readable("base_specifier_list" ,prule->code);
        break;
    case 105:
     *dest = craft_readable("base_specifier" ,prule->code);
        break;
    case 106:
     *dest = craft_readable("access_specifier" ,prule->code);
        break;
    case 107:
     *dest = craft_readable("conversion_func_id" ,prule->code);
        break;
    case 108:
     *dest = craft_readable("conversion_type_id" ,prule->code);
        break;
    case 109:
     *dest = craft_readable("conversion_declarator" ,prule->code);
        break;
    case 110:
     *dest = craft_readable("ctor_initializer" ,prule->code);
        break;
    case 111:
     *dest = craft_readable("mem_init_list" ,prule->code);
        break;
    case 112:
     *dest = craft_readable("mem_initializer" ,prule->code);
        break;
    case 113:
     *dest = craft_readable("mem_initializer_id" ,prule->code);
        break;
    case 114:
     *dest = craft_readable("operator_func_id" ,prule->code);
        break;
    case 115:
     *dest = craft_readable("operator" ,prule->code);
        break;
    case 116:
     *dest = craft_readable("template_declaration" ,prule->code);
        break;
    case 117:
     *dest = craft_readable("template_parameter_list" ,prule->code);
        break;
    case 118:
     *dest = craft_readable("template_parameter" ,prule->code);
        break;
    case 119:
     *dest = craft_readable("type_parameter" ,prule->code);
        break;
    case 120:
     *dest = craft_readable("template_id" ,prule->code);
        break;
    case 121:
     *dest = craft_readable("template_arg_list" ,prule->code);
        break;
    case 122:
     *dest = craft_readable("template_arg" ,prule->code);
        break;
    case 123:
     *dest = craft_readable("explicit_instantiation" ,prule->code);
        break;
    case 124:
     *dest = craft_readable("explicit_specialization" ,prule->code);
        break;
    case 125:
     *dest = craft_readable("try_block" ,prule->code);
        break;
    case 126:
     *dest = craft_readable("func_try_block" ,prule->code);
        break;
    case 127:
     *dest = craft_readable("handler_seq" ,prule->code);
        break;
    case 128:
     *dest = craft_readable("handler" ,prule->code);
        break;
    case 129:
     *dest = craft_readable("exception_decl" ,prule->code);
        break;
    case 130:
     *dest = craft_readable("throw_expression" ,prule->code);
        break;
    case 131:
     *dest = craft_readable("exception_specification" ,prule->code);
        break;
    case 132:
     *dest = craft_readable("type_id_list" ,prule->code);
        break;
    case 133:
     *dest = craft_readable("declaration_seq_opt" ,prule->code);
        break;
    case 134:
     *dest = craft_readable("nested_name_specifier_opt" ,prule->code);
        break;
    case 135:
     *dest = craft_readable("expression_list_opt" ,prule->code);
        break;
    case 136:
     *dest = craft_readable("coloncolon_opt" ,prule->code);
        break;
    case 137:
     *dest = craft_readable("new_placement_opt" ,prule->code);
        break;
    case 138:
     *dest = craft_readable("new_initializer_opt" ,prule->code);
        break;
    case 139:
     *dest = craft_readable("new_declarator_opt" ,prule->code);
        break;
    case 140:
     *dest = craft_readable("expression_opt" ,prule->code);
        break;
    case 141:
     *dest = craft_readable("stmt_seq_opt" ,prule->code);
        break;
    case 142:
     *dest = craft_readable("condition_opt" ,prule->code);
        break;
    case 143:
     *dest = craft_readable("enum_list_opt" ,prule->code);
        break;
    case 144:
     *dest = craft_readable("initializer_opt" ,prule->code);
        break;
    case 145:
     *dest = craft_readable("const_expr_opt" ,prule->code);
        break;
    case 146:
     *dest = craft_readable("abstract_decl_opt" ,prule->code);
        break;
    case 147:
     *dest = craft_readable("type_spec_seq_opt" ,prule->code);
        break;
    case 148:
     *dest = craft_readable("direct_abstract_decl_opt" ,prule->code);
        break;
    case 149:
     *dest = craft_readable("ctor_init_opt" ,prule->code);
        break;
    case 150:
     *dest = craft_readable("comma_opt" ,prule->code);
        break;
    case 151:
     *dest = craft_readable("member_spec_opt" ,prule->code);
        break;
    case 152:
     *dest = craft_readable("semicolon_opt" ,prule->code);
        break;
    case 153:
     *dest = craft_readable("conversion_decl_opt" ,prule->code);
        break;
    case 154:
     *dest = craft_readable("export_opt" ,prule->code);
        break;
    case 155:
     *dest = craft_readable("handler_seq_opt" ,prule->code);
        break;
    case 156:
     *dest = craft_readable("assign_expr_opt" ,prule->code);
        break;
    case 157:
     *dest = craft_readable("type_id_list_opt" ,prule->code);
        break;
    case 162:
     *dest = craft_readable("decl_specifier_seq" ,prule->code);
        break;
    default:
        printf("Unrecognized production rule.\n");
    }
    return;
}

struct pnode* only_child(struct pnode* des, int code) {
    if (!des) return NULL;
    struct prodrule* head = des->prule;
    struct prodrule* new = (struct prodrule*)malloc(sizeof(struct prodrule));
    if(!new)
	    return des; // failure is tolerable
    new->code = code;
    new->next = head;
    des->prule = new;
    return des;
}

int init_nametable() {
    nametable = (token_el**)calloc(TABLESIZE,sizeof(token_el*));
    if (!nametable) {
        fprintf(stderr,"Unable to allocate nametable. Exiting.\n");
        exit(1);
    }
    return 1;
}

void free_nametable() {
    int size = TABLESIZE, i;
    token_el *curr, *prev;
    if(parse_cleanup) {
      parse_cleanup = 0;
      token *t = lookup_name("string")-> t;
      free(t);
      t = lookup_name("fstream")-> t;
      free(t);
    }
    for( i=0; i<size; ++i) {
        curr = nametable[i];
        while(curr) {
            prev = curr;
            curr = curr->next;
            free(prev);
        }
    }
    free(nametable);
}

// djb2 by Dan Bernstein
unsigned long hash_name(char *s) {
    unsigned long hash = 5381;
    int c;
    while( (c = *s++) )
        hash = ((hash << 5) + hash) + c;
    return hash;
}

int insert_name(token *insert, int new_code) {
    unsigned long foo = hash_name(insert->text);
    token_el** des = &nametable[foo%TABLESIZE];
    token_el* res = *des;
    while( res ) { // collision does not guarantee identical
        if( !strcmp(insert->text, res->t->text) ) {
            return 0;
        }
        res = res->next;
    }
    token_el* new = (token_el*)malloc(sizeof(token_el));
    new->t = insert;
    new->t->code = new_code;
    new->next = *des;
    *des = new;
    return 1;
}

token_el* lookup_name(char *search) {
    token_el* res = nametable[hash_name(search)%TABLESIZE];
    while( res ) {
        if( !strcmp(search, res->t->text) ) {
            return res;
        }
        res = res->next;
    }
    return NULL;
}

// check if identifier in table
// if in table, return its code
// else return passed in code (likley identifier)
int id_check(char* s, int code) {
    token_el* res = lookup_name(s);
    if( res ) {
        return res->t->code;
    }
    else {
        return code;
    }
}

// need linked list to maintain roots of trees
void treelist_append(char *file, struct pnode *added) {
    root_el *new = malloc(sizeof(root_el));
    if (!new)
        exit(1);

    new->filename = file;
    new->p = added;
    new->next = NULL;

    if (treelist_tail != NULL) {
        treelist_tail->next = new;
    } else {
        treelist_head = new;
    }
    treelist_tail = new;
}

void treelist_call(void(*f)(struct pnode*)) {
    root_el* curr;
    for ( curr=treelist_head; curr != NULL; curr = curr->next) {
        (*f)(curr->p);
    }
}

void print_treelist(root_el *head) {
    root_el *curr;
    for(curr=head; curr; curr = curr->next) {
        printf("\n*** %s ***\n",curr->filename);
        treeprint(curr->p,0);
    }
}

void free_treelist(root_el *head) {
    while ( head ) {
        root_el *prev = head;
        head = head->next;
        freetree(prev->p);
        free(prev);
    }
    treelist_tail = NULL;
}
