kompilator: parser.y flex.l
	bison -d parser.y
	flex flex.l
	g++ -o kompilator.exe funkcje.c lex.yy.c parser.tab.c

