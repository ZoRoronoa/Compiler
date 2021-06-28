bison -v bison.y
flex -o flex.c flex.l
gcc bison.tab.c -O2 -ll -o forest
echo "[INFO] building forest..."
echo "[INFO] input \"./forest filepath\" to test, e.g. \"./forest t.txt\""
