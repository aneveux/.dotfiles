#!/bin/bash

function mods() {
    if [ -z "$OPENAI_API_KEY" ]; then 
        export OPENAI_API_KEY=$(pass openai)
    fi
    /usr/bin/mods "$@"
}

