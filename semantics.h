#ifndef SEMANTICS_H
#define	SEMANTICS_H

#define S_SIZE 1024

enum SemanticNodes {
    // nodes that require scope actions
    class_specifier = 950,
    compound_statement = 510,
    selection_statement = 530,
    iteration_statement = 550,
};

struct environment {
    int x;
};

struct type {
    enum {
        int_type,
        bool_type,
        void_type,
        class_type,
        array_type
    } kind;

    struct type* array;
    struct {
            struct environment *instancevars;
    } class;
};

struct typeList {
    struct type *first;
    struct typeList *rest;
};

struct type* IntegerType();
struct type* BooleanType();
struct type* VoidType();
struct type* ClassType(struct environment *instancevars);
struct type* ArrayType(struct type *basetype);

struct type *integerType;
struct type *boolType;
struct type *voidType;

#endif	

