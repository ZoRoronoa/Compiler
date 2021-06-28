%x comment
INT [0-9]|[1-9]([0-9]+)
HEXINT 0[xX][0-9a-fA-F]+
OCTINT 0[0-7]+
ERROCT 0[0-9]+
ERRHEX 0[xX][0-9a-zA-Z_]+
DIGIT [0-9]
FLOAT	(({INT}(\.{DIGIT}*)?|\.{DIGIT}+)([eE][+-]?{DIGIT}+)|({INT}?\.{DIGIT}+)|({INT}\.{DIGIT}*))
ERRFLOAT ({INT}(\.{DIGIT}*)?|\.{DIGIT}+)([eE])
ID [a-zA-Z_]([a-zA-Z0-9_]*)
TYPE (int|float)
STRUCT (struct)
RETURN (return)
IF (if)
ELSE (else)
WHILE (while)
ERRWORD ([a-zA-Z0-9_]+)
ANYWORD (.*)

%%
"//"{ANYWORD}"\n" {
    yylval = NULL;
	moveToNextLine();
}
[\t ] {
    yylval = NULL;
}
{TYPE} {
    char buf[1024];
    sprintf(buf, "TYPE: %s", yytext);
    yylval = newNode(buf, lineno, 0);
    return TYPE;
}
{IF} {yylval = newNode("IF", lineno, 0);return IF;}
{ELSE} {yylval = newNode("ELSE", lineno, 0);return ELSE;}
{WHILE} {yylval = newNode("WHILE", lineno, 0);return WHILE;}
{RETURN} {yylval = newNode("RETURN", lineno, 0);return RETURN;}
{STRUCT} {yylval = newNode("STRUCT", lineno, 0);return STRUCT;}
{INT} {
    char buf[1024];
    sprintf(buf, "INT: %s", yytext);
    yylval = newNode(buf, lineno, 0);
    return INT;
}
{HEXINT} {
    char buf[1024];
    int val;
    sscanf(yytext, "%x", &val);
    sprintf(buf, "INT: %d", val);
    yylval = newNode(buf, lineno, 0);
    return INT;
}
{OCTINT} {
    char buf[1024];
    int val;
    sscanf(yytext, "%o", &val);
    sprintf(buf, "INT: %d", val);
    yylval = newNode(buf, lineno, 0);
    return INT;
}
{ERRHEX} {
    char buf[1024];
    int val;
    sprintf(buf, "'%s' might be a wrong hex integer.", yytext);
    llerror(buf);
    yylval = newNode(buf, lineno, 0);
    return INT;
}
{ERROCT} {
    char buf[1024];
    int val;
    sprintf(buf, "'%s' might be a wrong oct integer.", yytext);
    llerror(buf);
    yylval = newNode(buf, lineno, 0);
    return INT;
}
{FLOAT} {
    char buf[1024];
    sprintf(buf, "FLOAT: %.8lf", atof(yytext));
    yylval = newNode(buf, lineno, 0);
    return FLOAT;
}
{ERRFLOAT} {
    char buf[1024];
    int val;
    sprintf(buf, "'%s' might be a wrong float.", yytext);
    llerror(buf);
    yylval = newNode(buf, lineno, 0);
    return INT;
}
{ID} {
    char buf[1024];
    sprintf(buf, "ID: %s", yytext);
    yylval = newNode(buf, lineno, 0);
    return ID;
}
"/*" {yylval = NULL;BEGIN(comment);}
<comment>"*"+"/" {yylval = NULL;BEGIN(INITIAL);}
<comment>\n {yylval = NULL;moveToNextLine();}
<comment>. {yylval = NULL;}
";" {
    yylval = newNode("SEMI", lineno, 0);
    return SEMI;
}
"," {
    yylval = newNode("COMMA", lineno, 0);
    return COMMA;
}
"=" {
    yylval = newNode("ASSIGNOP", lineno, 0);
    return ASSIGNOP;
}
">"|"<"|">="|"<="|"=="|"!=" {
    yylval = newNode("RELOP", lineno, 0);
    return RELOP;
}
"+" {
    yylval = newNode("PLUS", lineno, 0);
    return PLUS;
}
"-" {
    yylval = newNode("MINUS", lineno, 0);
    return MINUS;}
"*" {
    yylval = newNode("STAR", lineno, 0);
    return STAR;}
"/" {
    yylval = newNode("DIV", lineno, 0);
    return DIV;}
"&&" {
    yylval = newNode("AND", lineno, 0);
    return AND;}
"||" {
    yylval = newNode("OR", lineno, 0);
    return OR;}
"." {
    yylval = newNode("DOT", lineno, 0);
    return DOT;}
"!" {
    yylval = newNode("NOT", lineno, 0);
    return NOT;}
"(" {
    yylval = newNode("LP", lineno, 0);
    return LP;}
")" {
    yylval = newNode("RP", lineno, 0);
    return RP;}
"[" {
    yylval = newNode("LB", lineno, 0);
    return LB;}
"]" {
    yylval = newNode("RB", lineno, 0);
    return RB;}
"{" {
    yylval = newNode("LC", lineno, 0);
    return LC;}
"}" {
    yylval = newNode("RC", lineno, 0);
    return RC;}
\n {
    yylval = NULL;
	moveToNextLine();
}
"*/" {
    yylval = NULL;
    char buf[1024];
    sprintf(buf, "Missing left part of block comment");
	llerror(buf);
    yylval = NULL;
}
{ERRWORD} {
    char buf[1024];
    sprintf(buf, "Invalid identifier: %s", yytext);
    llerror(buf);
    sprintf(buf, "ERRWORD: %s", yytext);
    yylval = newNode(buf, lineno, 0);
    return ID;
}
. {
    char buf[1024];
    sprintf(buf, "Mysterious character: %c", yytext[0]);
	llerror(buf);
    yylval = NULL;
}
