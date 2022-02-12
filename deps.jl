#!/bin/bash

using Pkg

PACKAGES = [
    "Pkg", 
    "HTTP", 
    "Gumbo", 
    "Cascadia", 
    "Dates", 
    "PrettyPrint", 
    "Mongoc", 
    "ArgParse"
    ]

Pkg.add(PACKAGES)