%error-verbose
%{
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include "node.c"
#define YYSTYPE node *
extern FILE* yyin;

int lineno = 0;
int islegal = 1;
int yylex();

void llerror(const char * msg){
    islegal = 0;
    fprintf(stderr, "Error type A at Line %d: %s\n", lineno, msg);
}

void yyerror(const char * msg){
    islegal = 0;
    fprintf(stderr, "Error type B at Line %d: %s\n", lineno, msg);
}

void moveToNextLine(){
    lineno++;
}

void printTree(node * root, int level){
    if(!islegal) exit(1);
    for(int i = i = 0; i < level; i++) printf("  ");
	/*
	int toPrint = 1;
	char * tmp = (char *)malloc((strlen(root->label) + 3)*sizeof(char));
	strcpy(tmp, root->label);
	if(strlen(tmp) >= 3 && tmp[0] == 'I' && tmp[1] == 'N' && tmp[2] == 'T') toPrint = 0;
	else if(strlen(tmp) >= 3 && tmp[0] == 'F' && tmp[1] == 'L' && tmp[2] == 'O' && tmp[3] == 'A' && tmp[4] == 'T') toPrint = 0;
	else if(strlen(tmp) >= 2 && tmp[0] == 'I' && tmp[1] == 'D') toPrint = 0;
	else if(strlen(tmp) >= 4 && tmp[0] == 'T' && tmp[1] == 'Y' && tmp[2] == 'P' && tmp[3] == 'E') toPrint = 0;
	if(root->isLexical) toPrint = 0;
	*/
	printf("%s", root->label);
	if(!root->isLexical) printf(" (%d)", root->linenum);
	printf("\n");
    for(int i = 0; i < root->cnt; i++){
        if(root->child[i]) printTree(root->child[i], level + 1);
    }
}
%}


// 终结符定义
%token INT FLOAT ID SEMI COMMA ASSIGNOP RELOP PLUS MINUS STAR DIV AND OR DOT NOT TYPE LP RP LB RB LC RC STRUCT RETURN IF ELSE WHILE CBEGIN CEND


%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
%right ASSIGNOP
%left OR
%left AND
%left RELOP
%left PLUS MINUS
%left STAR DIV
%left LP RP LB RB DOT

%%
/* error: 预留符 */
Program : ExtDefList {$$ = newNode("Program", 0, 1, $1);printTree($$, 0);}
		;
ExtDefList : ExtDef ExtDefList {$$ = newNode("ExtDefList", 0, 2, $1, $2);}
		   |  {$$ = NULL;}
		   ;
ExtDef : Specifier ExtDecList SEMI {$$ = newNode("ExtDef", 0, 3, $1, $2, $3);}
	   | Specifier SEMI {$$ = newNode("ExtDef", 0, 2, $1, $2);}
	   | Specifier FunDec CompSt {$$ = newNode("ExtDef", 0, 3, $1, $2, $3);}
	   ;
ExtDecList : VarDec {$$ = newNode("ExtDecList", 0, 1, $1);};
		   | VarDec COMMA ExtDecList {$$ = newNode("ExtDecList", 0, 3, $1, $2, $3);}
		   ;
Specifier : TYPE {$$ = newNode("Specifier", 0, 1, $1);}
		  | StructSpecifier {$$ = newNode("StructSpecifier", 0, 1,  $1);}
		  ;
StructSpecifier : STRUCT OptTag LC DefList RC {$$ = newNode("StructSpecifier", 0, 5, $1, $2, $3, $4, $5);}
				| STRUCT OptTag LC error RC {}
				| STRUCT Tag {$$ = newNode("StructSpecifier", 0, 2, $1, $2);}
				;
OptTag : ID {$$ = newNode("OptTag", 0, 1, $1);}
	   | {$$ = NULL;}
	   ;
Tag : ID {$$ = newNode("Tag", 0, 1, $1);}
	;
VarDec : ID {$$ = newNode("VarDec", 0, 1, $1);}
	   | ID VarDimList {$$ = newNode("VarDec", 0, 2, $1, $2);}
	   ;
// 注意：小改一下数组的声明 产生式
VarDimList : LB INT RB {$$ = newNode("VarDimList", 0, 3, $1, $2, $3);}
		   | LB INT RB VarDimList {$$ = newNode("VarDimList", 0, 4, $1, $2, $3, $4);}
           | LB error RB {}
           ;
FunDec : ID LP VarList RP {$$ = newNode("FunDec", 0, 4, $1, $2, $3, $4);}
	   | ID LP RP {$$ = newNode("FunDec", 0, 3, $1, $2, $3);}
	   | ID LP error RP {
		}
	   ;
