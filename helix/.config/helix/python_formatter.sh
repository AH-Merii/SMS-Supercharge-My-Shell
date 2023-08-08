#!/bin/bash

# Check if there are any arguments
if [ "$#" -eq 0 ]; then
    isort --profile black . && black . "--quiet","--line-length=88"
    exit 1
fi

isort --profile black $1 && black $1 "--quiet","--line-length=88"
