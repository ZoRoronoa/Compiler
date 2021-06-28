#ifndef __NODE_C__
#define __NODE_C__


//语法结点定义
/*
    label: 标签
    linenum：所在行号
    cnt：包含的子结点个数
    isLexical：是否为词法单元（语法单元需要标记行号）
    child：子结点数组
*/
typedef struct node{
    char * label;
    int linenum;
    int cnt;
    int isLexical;
    struct node* child[20];
}node;


node * newNode(char * label, int linenum, int cnt, ...){
    node * tmp = (node*)malloc(sizeof(node));
    tmp->label = (char *)malloc((strlen(label) + 3)*sizeof(char));
    strcpy(tmp->label, label);
    va_list vl;
    va_start(vl, cnt);
    tmp->cnt = cnt;
    // 默认是语法单元
    tmp->isLexical = 0;
    if(linenum){
        tmp->linenum = linenum;
        tmp->isLexical = 1;
    }
    else tmp->linenum = 0x3f3f3f3f;
    for(int i = 0; i < cnt; i++){
        tmp->child[i] = va_arg(vl, node*);
        if(tmp->child[i]){
            if(tmp->child[i]->linenum < tmp->linenum) tmp->linenum = tmp->child[i]->linenum;  
            // 父结点的行号为所有子结点行号中最小值，子结点的行号通过词法结点递归生成
        }
    }
    va_end(vl);
    return tmp;
}

#endif