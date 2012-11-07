#!/bin/bash
################################################################################
#                                                                              # 
#       dev-env.sh - Source this script for ModelSEED development              #
#                                                                              # 
#       This will update your enviornment's PATH and PERL5LIB variables        #
#       to point into the ModelSEED repository. You would want to do this      #
#       if you are actively developing the ModelSEED code and don't want to    #
#       run ./Build install all the time.                                      #
#                                                                              # 
################################################################################
# env_push enviornment-variable value
env_push() {
    eval value=\$$1
    if [[ $value = "" ]]; then
        export $1=$2
    elif [ -d "$2" ]; then
        tmp=$(echo $value | tr ':' '\n' | awk '$0 != "'"$2"'"' | paste -sd: -)
        if [[ $tmp = "" ]]; then export $1=$2; else export $1=$2:$tmp; fi
    fi
}
# Find the target directorys ( the directory that this file is in )
# and the directory ../lib relative to it.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DIR="$( cd $SCRIPT_DIR/../ && pwd)"
env_push PERL5LIB $DIR/lib;
env_push PATH $SCRIPT_DIR
export PERL5LIB
export PATH;
export MODEL_SEED_CORE=$DIR;
. setup-bash-complete
