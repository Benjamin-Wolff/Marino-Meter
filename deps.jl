#!/bin/bash
#=
JULIA="${JULIA:-julia}"
JULIA_CMD="${JULIA_CMD:-$JULIA --color=yes --startup-file=no}"
export JULIA_PROJECT="$(dirname ${BASH_SOURCE[0]})"
export JULIA_LOAD_PATH=@:@stdlib  # exclude default environment
exec $JULIA_CMD -e 'include(popfirst!(ARGS))' "${BASH_SOURCE[0]}" "$@"
=#

import Pkg

PACKAGES = ["Pkg", "HTTP", "Gumbo", "Cascadia", "Dates", "PrettyPrint", "Mongoc", "ArgParse"]

Pkg.add(PACKAGES)