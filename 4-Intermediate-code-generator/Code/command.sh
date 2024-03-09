yacc -d -y 1805040.y
g++ -w -c -o y.o y.tab.c
flex 1805040.l
g++ -w -c -o l.o lex.yy.c
g++ -o a.out y.o l.o -lfl
./a.out input.c
