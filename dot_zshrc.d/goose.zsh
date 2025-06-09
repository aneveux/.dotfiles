#!/bin/bash

function goose() {
    if [ -z "$OPENAI_API_KEY" ]; then 
        export OPENAI_API_KEY=$(pass openai)
    fi
    "$HOME/.local/bin/goose" "$@"
}

