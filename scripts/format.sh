cmd="clang-format"
echo $cmd
find . -type d \( -path ./opt -o -path ./dist \) -prune -o -name "*.lsl" -print | xargs "$cmd" -i --verbose 
