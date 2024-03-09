%{
#include<bits/stdc++.h>
#include "SymbolTable.cpp"
#include "helper.cpp"
#include<fstream>

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

FILE *logout;
FILE *errorout;
FILE *fp;
FILE *asmFile;
FILE *opAsmFile;

extern int line_count;
extern int errorCount;
int labelCount = 0;
int tempCount = 0;

int offsetFromBase = 0;

SymbolInfo *symbolInfo;
SymbolTable symbolTable(7);

bool isValid; 

bool isVoid;

string variableType;

string funcCode;

vector<pair<string, int>> varList;


void yyerror(const char *s)
{
	errorCount++;
	fprintf(logout, "Error at line %d: %s\n", line_count, s);
	fprintf(errorout, "Error at line %d: %s\n", line_count, s);
}

string newLabel() { return "L" + to_string(labelCount++); }

string newTemp() { 
	//retun "temp" + to_string(tempCount++); 
	string temp = "temp" + to_string(tempCount++);
	varList.push_back({ temp, 0 });
	return temp;
}

void printAssemblyCode(FILE *asmFile, string code) { fprintf(asmFile, "%s\n", code.c_str()); }

void optimize(vector<string> codeVector) {
	vector<string> curLine;
	vector<string> nextLine;

	for(int i=0; i<codeVector.size(); i++) {
		if(i == codeVector.size()-1) {printAssemblyCode(opAsmFile, codeVector[i]); cout << codeVector[i] << endl;}
		else {
			if ((codeVector[i].size() < 4) || (codeVector[i + 1].size() < 4)) printAssemblyCode(opAsmFile, codeVector[i]);
			else if ((codeVector[i].substr(1, 3) == "MOV") && (codeVector[i + 1].substr(1, 3) == "MOV")) {
				stringstream ss1(codeVector[i]);
				stringstream ss2(codeVector[i+1]);
				string temp;
				while (getline(ss1, temp, ' ')) { curLine.push_back(temp); }
				while (getline(ss2, temp, ' ')) { nextLine.push_back(temp); }
				//printAssemblyCode(opAsmFile, codeVector[i]);
				// MOV AX, BX THEN MOV BX, AX -> second line redundant
				if((curLine[1].substr(0, curLine[1].size()-1) == nextLine[2]) && (nextLine[1].substr(0, nextLine[1].size()-1) == curLine[2])) {
					printAssemblyCode(opAsmFile, codeVector[i]);
					i++;
				}
				// MOV AX, BX THEN MOV AX, CX -> first line redundant
				else if(curLine[1].substr(0, curLine[1].size()-1) == nextLine[1].substr(0, nextLine[1].size()-1)) {
					
				}
				else printAssemblyCode(opAsmFile, codeVector[i]);
				
				curLine.clear();
				nextLine.clear();
			}
			// PUSH AX THEN POP AX REDUNDANT
			else if ((codeVector[i].substr(1, 4) == "PUSH") && (codeVector[i + 1].substr(1, 3) == "POP")) {
				stringstream ss1(codeVector[i]);
				stringstream ss2(codeVector[i+1]);
				string temp;
				while (getline(ss1, temp, ' ')) { curLine.push_back(temp); }
				while (getline(ss2, temp, ' ')) { nextLine.push_back(temp); }
				//printAssemblyCode(opAsmFile, codeVector[i]);
				if(curLine[1] == nextLine[1]) i = i + 1;
				else printAssemblyCode(opAsmFile, codeVector[i]);
				curLine.clear();
				nextLine.clear();
			}
			else printAssemblyCode(opAsmFile, codeVector[i]);
		}
	}
}


%}

%define parse.error verbose

%union 
{
	SymbolInfo* var;
}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE INCOP DECOP ASSIGNOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON PRINTLN

%token <var> ADDOP
%token <var> MULOP
%token <var> RELOP
%token <var> LOGICOP
%token <var> CONST_INT
%token <var> CONST_FLOAT
%token <var> CONST_CHAR
%token <var> ID
%token <var> STRING

%type <var> start program unit var_declaration variable type_specifier declaration_list
%type <var> expression_statement func_declaration parameter_list func_definition
%type <var> compound_statement statements unary_expression factor statement arguments
%type <var> expression logic_expression simple_expression rel_expression term argument_list
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%%

start : program
	{
		string fullAssemblyCode = $1->getAssemblyCode();
		if(errorCount == 0) {
			// initialization
			printAssemblyCode(asmFile, ".MODEL SMALL\n.STACK 100H\n\n.DATA\n\n");
			for(int i=0; i<varList.size(); i++) {
				if(varList[i].second == 0) printAssemblyCode(asmFile, varList[i].first + " DW ?");
				else printAssemblyCode(asmFile, varList[i].first + " DW " + to_string(varList[i].second) + " DUP(?)");
			}
			printAssemblyCode(asmFile, "\n.CODE");

			// println
			string asmCode = "";
			asmCode += "PRINTLN PROC\n";
			asmCode +="\tPUSH AX\n";
			asmCode +="\tPUSH BX\n";
			asmCode +="\tPUSH CX\n";
			asmCode +="\tPUSH DX\n";
		
			asmCode += "\tMOV BX, 10\n";
			asmCode += "\tMOV CX, 0\n";
			asmCode += "\tMOV DX, 0\n";			
			asmCode += "\tCMP AX, 0\n";
			asmCode += "\tJE PRINT_ZERO\n";
			asmCode += "\tJNL START_STACK\n";
			asmCode += "\tPUSH AX\n";
			asmCode += "\tMOV AH, 2\n";
			asmCode += "\tMOV DL, 2DH\n";
			asmCode += "\tINT 21H\n";
			asmCode += "\tPOP AX\n";
			asmCode += "\tNEG AX\n";
			asmCode += "\tMOV DX, 0\n";
			asmCode += "\tSTART_STACK:\n";
			asmCode += "\t\tCMP AX,0\n";
			asmCode += "\t\tJE PRINTING_START\n";
			asmCode += "\t\tDIV BX\n";
			asmCode += "\t\tPUSH DX\n";
			asmCode += "\t\tINC CX\n";
			asmCode += "\t\tMOV DX, 0\n";
			asmCode += "\t\tJMP START_STACK\n";			
			asmCode += "\tPRINTING_START:\n";
			asmCode += "\t\tMOV AH, 2\n";
			asmCode += "\t\tCMP CX, 0\n";
			asmCode += "\t\tJE PRINTING_END\n";
			asmCode += "\t\tPOP DX\n";
			asmCode += "\t\tADD DX, 30H\n";
			asmCode += "\t\tINT 21H\n";
			asmCode += "\t\tDEC CX\n";
			asmCode += "\t\tJMP PRINTING_START\n";		
			asmCode += "\tPRINT_ZERO:\n";
			asmCode += "\t\tMOV AH, 2\n";
			asmCode += "\t\tMOV DX, 30H\n";
			asmCode += "\t\tINT 21H\n";		
			asmCode += "\tPRINTING_END:\n";
			asmCode += "\t\tMOV DL, 0AH\n";
			asmCode += "\t\tINT 21H\n";
			asmCode += "\t\tMOV DL, 0DH\n";
			asmCode += "\t\tINT 21H\n";			
			asmCode += "\tPOP DX\n";
			asmCode += "\tPOP CX\n";
			asmCode += "\tPOP BX\n";
			asmCode += "\tPOP AX\n";
			asmCode += "\tRET\n";
			asmCode += "PRINTLN ENDP\n\n";

			printAssemblyCode(asmFile, asmCode);

			// printing rest of the code
			printAssemblyCode(asmFile, fullAssemblyCode);

			// optimization


		}
						
		fprintf(logout,"Line %d: start : program\n",line_count);
		$$ = $1;
		fprintf(logout, "%s\n", $$->getName().c_str());

		symbolTable.printAllScopeTable(logout);
		fprintf(logout, "\nTotal lines: %d\n", line_count-1);
		fprintf(logout, "Total errors: %d\n", errorCount);
	}
	;

