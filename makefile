# Limited Initial Makefile
# Creates "120++" from "lexer.l" and "120++.c"
#

CC=gcc
CFLAGS=-c -g

120++:	120++.o lex.yy.o
	$(CC) -o 120++ 120++.o lex.yy.o

120++.o: 120++.c
	$(CC) $(CFLAGS) 120++.c

lex.yy.o: lex.yy.c
	$(CC) $(CFLAGS) lex.yy.c

lex.yy.c: mylexer.l cgram.tab.h
	flex mylexer.l
