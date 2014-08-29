# Limited Initial Makefile
# Creates "120++" from "lexer.l" and "120++.c"
#
LEX=flex
YACC=bison -y
YFLAGS=-d
objects=scan.o parse.o 120++.o

120++: $(objects)
scan.o: scan.l parse.c
parse.o: parse.y
120++.o: 120++.c
