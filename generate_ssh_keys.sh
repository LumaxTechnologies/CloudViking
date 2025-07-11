#!/bin/bash

# Check if exactly one argument was passed
if [ "$#" -ne 1 ]; then
  echo "Error: Provide a customer's name." >&2
  echo "Usage: $0 <CUSTOMER>" >&2
  exit 1
fi

# If valid, print the argument
echo "Your customer's name: $1"

ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_${1} -N ""

chmod 600 ~/.ssh/id_${1}
