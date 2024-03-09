%option noyywrap

%x STRING
%x SINGLE_LINE_COMMENT
%x MULTI_LINE_COMMENT

%{
#include<iostream>
#include<fstream>
#include<string>
#include "SymbolTable.cpp"
#include "y.tab.h"

int line_count = 1;
int errorCount = 0;
int stringStartLine;
int commentStartLine;

extern FILE *logout;
extern FILE *errorout;

extern SymbolTable symbolTable;

char ch;

string str;
string comment;

%}

WHITESPACE [ \t\f\r\v]+ 
LETTER [a-zA-Z_]
DIGIT [0-9]
NEWLINE \n
SPACE [ ]
BACKSLASH "\\"
SPECIAL_CHARACTER "\\[tvar"'afb0n]"|"\\""

%%

{WHITESPACE} {}

{NEWLINE} {line_count++;}


"if"	{
			return IF;
}
		
"else"	{
			return ELSE;
}

"for"   {
            return FOR;
}

"while"   {
            return WHILE;
}

"do"   {
            return DO;
}

"break"   {
            return BREAK;
}

"int"   {
            return INT;
}

"char"   {
            return CHAR;
}

"float"   {
            return FLOAT;
}

"double"   {
            return DOUBLE;
}

"void"   {
            return VOID;
}

"return"   {
            return RETURN;
}

"switch"   {
            return SWITCH;
}

"case"   {
            return CASE;
}

"default"   {
            return DEFAULT;
}

"continue"   {
            return CONTINUE;
}

"println"	{
			return PRINTLN;
}


[+-]		{
			SymbolInfo *s = new SymbolInfo(yytext, "ADDOP");
			yylval.var = s;
			return ADDOP;
}

[*/%]	{
			SymbolInfo *s = new SymbolInfo(yytext, "MULOP");
			yylval.var = s;
			return MULOP;
}

"++"		{
			return INCOP;
}

"--"		{
			return DECOP;
}

("<"|"<="|">"|">="|"=="|"!=")		{
			SymbolInfo *s = new SymbolInfo(yytext, "RELOP");
			yylval.var = s;
			return RELOP;
}

"="		{
			return ASSIGNOP;
}

("&&"|"||")		{
			SymbolInfo *s = new SymbolInfo(yytext, "LOGICOP");
			yylval.var = s;
			return LOGICOP;
}

"!"		{
			return NOT;
}

"("		{
			return LPAREN;
}

")"		{
			return RPAREN;
}

"{"		{
			return LCURL;
}

"}"		{
			return RCURL;
}

"["		{
			return LTHIRD;
}

"]"		{
			return RTHIRD;
}

","		{
			return COMMA;
}

";"		{
			return SEMICOLON;
}
		
{DIGIT}+ 	{
				SymbolInfo *s = new SymbolInfo(yytext, "int");
				yylval.var = s;
				return CONST_INT;
}

{DIGIT}*(\.{DIGIT}+) {
                SymbolInfo *s = new SymbolInfo(yytext, "float");
				yylval.var = s;
				return CONST_FLOAT;
}


{DIGIT}*(\.{DIGIT}+)([Ee][+-]?({DIGIT}+)) 	{
				SymbolInfo *s = new SymbolInfo(yytext, "float");
				yylval.var = s;
				return CONST_FLOAT;
}

{DIGIT}*(\.{DIGIT}*)(\.{DIGIT}*)+	{
				errorCount++;
				fprintf(errorout,"Error at line %d: Too many decimal point for character sequence %s\n",line_count,yytext);
}

{DIGIT}*(\.{DIGIT}*)?([Ee][+-]?{DIGIT}*)(\.{DIGIT}*)+	{
				errorCount++;
				fprintf(errorout,"Error at line %d: Ill formed number %s\n",line_count,yytext);
}


\'({LETTER}|{DIGIT})\'    {
                SymbolInfo *s = new SymbolInfo(yytext, "char");
				yylval.var = s;
				return CONST_CHAR;
}

\'\\n\' { 
        SymbolInfo *s = new SymbolInfo(yytext, "char");
		yylval.var = s;
		return CONST_CHAR;
}

\'\\t\' { 
        SymbolInfo *s = new SymbolInfo(yytext, "char");
		yylval.var = s;
		return CONST_CHAR;
}

\'\\\\\' {
        SymbolInfo *s = new SymbolInfo(yytext, "char");
		yylval.var = s;
		return CONST_CHAR;
}

\'\\\'\' {
        SymbolInfo *s = new SymbolInfo(yytext, "char");
		yylval.var = s;
		return CONST_CHAR;
}

\'\\\"\' { 
        SymbolInfo *s = new SymbolInfo(yytext, "char");
		yylval.var = s;
		return CONST_CHAR;
}

\'\\a\' { 
        SymbolInfo *s = new SymbolInfo(yytext, "char");
		yylval.var = s;
		return CONST_CHAR;
}

\'\\f\' { 
        SymbolInfo *s = new SymbolInfo(yytext, "char");
		yylval.var = s;
		return CONST_CHAR;
}

