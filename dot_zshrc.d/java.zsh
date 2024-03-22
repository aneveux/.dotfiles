if asdf current java > /dev/null 2>&1
then
    export JAVA_HOME=$(asdf where java)
fi
