if ( ! $?BBTB_ROOT ) then
    echo "set bbtb_root"
    exit 1
endif

setenv PROMPT_CMD "$BBTB_ROOT/setprompt.rb -p"
set prompt="`$PROMPT_CMD`> [%h] "
