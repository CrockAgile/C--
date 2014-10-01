# Makefile for 120++ 
# Jeff Crocker

CC=gcc
CFLAGS=-c -g
TARNAME=hw2.tar

120++:	120++.o lex.yy.o lexlib.o 120gram.tab.o
	$(CC) -o 120++ 120++.o lex.yy.o lexlib.o 120gram.tab.o
	cp 120++ ./examples/120++

120++.o: 120++.c 120gram.tab.h
	$(CC) $(CFLAGS) 120++.c

120gram.tab.o:	120gram.tab.c
	$(CC) $(CFLAGS) 120gram.tab.c

120gram.tab.c 120gram.tab.h: 120gram.y parselib.h
	bison -dt --verbose 120gram.y

lex.yy.o: lex.yy.c
	$(CC) $(CFLAGS) lex.yy.c

lex.yy.c: lexer.l 120gram.tab.h
	flex lexer.l

lexlib.o: lexlib.c 120gram.tab.h
	$(CC) $(CFLAGS) lexlib.c

clean:
	rm -f *.o 120++ lex.yy.c 120gram.output 120gram.tab.c 120gram.tab.h

tar: clean
	tar -cvf $(TARNAME) . \
		--exclude=./.git/* \
		--exclude=./.git \
		--exclude=$(TARNAME) \
		--exclude=.gitignore

transfer: tar
	scp $(TARNAME) croc4574@wormulon.cs.uidaho.edu:/home/croc4574/445/$(TARNAME)
