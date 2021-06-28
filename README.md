#### Forest Compiler Assignment

---

##### 1. 系统环境

Ubuntu 20.04 LTS | GNU flex 2.6.4 | GNU bison 3.5.1 | GCC 5.4.0

##### 2.系统使用

在当前目录键入`./Makefile`即可完成编译，目录下生成`forest`程序。然后输入命令`./forest file_path`，其中`file_path`指定要分析的文件路径。编译之后若想重新编译，请先执行`./clean`。

##### 3. 功能介绍

1. 基础功能

   能够完成词法分析和语法分析，在词法、语法无误的情况下，能够按格式输出语法树，不再详述。

2. 错误检查

   词法错误：

   1. 错误的16进制、错误的8进制、错误的浮点数

      以16进制为例，对`INT`，`HEXINT`和`ERRHEX`的正则表达式分别如下：

      ```assembly
      INT [0-9]|[1-9]([0-9]+)         // 一般的十进制INT表示
      HEXINT 0[xX][0-9a-fA-F]+　　　　 // 一般的16进制表示
      ERRHEX 0[xX][0-9a-zA-Z_]+      //  错误的16进制表示
      ```
   
      在检测到`INT`或者`HEXINT`之后都正常地生成一个INT类型的结点，而检测到`ERRHEX`之后则抛出词法错误，如输入`0x5f5h`，此时抛出错误为：

      ```ABAP
      Error type A at Line 3: '0x5f5h' might be a wrong hex integer.
      ```
   
      8进制和浮点数同理，不过错误的浮点数难以用正则完全表达出来，这里只假设可能的某种情况，表达式为：`ERRFLOAT ({INT}(\.{DIGIT}*)?|\.{DIGIT}+)([eE])`，即数字中出现了`e|E`，但不符合科学计数法的表示方法，如输入`1.5e`，抛出错误为：

      ```ABAP
      Error type A at Line 3: '1.5e' might be a wrong float.
      ```
   
   2. 错误的标识符、未定义的字符

      两者的正则定义分别是：

      ```assembly
      ERRWORD ([a-zA-Z0-9_]+)        // 非法的标识符
      ANYWORD (.*)	               // 未定义字符
      ```
   
      考虑到flex采用的最先匹配原则，将这两个模式放在正则定义区的最后，配合上述正则即可完成相应功能，测试如下（输入非法标识符`123test`和字符`~`）

      ```ABAP
      Error type A at Line 3: Invalid identifier: 123test
      Error type A at Line 4: Mysterious character: ~
      ```
   
   语法错误：

   对于语法规则，bison提供了语法错误检查机制。不过，如果简单地使用bison会存在以下问题：

   1. 在当前状态下，面对当前的终结符不能进行任何规约或移进，则产生语法错误。一个语法错误，可能导致后面正常的程序无法分析，而且后面的错误无法处理。
   2. 语法错误一律报`syntax error`，不够具体。
   
   对于第一个问题，使用bison提供的错误处理机制，通过预留终结符error提供状态恢复分析的机制，通过设计错误恢复规则，可一定程度避免对后续程序分析的影响，比如：

   ``` assembly
   FunDec : ID LP error RP // 函数定义，若括号内参数列表出错，则遇到右括号RP完成恢复  
   Stmt : IF LP error RP   // 语句块，if内部出现语法错误，遇到右括号RP完成恢复
   ...                     // 许多其他类似定义
   ```
   
   对于第二个问题，通过添加声明指令`%error-verbose`，可供语法错误更加详细的信息（错误源自声明的产生式规则，所以不可避免地，有些地方有些生硬）。

   关于以上两个问题的处理，有以下例子：
   
   ```c++
        1  int main()
        2  {
        3      int a = array[1 , 2]; // 数组出错
        4      int a = max(x y);     // 函数调用内部出错
        5      if (a == ) a = 0;   // if表达式内部出错
        6  }
        7
        8  int max(int a, b);         //函数定义，参数列表错误
   ```
   
   ```assembly
   Error type B at Line 3: syntax error, unexpected COMMA
   Error type B at Line 4: syntax error, unexpected ID, expecting RP
   Error type B at Line 5: syntax error, unexpected RP
   Error type B at Line 8: syntax error, unexpected ID, expecting TYPE or STRUCT
   ```

##### 4. 总体设计

语法结点树的结构描述：

```c++
typedef struct node{
    char * label;           //label: 标签
    int linenum;		    //linenum：所在行号
    int cnt;                //cnt：包含的子结点个数
    int isLexical;          //isLexical：是否为词法单元（语法单元需要标记行号）
    struct node* child[20]; //child：子结点数组
}node;
```

语法结点的结构体设计，以及语法结点的生成函数，在词法分析和语法分析中均有用到，是整个程序串联起来的基础。好的设计能使程序更加简洁。

程序的整体设计思路是：词法分析过程中生成词法结点，在语法分析中再递归生成上层语法结点，更新它们的信息，在整个过程中提供相应的错误检查，无误的情况下，输出语法树。

1. 词法分析

   主要内容在`flex.l`中，包括各词法单元的正则表达式定义，以及各`pattern`触发的`action`定义。在词法单元生成过程中，需要确定上述结构体中的`label`、`linenum`、`isLexical`，不存在子结点。

2. 语法分析

   主要内容在`bison.y`中，包括文法规则和语义动作定义。在语义动作定义中，主要完成的动作是根据产生式规则，构建语法树。对具体的结点，确定上述结构体中的`label`， `isLexical` ，`cnt`和`child`，行号`linenum`的确定规则是：父结点的所有子结点中，最小的行号即为该父结点的行号。通过这一规则递归填充所有结点的相关信息。

3. 正则表达式设计：不再详述

4. 产生式规则设计：产生式规则基本上由CMINUS的文法给定。

##### 5. 亮点设计

1. C语言函数可变参数

   C函数可变参数，可变参数通过`···`传参，在函数体内通过宏`va_start`、`va_end`以及`va_list`结合使用。在实验中，由于C没有直接提供函数重载功能，所以我们需要通过可变参数来实现此功能。具体使用场景为，由一个语法结点生成多个子结点时，子结点的数目不固定，在语法结点生成函数中，使用：

   ```c
   node * newNode(char * label, int linenum, int cnt, ...)
   ```

   可以极大地简化函数的编写。

2. 注释的处理

   注释的处理，在词法分析中进行，分为行注释和块注释。

   行注释：用正则表达式确定，即`"//"{ANYWORD}"\n"`

   块注释：不需要使用复杂的正则表达式，根据flex提供的BEGIN宏，可以实现状态之间的转移。设置comment 为注释状态，INITIAL为初始状态（默认）。部分代码展示：

   ```assembly
   "/*" {yylval = NULL;BEGIN(comment);}                  // 注释状态的进入
   <comment>"*"+"/" {yylval = NULL;BEGIN(INITIAL);}      // 注释状态的退出
   <comment>\n {yylval = NULL;moveToNextLine();}		 // 块注释遇到换行，仅增加行号 
   <comment>. {yylval = NULL;}                           // 块注释遇到任意字符，忽略
   ```

   另：考虑到程序要求给出不符合定义的注释所引发的提示信息，对缺少左半部分的块注释，需要对其右半部分注释进行识别和处理，抛出错误如：
   
   ```c++
   5 /* /* */ */
   ```
   
   ```assembly
   Error type A at Line 5: Missing left part of block comment
   ```
   
3. 错误处理

   上述提及的错误检查，包括基本的词法错误处理，和语法错误的处理。