\'\\r\' { 
        SymbolInfo *s = new SymbolInfo(yytext, "char");
		yylval.var = s;
		return CONST_CHAR;
}

\'\\b\' { 
        SymbolInfo *s = new SymbolInfo(yytext, "char");
		yylval.var = s;
		return CONST_CHAR;
}

\'\\v\' { 
        SymbolInfo *s = new SymbolInfo(yytext, "char");
		yylval.var = s;
		return CONST_CHAR;
}

\'\\0\' { 
        SymbolInfo *s = new SymbolInfo(yytext, "char");
		yylval.var = s;
		return CONST_CHAR;
}

\'\'    {
        errorCount++;
		fprintf(errorout,"Error at line %d: Empty character constant error %s\n",line_count,yytext);
}

\'({LETTER}|{DIGIT}|{SPACE}|{BACKSLASH}|{SPECIAL_CHARACTER})({LETTER}|{DIGIT}|{SPACE}|{BACKSLASH}|{SPECIAL_CHARACTER})+\'   {
        errorCount++;
		fprintf(errorout,"Error at line %d: Multiple characters error %s\n",line_count,yytext);
}

\'({LETTER}|{DIGIT}|{SPACE}|{BACKSLASH}|{SPECIAL_CHARACTER})*    {
        errorCount++;
		fprintf(errorout,"Error at line %d: Unfinished character error %s\n",line_count,yytext);
}



{LETTER}({LETTER}|{DIGIT})* {
                SymbolInfo *s = new SymbolInfo(yytext, "ID");
				yylval.var = s;
				return ID;
}

({DIGIT})+{LETTER}({LETTER}|{DIGIT})* {
                errorCount++;
				fprintf(errorout,"Error at line %d: Invalid Suffix on numeric constant or invalid prefix on identifier for character sequence %s\n",line_count,yytext);
}

\"  {
        BEGIN STRING;
        str.clear();
        str.push_back(34);
        stringStartLine = line_count;
}



<STRING>\\\n   {line_count++; str.push_back('\n');}

<STRING>"\\n"	{str.push_back('\n');}

<STRING>"\\t"	{str.push_back('\t');}

<STRING>"\\\\"	{str.push_back(92);}

<STRING>"\\\'"	{str.push_back(39);}

<STRING>"\\\""	{str.push_back(34);}

<STRING>"\\a"	{str.push_back('\a');}

<STRING>"\\f"	{str.push_back('\f');}

<STRING>"\\r"	{str.push_back('\r');}

<STRING>"\\b"	{str.push_back('\b');}

<STRING>"\\v"	{str.push_back('\v');}

<STRING>"\\0"	{str.push_back('\0');}

<STRING>\n  {
            line_count++;
            errorCount++;
            fprintf(errorout,"Error at line %d: Unfinished string %s\n",stringStartLine,str.c_str());
            BEGIN INITIAL;
}

<STRING>\" {
            SymbolInfo *s = new SymbolInfo(yytext, "STRING");
			yylval.var = s;
            BEGIN INITIAL;
			return STRING;
}

<STRING>.   {str.append(yytext);}


"//"    {
            BEGIN SINGLE_LINE_COMMENT;
            comment.clear();
			comment.append(yytext);
            commentStartLine = line_count;
}

<SINGLE_LINE_COMMENT>\\\n   {
            line_count++;
            comment.append(yytext);
}

<SINGLE_LINE_COMMENT>\n     {
            line_count++;
            comment.append(yytext);
            //fprintf(logout,"Line no %d: TOKEN <COMMENT> Lexeme %s foundstr\n",commentStartLine,comment.c_str());
            BEGIN INITIAL;
}

<SINGLE_LINE_COMMENT><<EOF>>    {
            //fprintf(logout,"Line no %d: TOKEN <COMMENT> Lexeme %s foundstr\n",commentStartLine,comment.c_str());
            BEGIN INITIAL;
            return 0;
}

<SINGLE_LINE_COMMENT>.  {comment.append(yytext);}


"/*"    {
            BEGIN MULTI_LINE_COMMENT;
            comment.clear();
			comment.append(yytext);
            commentStartLine = line_count;
}

<MULTI_LINE_COMMENT>\n	{
            line_count++;
            comment.append(yytext);
}

<MULTI_LINE_COMMENT>"*/"	{
            line_count++;
            comment.append(yytext);
            //fprintf(logout,"Line no %d: TOKEN <COMMENT> Lexeme %s found\n",commentStartLine,comment.c_str());
            BEGIN INITIAL;
}



<MULTI_LINE_COMMENT><<EOF>>	{
			errorCount++;
            fprintf(errorout,"Error at line %d: Unterminated comment %s\n",commentStartLine,comment.c_str());
			return 0;
}

<MULTI_LINE_COMMENT>.	{comment.append(yytext);}

.	{
		errorCount++;
		fprintf(errorout,"\nError at line %d: Unrecognized character %s\n",line_count,yytext);
}
		

%%