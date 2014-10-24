#include <stdlib.h>
#include "semantics.h"

struct type *integerType = NULL;
struct type *boolType = NULL;
struct type *voidType = NULL;

// classic singletons?
struct type* IntegerType(){
    if ( integerType == NULL ) {
        integerType = calloc(1,sizeof(struct type));
        integerType->kind = int_type;
    }
    return integerType;
}

struct type* BooleanType(){
    if ( boolType == NULL ) {
        boolType = calloc(1,sizeof(struct type));
        boolType->kind = bool_type;
    }
    return boolType;
}

struct type* VoidType(){
    if ( voidType == NULL ) {
        voidType = calloc(1,sizeof(struct type));
        voidType->kind = void_type;
    }
    return voidType;
}

struct type* CharacterType(){
    if ( charType == NULL ) {
        charType = calloc(1,sizeof(struct type));
        charType->kind = char_type;
    }
    return charType;
}

struct type* DoubleType(){
    if ( doubleType == NULL ) {
        doubleType = calloc(1,sizeof(struct type));
        doubleType->kind = double_type;
    }
    return doubleType;
}

