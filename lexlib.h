#ifndef lexlib
#define lexlib

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// filestack interface
int push_file(char* filename, int lineno);
int pop_file(char* name_buff);
int delete_filestack();
void print_filestack();

#endif
