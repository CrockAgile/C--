#ifndef SEMANTICS_H
#define	SEMANTICS_H

#define S_SIZE 1024

enum SemanticNodes {
    // nodes that require new environment
    class_specifier = 950,
    compound_statement = 510,
    selection_statement = 530,
    iteration_statement = 550,
    function_definition = 900,

    // nodes that require adding to environment
    // function_definiton previously defined
    // class_specifier also previously defined
    init_declarator = 770,
    parameter_declarator = 890,
};

void* sem_malloc(int size, int zero);

typedef enum {
        int_type,
        bool_type,
        void_type,
        class_type,
        array_type,
        char_type,
        double_type,
} btype;

typedef struct tableE {
    char *name;
    int scope;
    btype type;
    int cons;
    struct tableE *next;
} tableE;

typedef struct environ {
    tableE **table;
    struct environ *up;
} environ;

tableE* MakeTableE(char*,int,btype,int,tableE*);
environ* MakeEnviron(environ *parent);
tableE* InsertTE(environ*,char*,int,btype,int);
tableE* LookUpTE(environ*,char*);

#endif	