program : program unit 
	{
		fprintf(logout,"Line %d: program : program unit\n",line_count);
		
		$$ = new SymbolInfo($1->getName() + "\n" + $2->getName(), "program");
		$$->setAssemblyCode($1->getAssemblyCode() + $2->getAssemblyCode());

		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| unit
	{
		fprintf(logout,"Line %d: program : program unit\n",line_count);
		$$ = $1;
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	;
	
unit : var_declaration
	{
		fprintf(logout,"Line %d: unit : var_declaration\n",line_count);
		$$ = $1;
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
    | func_declaration
	{
		fprintf(logout,"Line %d: unit : func_declaration\n",line_count);
		$$ = $1;
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
    | func_definition
	{
		fprintf(logout,"Line %d: unit : func_definition\n",line_count);
		$$ = $1;
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
    ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{
			SymbolInfo* func = symbolTable.lookUp($2->getName());
			if(func == nullptr) {
				vector<string> type;
				vector<SymbolInfo*> pList;
				vector<string> pair = splitString($4->getName(), ',');
				for(string currentPair:pair) {
					type = splitString(currentPair, ' ');
					pList.push_back(new SymbolInfo("name", type[0]));
				}
				
				symbolTable.insert(new SymbolInfo($2->getName(), $1->getName(), pList));
				
				//SymbolInfo *s = new SymbolInfo($2->getName(), $1->getName());
				//s->setIdentity("function");
				//s->parameterList = $4->parameterList;
				//symbolTable.insert(s);
			}
			else {
				errorCount++;
				fprintf(logout, "Error at line %d: function %s already declared\n", line_count, $2->getName().c_str());
				fprintf(errorout, "Error at line %d: function %s already declared\n", line_count, $2->getName().c_str());
			}
			fprintf(logout,"Line %d: func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n",line_count);
			$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "(" + $4->getName() + ");", "func_declaration");
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			SymbolInfo* func = symbolTable.lookUp($2->getName());
			if(func == nullptr) {
				SymbolInfo *s = new SymbolInfo($2->getName(), $1->getName());
				s->setIdentity("function");
				symbolTable.insert(s);
			}
			else {
				errorCount++;
				fprintf(logout, "Error at line %d: function %s already declared\n", line_count, $2->getName().c_str());
				fprintf(errorout, "Error at line %d: function %s already declared\n", line_count, $2->getName().c_str());
			}
			fprintf(logout,"Line %d: func_declaration : type_specifier ID RPAREN SEMICOLON\n",line_count);
			$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "();", "func_declaration");
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN 
				{
					SymbolInfo* func = symbolTable.lookUp($2->getName());
					vector<SymbolInfo*> pList;
					// setting pList
					vector<string> pair = splitString($4->getName(), ',');
					vector<string> typeName;
					for(string currentPair:pair) {
						typeName = splitString(currentPair, ' ');
						SymbolInfo* tempSymbol = new SymbolInfo(typeName[1], typeName[0]);
						pList.push_back(tempSymbol);
					}
					//
					// note - pList works fine
					if(func == nullptr) {
						//SymbolInfo *s1 = new SymbolInfo($2->getName(), $1->getName(), pList);
						//s1->setParameterList(pList); 
						//for(int i=0; i<pList.size(); i++)	s1->getParameterList().push_back(pList[i]);
						//s1->setIdentity("function");
						//s1->setFunctionDefined(true);
						symbolTable.insert(new SymbolInfo($2->getName(), $1->getName(), pList, true));
						// cout << "here " << s1->getParameterList().size() << endl; works fine
						//for(int i=0; i< (s1->getParameterList().size()); i++)	cout << "hrer" << s1->getParameterList()[i]->getName() << endl; // works fine
						symbolTable.enterScope();
						string tempFuncCode = "";
						for(int i=0; i<(pList.size()); i++) {
							string tName = pList[i]->getName() + symbolTable.getCurrentScopeID();
							varList.push_back({tName, 0});
							pList[i]->setAssemblySymbol(tName);
							tempFuncCode += "\tPOP " + tName + "\n";
							isValid = symbolTable.insert(pList[i]);
							//cout << "here " << pList[i]->getName() << endl; // ok
							if(!isValid) {
								errorCount++;
								fprintf(logout, "Error at line %d: parameter of function %s already defined\n", line_count, $2->getName().c_str());
								fprintf(errorout, "Error at line %d: parameter of function %s already defined\n", line_count, $2->getName().c_str());
							}
						}
						funcCode = tempFuncCode;
						
					}
					else {
						if(func->getIdentity() == "function") {
							if(func->getFunctionDefined()) {
								errorCount++;
								fprintf(logout, "Error at line %d: function %s already defined\n", line_count, $2->getName().c_str());
								fprintf(errorout, "Error at line %d: function %s already defined\n", line_count, $2->getName().c_str());
							}
							else {
								int declaredParameterNum = func->getParameterList().size();
								string declaredReturnType = func->getType();
								if(declaredReturnType != $1->getName()) {
									errorCount++;
									fprintf(logout, "Error at line %d: return type of function %s does not match with declaration\n", line_count, $2->getName().c_str());
									fprintf(errorout, "Error at line %d: retun type of function %s does not match with declaration\n", line_count, $2->getName().c_str());
								}
								if(declaredParameterNum != pList.size()) {
									errorCount++;
									fprintf(logout, "Error at line %d: number of parameters of function %s does not match with declaration\n", line_count, $2->getName().c_str());
									fprintf(errorout, "Error at line %d: number of parameters of function %s does not match with declaration\n", line_count, $2->getName().c_str());
								}
								else {
									for(int i=0; i<declaredParameterNum; i++) {
										if(func->getParameterList()[i]->getType() != pList[i]->getType()) {
											errorCount++;
											fprintf(logout, "Error at line %d: function %s parameter does not match with declaration\n", line_count, $2->getName().c_str());
											fprintf(errorout, "Error at line %d: function %s parameter does not match with declaration\n", line_count, $2->getName().c_str());
										}
									}
								}

								symbolTable.remove($2->getName());
								//SymbolInfo *s2 = new SymbolInfo($2->getName(), $1->getName(), pList);
								//s1->setParameterList(pList);
								//s2->setIdentity("function");
								//s2->setFunctionDefined(true);
								//symbolTable.insert(s2);
								symbolTable.insert(new SymbolInfo($2->getName(), $1->getName(), pList, true));
								symbolTable.enterScope();
								string tempFuncCode = "";
								for(int i=0; i<(pList.size()); i++) {
									string tName = pList[i]->getName() + symbolTable.getCurrentScopeID();
									varList.push_back({tName, 0});
									pList[i]->setAssemblySymbol(tName);
									tempFuncCode += "\tPOP " + tName + "\n";
									isValid = symbolTable.insert(pList[i]);
									//cout << "here " << pList[i]->getName() << endl; // ok
									if(!isValid) {
										errorCount++;
										fprintf(logout, "Error at line %d: parameter of function %s already defined\n", line_count, $2->getName().c_str());
										fprintf(errorout, "Error at line %d: parameter of function %s already defined\n", line_count, $2->getName().c_str());
									}
								}
								funcCode = tempFuncCode;

							}
						}
						else {
							symbolTable.enterScope();
							errorCount++;
							fprintf(logout, "Error at line %d:  %s is not a function\n", line_count, $2->getName().c_str());
							fprintf(errorout, "Error at line %d: %s is not a function\n", line_count, $2->getName().c_str());
						}
					}
					pList.clear();
				}
				compound_statement
				{
					SymbolInfo *ss = symbolTable.lookUp($2->getName());
					vector<SymbolInfo*> parList = ss->getParameterList();
					//cout << "compound "<< ss->getIdentity() << ss->getParameterList()[0]->getType() << endl;
					
					string asmCode = "";
					if($2->getName() == "main") {
						asmCode += "MAIN PROC\n\tMOV AX, @DATA\n\tMOV DS, AX\n";
						asmCode += $7->getAssemblyCode();
						asmCode += "\tMOV AX, 4CH\n\tINT 21H\nMAIN ENDP\nEND MAIN\n\n";
					}
					else {
						asmCode += $2->getName() + " PROC\n\tPOP BP\n";
						asmCode += funcCode;
						asmCode += "\tPUSH BP\n";
						asmCode += $7->getAssemblyCode();
						asmCode += "\tPUSH BP\n\tRET\n";
						asmCode += $2->getName() + " ENDP\n\n";
					}
					
					fprintf(logout,"Line %d: func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n",line_count);
					
					$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "(" + $4->getName() + ")" + $7->getName() + "\n", "func_definition");
					$$->setAssemblyCode(asmCode);
					
					fprintf(logout, "%s\n", $$->getName().c_str());
				}
				| type_specifier ID LPAREN RPAREN
				{
					SymbolInfo* func = symbolTable.lookUp($2->getName());
					if(func == nullptr) {
						SymbolInfo *s1 = new SymbolInfo($2->getName(), $1->getName());
						s1->setIdentity("function");
						s1->setFunctionDefined(true);
						symbolTable.insert(s1);
						symbolTable.enterScope();
					}
					else {
						if(func->getIdentity() == "function") {
							if(func->getFunctionDefined()) {
								errorCount++;
								fprintf(logout, "Error at line %d: function %s already defined\n", line_count, $2->getName().c_str());
								fprintf(errorout, "Error at line %d: function %s already defined\n", line_count, $2->getName().c_str());
							}
							else {
								int declaredParameterNum = func->getParameterList().size();
								string declaredReturnType = func->getType();
								if(declaredReturnType != $1->getName()) {
									errorCount++;
									fprintf(logout, "Error at line %d: return type of function %s does not match with declaration\n", line_count, $2->getName().c_str());
									fprintf(errorout, "Error at line %d: retun type of function %s does not match with declaration\n", line_count, $2->getName().c_str());
								}
								if(declaredParameterNum != 0) {
									errorCount++;
									fprintf(logout, "Error at line %d: number of parameters of function %s does not match with declaration\n", line_count, $2->getName().c_str());
									fprintf(errorout, "Error at line %d: number of parameters of function %s does not match with declaration\n", line_count, $2->getName().c_str());
								}

								symbolTable.remove($2->getName());
								SymbolInfo *s1 = new SymbolInfo($2->getName(), $1->getName());
								s1->setIdentity("function");
								s1->setFunctionDefined(true);
								symbolTable.insert(s1);
								symbolTable.enterScope();
							}
						}
						else {
							symbolTable.enterScope();
							errorCount++;
							fprintf(logout, "Error at line %d:  %s is not a function\n", line_count, $2->getName().c_str());
							fprintf(errorout, "Error at line %d: %s is not a function\n", line_count, $2->getName().c_str());
						}
					}
				}
				compound_statement
				{
					
					string asmCode = "";
					if ($2->getName() == "main") {
						asmCode += "MAIN PROC\n\tMOV AX, @DATA\n\tMOV DS, AX\n";
						asmCode += $6->getAssemblyCode();
						asmCode += "\tMOV AX, 4CH\n\tINT 21H\nMAIN ENDP\nEND MAIN\n\n";
					}
					else {
						asmCode += $2->getName() + " PROC\n\tPOP BP\n";
						asmCode += $6->getAssemblyCode();
						asmCode += "\tPUSH BP\n\tRET\n";
						asmCode += $2->getName() + " ENDP\n\n";
					}
					
					fprintf(logout,"Line %d: func_definition : type_specifier ID LPAREN RPAREN compound_statement\n",line_count);
					
					$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "()" + $6->getName() + "\n", "func_definition");
					$$->setAssemblyCode(asmCode);
					
					fprintf(logout, "%s\n", $$->getName().c_str());
				}
 			;				
			


parameter_list  : parameter_list COMMA type_specifier ID
		{
			fprintf(logout,"Line %d: parameter_list  : parameter_list COMMA type_specifier ID\n",line_count);
			$$ = new SymbolInfo($1->getName() + "," + $3->getName() + " " + $4->getName(), "parameter_list");
			fprintf(logout, "%s\n", $$->getName().c_str());
			//SymbolInfo* param = new SymbolInfo($4->getName(), $3->getName());
			//param->setIdentity("variable");
			//$$->parameterList.push_back(param);
		}
		| parameter_list COMMA type_specifier
 		{
			fprintf(logout,"Line %d: parameter_list  : parameter_list COMMA type_specifier\n",line_count);
			$$ = new SymbolInfo($1->getName() + "," + $3->getName(), "parameter_list");
			fprintf(logout, "%s\n", $$->getName().c_str());
			//SymbolInfo* param = new SymbolInfo($3->getName(), $3->getName());
			//param->setIdentity("type_specifier");
			//$$->parameterList.push_back(param);
		}
		| type_specifier ID
		{
			fprintf(logout,"Line %d: parameter_list  : type_specifier ID\n",line_count);
			$$ = new SymbolInfo($1->getName() + " " + $2->getName(), "parameter_list");
			fprintf(logout, "%s\n", $$->getName().c_str());
			//SymbolInfo* param = new SymbolInfo($2->getName(), $1->getName());
			//param->setIdentity("variable");
			//$$->parameterList.push_back(param);
		}
		| type_specifier
 		{
			fprintf(logout,"Line %d: parameter_list  : type_specifier\n",line_count);
			$$ = $1;
			fprintf(logout, "%s\n", $$->getName().c_str());
			//SymbolInfo* param = new SymbolInfo($1->getName(), $1->getName());
			//param->setIdentity("type_specifier");
			//$$->parameterList.push_back(param);
		}
		;




 		
compound_statement : LCURL statements RCURL
 		    {
				fprintf(logout,"Line %d: compound_statement : LCURL statements RCURL\n",line_count);
				
				$$ = new SymbolInfo("{\n"+ $2->getName() + "\n}", "compound_statement");
				$$->setAssemblyCode($2->getAssemblyCode());

				fprintf(logout, "%s\n", $$->getName().c_str());
				symbolTable.printAllScopeTable(logout);
				symbolTable.exitScope();
			}
			| LCURL RCURL
 		    {
				fprintf(logout,"Line %d: compound_statement : LCURL RCURL\n",line_count);
				$$ = new SymbolInfo("{\n}", "compound_statement");
				fprintf(logout, "%s\n", $$->getName().c_str());
			}
			;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
 		{
			if($1->getName() == "void") {
				errorCount++;
				fprintf(logout, "Error at line %d: Variable type cannot be void\n", line_count);
				fprintf(errorout, "Error at line %d: Variable type cannot be void\n", line_count);
			}
			else {
				vector<string> line = splitString($2->getName(), ',');
				for(string word:line) {
					SymbolInfo* s;
					string name, size, tName;
					if ((word.find("[") != string::npos) || (word.find("]") != string::npos)) {
						stringstream ss(word);
						getline(ss, name, '[');
						while(getline(ss, size, '[')) { }
						stringstream ss2(size);
						getline(ss2, size, ']');

						int sz = atoi(size.c_str());

						tName = name + symbolTable.getCurrentScopeID();
						varList.push_back({tName, sz});
						s = new SymbolInfo(name, $1->getType(), sz);
						s->setIdentity("array");
						s->setAssemblySymbol(tName);
    				}
					else {
						tName = word + symbolTable.getCurrentScopeID();
						varList.push_back({tName, 0});
						s = new SymbolInfo(word, $1->getType());
						s->setIdentity("variable");
						s->setAssemblySymbol(tName);
					}
					isValid = symbolTable.insert(s);
					if(!isValid) {
						errorCount++;
						fprintf(logout, "Error at line %d: %s variable already exists\n", line_count, s->getName().c_str());
						fprintf(errorout, "Error at line %d: %s variable already exists\n", line_count, s->getName().c_str());
					}
				}
			}
			
			fprintf(logout,"Line %d: var_declaration : type_specifier declaration_list SEMICOLON\n",line_count);
			$$ = new SymbolInfo($1->getName() + $2->getName() + ";", "var_declaration");
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		;
 		 
type_specifier	: INT
				{
					fprintf(logout,"Line %d: type_specifier	: INT\n",line_count);
					$$ = new SymbolInfo("int", "int");
					fprintf(logout, "%s\n", $$->getName().c_str());
				}
 				| FLOAT
				{
					fprintf(logout,"Line %d: type_specifier	: FLOAT\n",line_count);
					$$ = new SymbolInfo("float", "float");
					fprintf(logout, "%s\n", $$->getName().c_str());
				}
 				| VOID
				{
					fprintf(logout,"Line %d: type_specifier	: VOID\n",line_count);
					$$ = new SymbolInfo("void", "void");
					fprintf(logout, "%s\n", $$->getName().c_str());
				}
 				;
 		
declaration_list : declaration_list COMMA ID
		{
			fprintf(logout,"Line %d: declaration_list : declaration_list COMMA ID\n",line_count);
			$$ = new SymbolInfo($1->getName() + "," + $3->getName(), "declaration_list");
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
 		| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
 		{
			fprintf(logout,"Line %d: declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n",line_count);
			$$ = new SymbolInfo($1->getName() + "," + $3->getName() + "[" + $5->getName() + "]", "declaration_list");
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		| ID
 		{
			fprintf(logout,"Line %d: declaration_list : ID\n",line_count);
			$$ = $1;
			fprintf(logout, "%s\n", $$->getName().c_str());
		}	
		| ID LTHIRD CONST_INT RTHIRD
 		{
			fprintf(logout,"Line %d: declaration_list : ID LTHIRD CONST_INT RTHIRD\n",line_count);
			$$ = new SymbolInfo($1->getName() + "[" + $3->getName() + "]", "declaration_list");
			fprintf(logout, "%s\n", $$->getName().c_str());
		}  
		;
 		  
statements : statement
		{
			fprintf(logout,"Line %d: statements : statement\n",line_count);
			$$ = $1;
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
	   | statements statement
	   {
			fprintf(logout,"Line %d: statements : statements statement\n",line_count);

			$$ = new SymbolInfo($1->getName() + "\n" + $2->getName(), "statements");
			$$->setAssemblyCode($1->getAssemblyCode() + $2->getAssemblyCode());

			fprintf(logout, "%s\n", $$->getName().c_str());
	   }
	   ;
	   
statement : var_declaration
	{
		fprintf(logout,"Line %d: statement : var_declaration\n",line_count);
		$$ = $1;
		//string asmCode = "; assembly code for " + $$->getName() + "\n" + $$->getAssemblyCode();
		//$$->setAssemblyCode(asmCode);
		
		fprintf(logout, "%s\n", $$->getName().c_str());
	}	
	| expression_statement
	{
		fprintf(logout,"Line %d: statement : expression_statement\n",line_count);
		$$ = $1;
		string asmCode = "; assembly code for " + $$->getName() + "\n" + $$->getAssemblyCode();
		$$->setAssemblyCode(asmCode);
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| { symbolTable.enterScope(); }compound_statement
	{
		fprintf(logout,"Line %d: statement : compound_statement\n",line_count);
		$$ = $2;
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| FOR LPAREN expression_statement expression_statement expression RPAREN statement
	{
		
		string asmCode = ";Assembly code for FOR loop ending on line " + to_string(line_count) +"\n";
		asmCode += $3->getAssemblyCode();
		if(($3->getName()!=";") && ($4->getName()!=";")) {
			string l1 = newLabel();
			string l2 = newLabel();
			asmCode += l1 + ":\n" + $4->getAssemblyCode();
			asmCode += "\tMOV AX, " + $4->getAssemblySymbol() + "\n\tCMP AX, 0\n\tJE " + l2 + "\n";
			asmCode += $7->getAssemblyCode();
			asmCode += $5->getAssemblyCode();
			asmCode += "\tJMP " + l1 + "\n" + l2 + ":\n";
		}

		fprintf(logout,"Line %d: statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n",line_count);
		
		$$ = new SymbolInfo("for(" + $3->getName() + $4->getName() + $5->getName() + ")" + $7->getName(),	"statement");
		$$->setAssemblyCode(asmCode);
		
		
		fprintf(logout, "%s\n", $$->getName().c_str());
	}  
	| IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	{
		
		string l = newLabel();
		string asmCode = "; Assembly code for IF ending on line " + to_string(line_count) + "\n";
		asmCode += $3->getAssemblyCode();
		asmCode += "\tMOV AX, " + $3->getAssemblySymbol() + "\n\tCMP AX, 0\n\tJE " + l + "\n";
		asmCode += $5->getAssemblyCode() + l + ":\n";
		
		fprintf(logout,"Line %d: statement : IF LPAREN expression RPAREN statement\n",line_count);

		$$ = new SymbolInfo("if(" + $3->getName() + ")" + $5->getName(), "statement");
		$$->setAssemblyCode(asmCode);
		
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| IF LPAREN expression RPAREN statement ELSE statement
	{
		string l1 = newLabel();
		string l2 = newLabel();
		string asmCode = "; Assembly code for IF...ELSE  ending on line " + to_string(line_count) +"\n";
		asmCode += $3->getAssemblyCode();;
		asmCode += "\tMOV AX, " + $3->getAssemblySymbol() + "\n\tCMP AX, 0\n\tJE " + l1 + "\n";
		asmCode += $5->getAssemblyCode();
		asmCode += "\tJMP " + l2 + "\n" + l1 + ":\n";
		asmCode += $7->getAssemblyCode() + l2 + ":\n";
		
		
		fprintf(logout,"Line %d: statement : IF LPAREN expression RPAREN statement ELSE statement\n",line_count);
		
		$$ = new SymbolInfo("if(" + $3->getName() + ")" + $5->getName() + "else" + $7->getName(), "statement");
		$$->setAssemblyCode(asmCode);
		
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| WHILE LPAREN expression RPAREN statement
	{
		string l1 = newLabel();
		string l2 = newLabel();
		string asmCode = "; Assembly code for WHILE ending on line " + to_string(line_count) +"\n";
		asmCode += l1 + ":\n";
		asmCode += $3->getAssemblyCode();
		asmCode += "\tMOV AX, " + $3->getAssemblySymbol() + "\n\tCMP AX, 0\n\tJE " + l2 + "\n";
		asmCode += $5->getAssemblyCode();
		asmCode += "\tJMP " + l1 + "\n" + l2 +":\n";
		
		fprintf(logout,"Line %d: statement : WHILE LPAREN expression RPAREN statement\n",line_count);
		
		$$ = new SymbolInfo("while(" + $3->getName() + ")" + $5->getName(),	"statement");
		$$->setAssemblyCode(asmCode);
		
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| PRINTLN LPAREN ID RPAREN SEMICOLON
	{
		SymbolInfo* s = symbolTable.lookUp($3->getName());
		if(s == nullptr) {
			errorCount++;
			fprintf(logout, "Error at line %d: Variable %s is not declared\n", line_count, $3->getName().c_str());
			fprintf(errorout, "Error at line %d: Variable %s is not declared\n", line_count, $3->getName().c_str());
		}

		//
		string asmCode = "\tMOV AX, " + s->getAssemblySymbol() + "\n\tCALL PRINTLN\n";

		fprintf(logout,"Line %d: statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n",line_count);

		$$ = new SymbolInfo("println(" + $3->getName() + ");", "statement");
		string tAsmCode = "; Assembly code for " + $$->getName() + "\n" + asmCode;
		$$->setAssemblyCode(tAsmCode);

		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| RETURN expression SEMICOLON
	{
		if($2->getName() == "void") {
			errorCount++;
			fprintf(logout, "Error at line %d: Void function cannot have return statement\n", line_count);
			fprintf(errorout, "Error at line %d: Void function cannot have return statement\n", line_count);
		}

		string asmCode = $2->getAssemblyCode() + "\tPOP BP\n\tPUSH " + $2->getAssemblySymbol() + "\n";

		fprintf(logout,"Line %d: statement : RETURN expression SEMICOLON\n",line_count);

		$$ = new SymbolInfo("return " + $2->getName() + ";", "statement");
		string tAsmCode = "; Assembly code for " + $$->getName() + "\n" + asmCode;
		$$->setAssemblyCode(tAsmCode);

		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	;
	  
expression_statement 	: SEMICOLON			
			{
				fprintf(logout,"Line %d: expression_statement : SEMICOLON\n",line_count);
				$$ = new SymbolInfo(";", "SEMICOLON");
				fprintf(logout, "%s\n", $$->getName().c_str());
			}
			| expression SEMICOLON 
			{
				fprintf(logout,"Line %d: expression_statement : expression SEMICOLON\n",line_count);

				$$ = new SymbolInfo($1->getName() + ";", "expression_statement");
				$$->setAssemblyCode($1->getAssemblyCode());
				$$->setAssemblySymbol($1->getAssemblySymbol());

				fprintf(logout, "%s\n", $$->getName().c_str());
			}
			;
	  
variable : ID 		
	{
		fprintf(logout,"Line %d: variable : ID\n",line_count);
		SymbolInfo* s = symbolTable.lookUp($1->getName());
		if(s == nullptr) {
			errorCount++;
			fprintf(logout, "Error at line %d: Variable %s is not declared\n", line_count, $1->getName().c_str());
			fprintf(errorout, "Error at line %d: Variable %s is not declared\n", line_count, $1->getName().c_str());
			$$ = new SymbolInfo($1->getName(), "error");
		}
		else {
			$$ = new SymbolInfo(s->getName(), s->getType());
			$$->setIdentity(s->getIdentity());
			$$->setAssemblySymbol(s->getAssemblySymbol());
		}
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| ID LTHIRD expression RTHIRD
	{
		fprintf(logout,"Line %d: variable : ID LTHIRD expression RTHIRD\n",line_count);
		SymbolInfo* s = symbolTable.lookUp($1->getName());
		string temp = newTemp();
		string asmCode = "";
		if(s == nullptr) {
			errorCount++;
			fprintf(logout, "Error at line %d: Variable %s is not declared\n", line_count, $1->getName().c_str());
			fprintf(errorout, "Error at line %d: Variable %s is not declared\n", line_count, $1->getName().c_str());
			$$ = new SymbolInfo($1->getName() + "[" + $3->getName() + "]",	"error");
		}
		else {
			if(s->getIdentity() == "array") {
				if ($3->getType() != "int") {
					errorCount++;
					fprintf(logout, "Error at line %d: Array index must be integer\n", line_count);
					fprintf(errorout, "Error at line %d: Array index must be integer\n", line_count);
				}
				asmCode += $3->getAssemblyCode();
				asmCode += "\tMOV SI, " + $3->getAssemblySymbol() + "\n\tADD SI, SI\n\tMOV AX, " + s->getAssemblySymbol() + "[SI]\n";
				temp = s->getAssemblySymbol() + "[" + $3->getAssemblySymbol() + "]";
				$$ = new SymbolInfo($1->getName() + "[" + $3->getName() + "]", s->getType());
				$$->setAssemblyCode(asmCode);
				$$->setAssemblySymbol(temp);
			}
			else {
				errorCount++;
				fprintf(logout, "Error at line %d: Variable %s is not an array\n", line_count, $1->getName().c_str());
				fprintf(errorout, "Error at line %d: Variable %s is not an array\n", line_count, $1->getName().c_str());
				$$ = new SymbolInfo($1->getName() + "[" + $3->getName() + "]",	"error");
			}
		}
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	;
	 
expression : logic_expression	
	   {
			fprintf(logout,"Line %d: expression : logic_expression\n",line_count);
			$$ = $1;
			fprintf(logout, "%s\n", $$->getName().c_str());
	   }
	   | variable ASSIGNOP logic_expression 	
	   {
			
			if(($1->getIdentity()!="variable") || ($3->getType()=="error") ) {
				errorCount++;
				fprintf(logout, "Error at line %d: Type mismatch between the operands of assignment operator\n", line_count);
				fprintf(errorout, "Error at line %d: Type mismatch between the operands of assignment operator\n", line_count);
			}
			else {
				if($1->getType() != $3->getType()) {
					cout << "yezz2 " << endl;
					if(($1->getType() == "float") && ($3->getType() == "int")) {}
					else {
						errorCount++;
						fprintf(logout, "Error at line %d: Type mismatch between the operands of assignment operator\n", line_count);
						fprintf(errorout, "Error at line %d: Type mismatch between the operands of assignment operator\n", line_count);
					}	
				}
			}

			string asmCode = $1->getAssemblyCode() + $3->getAssemblyCode() + "\tMOV AX, " + $3->getAssemblySymbol() + "\n\tMOV " + $1->getAssemblySymbol() + ", AX\n";

			fprintf(logout,"Line %d: expression : variable ASSIGNOP logic_expression\n",line_count);

			$$ = new SymbolInfo($1->getName() + "=" + $3->getName(), "expression");
			$$->setAssemblyCode(asmCode);
			$$->setAssemblySymbol($1->getAssemblySymbol());


			fprintf(logout, "%s\n", $$->getName().c_str());
	   }
	   ;
			
logic_expression : rel_expression 	
		{
			fprintf(logout,"Line %d: logic_expression : rel_expression\n",line_count);
			$$ = $1;
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		| rel_expression LOGICOP rel_expression 	
		{
			string retType = "error";
			if(($1->getType() != "int") || ($3->getType() != "int")) {
				errorCount++;
				fprintf(logout, "Error at line %d: operands of logical operator must be integer\n", line_count);
				fprintf(errorout, "Error at line %d: operands of logical operator must be integer\n", line_count);
			}
			else retType = "int";

			string temp = newTemp();
			string r0 = newLabel();
			string r1 = newLabel();
			string op = $2->getName();
			string asmCode = $1->getAssemblyCode() + $3->getAssemblyCode();
			if(op == "&&") {
				asmCode += "\tMOV AX, " + $1->getAssemblySymbol() + "\n";
				asmCode += "\tCMP AX, 0\n";
				asmCode += "\tJE " + r0 + "\n";
				asmCode += "\tMOV AX, " + $3->getAssemblySymbol() + "\n";
				asmCode += "\tCMP AX, 0\n";
				asmCode += "\tJE " + r0 + "\n";
				asmCode += "\tMOV AX, 1\n";
				asmCode += "\tMOV " + temp + ", AX\n";
				asmCode += "\tJMP " + r1 + "\n";
				asmCode += r0 + ":\n";
				asmCode += "\tMOV AX, 0\n";
				asmCode += "\tMOV " + temp + ", AX\n";
				asmCode += r1 + ":\n";
			}
			else {
				asmCode += "\tMOV AX, " + $1->getAssemblySymbol() + "\n";
				asmCode += "\tCMP AX, 0\n";
				asmCode += "\tJNE " + r0 + "\n";
				asmCode += "\tMOV AX, " + $3->getAssemblySymbol() + "\n";
				asmCode += "\tCMP AX, 0\n";
				asmCode += "\tJNE " + r0 + "\n";
				asmCode += "\tMOV AX, 1\n";
				asmCode += "\tMOV " + temp + ", AX\n";
				asmCode += "\tJMP " + r1 + "\n";
				asmCode += r0 + ":\n";
				asmCode += "\tMOV AX, 0\n";
				asmCode += "\tMOV " + temp + ", AX\n";
				asmCode += r1 + ":\n";
			}

			fprintf(logout,"Line %d: logic_expression : rel_expression LOGICOP rel_expression\n",line_count);
			
			$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), retType);
			$$->setAssemblyCode(asmCode);
			$$->setAssemblySymbol(temp);
			
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		;
			
rel_expression	: simple_expression 
		{
			fprintf(logout,"Line %d: rel_expression	: simple_expression\n",line_count);
			$$ = $1;
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		| simple_expression RELOP simple_expression	
		{
			string temp = newTemp();
			string r0 = newLabel();
			string r1 = newLabel();
			string op = $2->getName();
			string asmCode = $1->getAssemblyCode() + $3->getAssemblyCode() + "\tMOV AX, " + $1->getAssemblySymbol()  + "\n\tCMP AX, " + $3->getAssemblySymbol() + "\n";
			
			if (op == "<") {
				asmCode += "\tJL " + r1 + "\n";
				asmCode += "\tMOV AX, 0\n";
				asmCode += "\tMOV " + temp + ", AX\n";
				asmCode += "\tJMP " + r0 + "\n";
				asmCode += r1 + ":\n";
				asmCode += "\tMOV AX, 1\n";
				asmCode += "\tMOV " + temp + ", AX\n";
				asmCode += r0 + ":\n";
			}
			else if (op == ">") {
				asmCode += "\tJG " + r1 + "\n";
				asmCode += "\tMOV AX, 0\n";
				asmCode += "\tMOV " + temp + ", AX\n";
				asmCode += "\tJMP " + r0 + "\n";
				asmCode += r1 + ":\n";
				asmCode += "\tMOV AX, 1\n";
				asmCode += "\tMOV " + temp + ", AX\n";
				asmCode += r0 + ":\n";
			}
			else if (op == "<=") {
				asmCode += "\tJLE " + r1 + "\n";
				asmCode += "\tMOV AX, 0\n";
				asmCode += "\tMOV " + temp + ", AX\n";
				asmCode += "\tJMP " + r0 + "\n";
				asmCode += r1 + ":\n";
				asmCode += "\tMOV AX, 1\n";
				asmCode += "\tMOV " + temp + ", AX\n";
				asmCode += r0 + ":\n";
			}
			else if (op == ">=") {
				asmCode += "\tJGE " + r1 + "\n";
				asmCode += "\tMOV AX, 0\n";
				asmCode += "\tMOV " + temp + ", AX\n";
				asmCode += "\tJMP " + r0 + "\n";
				asmCode += r1 + ":\n";
				asmCode += "\tMOV AX, 1\n";
				asmCode += "\tMOV " + temp + ", AX\n";
				asmCode += r0 + ":\n";
			}
			else if (op == "==") {
				asmCode += "\tJE " + r1 + "\n";
				asmCode += "\tMOV AX, 0\n";
				asmCode += "\tMOV " + temp + ", AX\n";
				asmCode += "\tJMP " + r0 + "\n";
				asmCode += r1 + ":\n";
				asmCode += "\tMOV AX, 1\n";
				asmCode += "\tMOV " + temp + ", AX\n";
				asmCode += r0 + ":\n";
			}
			else {
				asmCode += "\tJNE " + r1 + "\n";
				asmCode += "\tMOV AX, 0\n";
				asmCode += "\tMOV " + temp + ", AX\n";
				asmCode += "\tJMP " + r0 + "\n";
				asmCode += r1 + ":\n";
				asmCode += "\tMOV AX, 1\n";
				asmCode += "\tMOV " + temp + ", AX\n";
				asmCode += r0 + ":\n";
			}

			fprintf(logout,"Line %d: rel_expression	: simple_expression RELOP simple_expression\n",line_count);
			
			$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(),	"int");
			$$->setAssemblyCode(asmCode);
			$$->setAssemblySymbol(temp);
			
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		;
				
simple_expression : term 
		{
			fprintf(logout,"Line %d: simple_expression : term\n",line_count);
			$$ = $1;
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		| simple_expression ADDOP term 
		{
			string temp;
			string asmCode = $1->getAssemblyCode() + $3->getAssemblyCode();
			if($2->getName() == "+") {
				asmCode += "\tMOV AX, " + $1->getAssemblySymbol()  + "\n\tADD AX, " + $3->getAssemblySymbol() + "\n";
				temp = newTemp();
				asmCode += "\tMOV " + temp + ", AX\n";
			}
			else {
				asmCode += "\tMOV AX, " + $1->getAssemblySymbol()  + "\n\tSUB AX, " + $3->getAssemblySymbol() + "\n";
				temp = newTemp();
				asmCode += "\tMOV " + temp + ", AX\n";
			}
			
			fprintf(logout,"Line %d: simple_expression : simple_expression ADDOP term\n",line_count);
			
			if (($1->getType() == "float") || ($3->getType() == "float")) $$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "float");
			else $$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "int");
			$$->setAssemblyCode(asmCode);
			$$->setAssemblySymbol(temp);
			
			
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		;
					
term :	unary_expression
    {
		fprintf(logout,"Line %d: term : unary_expression\n",line_count);
		$$ = $1;
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	|  term MULOP unary_expression
    {
		string op = $2->getName();
		string retType = "error";

		if(op == "%") {
			if(($1->getType() != "int") || ($3->getType() != "int")) {
				errorCount++;
				fprintf(logout, "Error at line %d: operands of modulus operator must be integer\n", line_count);
				fprintf(errorout, "Error at line %d: operands of modulus operator must be integer\n", line_count);
			}
			else if($3->getName() == "0") {
				errorCount++;
				fprintf(logout, "Error at line %d: Modulus by zero\n", line_count);
				fprintf(errorout, "Error at line %d: Modulus by zero\n", line_count);
			}
			else retType = "int";
		}
		else if(op == "*" || op == "/") {
			if((op == "/") && ($3->getName() == "0")) {
				errorCount++;
				fprintf(logout, "Error at line %d: Division by zero\n", line_count);
				fprintf(errorout, "Error at line %d: Division by zero\n", line_count);
			}
			else {
				if(($1->getType() == "float") || ($3->getType() == "float")) retType = "float";
				else retType = "int";
			}
		}

		string temp = newTemp();
		string asmCode = $1->getAssemblyCode() + $3->getAssemblyCode();
		if(op == "*") {
			//if($3->getName() != "1")
				asmCode += "\tMOV AX, " + $1->getAssemblySymbol() + "\n\tMOV BX, " + $3->getAssemblySymbol() + "\n\tIMUL BX\n\tMOV " + temp + ", AX\n";
			//else asmCode += "\t; Multiplying by 1 is redundant\n";
		}
		else {
			//if($3->getName() != "1") {
				asmCode += "\tMOV AX, " + $1->getAssemblySymbol() + "\n\tCWD\n\tMOV BX, " + $3->getAssemblySymbol() + "\n\tIDIV BX\n";
				if(op == "/") { asmCode += "\tMOV " + temp + ", AX\n";}
				else { asmCode += "\tMOV " + temp + ", DX\n"; }
			//}
			
		}

		fprintf(logout,"Line %d: term : term MULOP unary_expression\n",line_count);

		$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), retType);
		$$->setAssemblyCode(asmCode);
		$$->setAssemblySymbol(temp);

		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	;

unary_expression : ADDOP unary_expression  
		{
			fprintf(logout,"Line %d: unary_expression : ADDOP unary_expression\n",line_count);

			string temp, asmCode;
			if($1->getName() == "-") {
				temp = newTemp();
				asmCode = $2->getAssemblyCode() + "\tMOV AX, " + $2->getAssemblySymbol() + "\n\tMOV " + temp + ", AX\n\tNEG " + temp + "\n";
			}
			else {
				temp = $2->getAssemblySymbol();
				asmCode = $2->getAssemblyCode();
			}

			$$ = new SymbolInfo($1->getName() + $2->getName(), $2->getType());
			$$->setAssemblyCode(asmCode);
			$$->setAssemblySymbol(temp);

			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		| NOT unary_expression 
		{
			fprintf(logout,"Line %d: unary_expression : NOT unary_expression\n",line_count);

			string asmCode = "";
			string temp;
			string r0 = newLabel();
			string r1 = newLabel();
			asmCode += $2->getAssemblyCode();
			asmCode += "\tMOV AX, " + $2->getAssemblySymbol() + "\n";
			asmCode += "\tCMP AX, 0\n";
			asmCode += "\tJE " + r1 + "\n";
			asmCode += "\tMOV AX, 0\n";
			asmCode += "\tMOV " +  temp + ", AX\n";
			asmCode += "\tJMP " + r0 + "\n";
			asmCode += r1 + ":\n";
			asmCode += "\tMOV AX, 1\n";
			asmCode += "\tMOV " + temp + ", AX\n";
			asmCode += r0 + ":\n";

			$$ = new SymbolInfo("!" + $2->getName(), $2->getType());
			$$->setAssemblyCode(asmCode);
			$$->setAssemblySymbol(temp);

			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		| factor 
		{
			fprintf(logout,"Line %d: unary_expression : factor\n",line_count);
			$$ = $1;
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		;
	
factor	: variable 
	{
		fprintf(logout,"Line %d: factor : variable\n",line_count);
		$$ = $1;
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| ID LPAREN argument_list RPAREN
	{
		SymbolInfo *s = symbolTable.lookUp($1->getName());
		string asmCode = "";
		string temp;
		if(s == nullptr) {
			errorCount++;
			fprintf(logout, "Error at line %d: function %s not declared or defined\n", line_count, $1->getName().c_str());
			fprintf(errorout, "Error at line %d: function %s not declared or defined\n", line_count, $1->getName().c_str());
		} else {
			if(s->getIdentity() == "function") {
				vector<string> argNames = splitString($3->getName(), ',');
				vector<string> argTypes = splitString($3->getType(), ',');
				vector<string> asmSymbols = splitString($3->getAssemblySymbol(), ',');
				vector<SymbolInfo*> sList = s->getParameterList();
				//cout << "yez1 " << s->getParameterList()[0]->getType() << " " << s->getType() << endl;
				//cout << "yez2 " << sList[0]->getName() << " " << sList[1]->getType() << endl;
				//if(s->getType() == "void") {
				//	errorCount++;
				//	fprintf(logout, "Error at line %d: factor cannot be void function\n", line_count);
				//	fprintf(errorout, "Error at line %d: factor cannot be void function\n", line_count);
				//}
				if(sList.size() != argNames.size()) {
					errorCount++;
					fprintf(logout, "Error at line %d: Number of arguments do not match\n", line_count);
					fprintf(errorout, "Error at line %d: Number of arguments do not match\n", line_count);
				}
				else {
					for(int i=0; i<argNames.size(); i++) {
						if(argTypes[i] != sList[i]->getType()) {
							fprintf(errorout, "%s ...%s, %s ", argTypes[i].c_str(), sList[i]->getType().c_str(), sList[i]->getType().c_str());
							errorCount++;
							fprintf(logout, "Error at line %d: Argument types do not match\n", line_count);
							fprintf(errorout, "Error at line %d: Argument types do not match\n", line_count);
						}
					}

					asmCode += "\tPUSH AX\n";
					asmCode += "\tPUSH BX\n";
					asmCode += "\tPUSH CX\n";
					asmCode += "\tPUSH DX\n";

					int c = asmSymbols.size();
					while(c--) { asmCode += "\tPUSH " + asmSymbols[c] + "\n";}

					asmCode += "\tCALL " + s->getName() + "\n";
					temp = newTemp();
					asmCode += "\tPOP " + temp + "\n";

					asmCode += "\tPOP DX\n";
					asmCode += "\tPOP CX\n";
					asmCode += "\tPOP BX\n";
					asmCode += "\tPOP AX\n";
				}
			} else {
				errorCount++;
				fprintf(logout, "Error at line %d: ID is not function\n", line_count);
				fprintf(errorout, "Error at line %d: ID is not function\n", line_count);
			}
		}
		fprintf(logout,"Line %d: factor : variable\n",line_count);

		$$ = new SymbolInfo($1->getName() + "(" + $3->getName() + ")",	s->getType());
		$$->setAssemblyCode(asmCode);
		$$->setAssemblySymbol(temp);

		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| LPAREN expression RPAREN
	{
		fprintf(logout,"Line %d: factor : LPAREN expression RPAREN\n",line_count);
		
		$$ = new SymbolInfo("(" + $2->getName() + ")",	$2->getType());
		$$->setAssemblyCode($2->getAssemblyCode());
		$$->setAssemblySymbol($2->getAssemblySymbol());

		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| CONST_INT 
	{
		fprintf(logout,"Line %d: factor : CONST_INT\n",line_count);
		$$ = yylval.var;
		$$->setAssemblySymbol(yylval.var->getName());
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| CONST_FLOAT
	{
		fprintf(logout,"Line %d: factor : CONST_FLOAT\n",line_count);
		$$ = yylval.var;
		$$->setAssemblySymbol(yylval.var->getName());
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| variable INCOP 
	{
		fprintf(logout,"Line %d: factor : variable INCOP\n",line_count);

		$$ = new SymbolInfo($1->getName() + "++",	$1->getType());
		string temp = newTemp();
		string asmCode = $1->getAssemblyCode() + "\tMOV AX, " + $1->getAssemblySymbol() + "\n\tMOV " + temp + ", AX\n\tINC " + $1->getAssemblySymbol() + "\n";
		$$->setAssemblyCode(asmCode);
		$$->setAssemblySymbol(temp);

		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| variable DECOP
	{
		fprintf(logout,"Line %d: factor : variable DECOP\n",line_count);

		$$ = new SymbolInfo($1->getName() + "--",	$1->getType());
		string temp = newTemp();
		string asmCode = $1->getAssemblyCode() + "\tMOV AX, " + $1->getAssemblySymbol() + "\n\tMOV " + temp + ", AX\n\tDEC " + $1->getAssemblySymbol() + "\n";
		$$->setAssemblyCode(asmCode);
		$$->setAssemblySymbol(temp);
		
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	;
	
argument_list : arguments
			  {
				fprintf(logout,"Line %d: argument_list : arguments\n",line_count);
				$$ = $1;
				fprintf(logout, "%s\n", $$->getName().c_str());
			  }
			  |
			  {
				fprintf(logout,"Line %d: arguments_list : \n",line_count);
				$$ = new SymbolInfo("", "void");
				fprintf(logout, "%s\n", $$->getName().c_str());
			  }
			  ;
	
arguments : arguments COMMA logic_expression
	      {
				fprintf(logout,"Line %d: arguments : arguments COMMA logic_expression\n",line_count);
				
				$$ = new SymbolInfo($1->getName() + "," + $3->getName(), $1->getType() + "," + $3->getType());
				$$->setAssemblyCode($1->getAssemblyCode() + $3->getAssemblyCode());
				$$->setAssemblySymbol($1->getAssemblySymbol() + "," + $3->getAssemblySymbol());

				fprintf(logout, "%s\n", $$->getName().c_str());
		  }
		  | logic_expression
	      {
				fprintf(logout,"Line %d: arguments : logic_expression\n",line_count);
				$$ = $1;
				fprintf(logout, "%s\n", $$->getName().c_str());
		  }
		  ;
 

%%
int main(int argc,char *argv[])
{

	cout << "start";
	if((fp = fopen(argv[1],"r")) == nullptr)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	logout = fopen("log.txt", "w");
	errorout = fopen("error.txt", "w");
	asmFile = fopen("code.asm", "w");
	
	cout << "start";

	yyin = fp;
	yyparse();
	

	fclose(logout);
	fclose(errorout);
	fclose(asmFile);

	// optimization
	opAsmFile = fopen("optimized_code.asm", "w");
	string codeString;
	vector<string> codeVector;
	ifstream fileTemp("code.asm");
    while (getline(fileTemp, codeString)) { codeVector.push_back(codeString); }
	optimize(codeVector);

	fclose(opAsmFile);

	cout << "succes";
	
	return 0;
}