VarList : ParamDec COMMA VarList {$$ = newNode("VarList", 0, 3, $1, $2, $3);}
		| ParamDec {$$ = newNode("VarList", 0, 1, $1);}
		| ParamDec error {}
		;
ParamDec : Specifier VarDec {$$ = newNode("ParamDec", 0, 2, $1, $2);}
		 ;
CompSt : LC DefList StmtList RC {$$ = newNode("CompSt", 0, 4, $1, $2, $3, $4);}
	   | LC error DefList StmtList RC {}  // <== MARK TODO
	   ;
StmtList : Stmt StmtList {$$ = newNode("StmtList", 0, 2, $1, $2);}
		 | {$$ = NULL;}
		 ;
Stmt : Exp SEMI {$$ = newNode("Stmt", 0, 2, $1, $2);}
	 | CompSt {$$ = newNode("Stmt", 0, 1, $1);}
	 | RETURN Exp SEMI {$$ = newNode("Stmt", 0, 3, $1, $2, $3);}
	 | IF LP Exp RP Stmt %prec LOWER_THAN_ELSE {$$ = newNode("Stmt", 0, 5, $1, $2, $3, $4, $5);}
	 | IF LP Exp RP Stmt ELSE Stmt {$$ = newNode("Stmt", 0, 7, $1, $2, $3, $4, $5, $6, $7);}
	 | IF LP error RP {
		}
	 | WHILE LP Exp RP Stmt {$$ = newNode("Stmt", 0, 5, $1, $2, $3, $4, $5);}
	 | Exp error {
		}
	 | IF error {
		}
	 | WHILE error {
		}
	 | WHILE LP error RP{
		}
	 ;
DefList : Def DefList {$$ = newNode("DefList", 0, 2, $1, $2);}
		| /* empty */ {$$ = NULL;}
		;
Def : Specifier DecList SEMI {$$ = newNode("Def", 0, 3, $1, $2, $3);}
	;
DecList : Dec {$$ = newNode("DecList", 0, 1, $1);}
		| Dec COMMA DecList {$$ = newNode("DecList", 0, 3, $1, $2, $3);}
		;
Dec : VarDec ASSIGNOP Exp {$$ = newNode("VarDec", 0, 3, $1, $2, $3);}
	| VarDec {$$ = newNode("Dec", 0, 1, $1);}
	;
Exp : Exp ASSIGNOP Exp {$$ = newNode("Exp", 0, 3, $1, $2, $3);}
	| Exp AND Exp {$$ = newNode("Exp", 0, 3, $1, $2, $3);}
	| Exp OR Exp {$$ = newNode("Exp", 0, 3, $1, $2, $3);}
	| Exp RELOP Exp {$$ = newNode("Exp", 0, 3, $1, $2, $3);}
	| Exp PLUS Exp {$$ = newNode("Exp", 0, 3, $1, $2, $3);}
	| Exp MINUS Exp {$$ = newNode("Exp", 0, 3, $1, $2, $3);}
	| Exp STAR Exp {$$ = newNode("Exp", 0, 3, $1, $2, $3);}
	| Exp DIV Exp {$$ = newNode("Exp", 0, 3, $1, $2, $3);}
	| LP Exp RP {$$ = newNode("Exp", 0, 3, $1, $2, $3);}
	| MINUS Exp %prec STAR {$$ = newNode("Exp", 0, 2, $1, $2);}
	| NOT Exp {$$ = newNode("Exp", 0, 2, $1, $2);}
	| ID LP Args RP {$$ = newNode("Exp", 0, 4, $1, $2, $3, $4);}
	| ID LP error RP{
	}
	| ID LP RP {$$ = newNode("Exp", 0, 3, $1, $2, $3);}
	| Exp LB Exp RB {$$ = newNode("Exp", 0, 4, $1, $2, $3, $4);}
	| Exp LB error RB {
	}
	| Exp DOT ID {$$ = newNode("Exp", 0, 3, $1, $2, $3);}
	| ID {$$ = newNode("Exp", 0, 1, $1);}
	| INT {$$ = newNode("Exp", 0, 1, $1);}
	| FLOAT {$$ = newNode("Exp", 0, 1, $1);}
	;
Args : Exp COMMA Args {$$ = newNode("Args", 0, 3, $1, $2, $3);}
	 | Exp {$$ = newNode("Args", 0, 1, $1);}
	 ;
%%

#include "flex.c"

int main(int argc, char **argv){
	if (argc == 2){
		yyin = fopen(argv[1], "r");
	}
	else{
        return -1;
	}
	moveToNextLine();
	yyparse();
}