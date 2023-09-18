
set this_script=prompt_init.csh

if (! $?BBTB_ROOT ) then

    # make sure this is being sourced and not executed
    if ( "$0" =~ '*'$this_script ) then
       echo "Error: this script should only be sourced, never executed directly.  Aborting.  ($0)"
       exit 1
    endif

    # use proc to find out the path to the script we are sourcing.
    if ( -e /proc ) then
      set script_path=`/usr/bin/env -i /bin/ls -1 /proc/$$/fd -l | /bin/grep /$this_script | /bin/awk '{print $11}'`
      if ($status != 0) then
         echo "Error: Could not find source code path using /proc method.  Aborting $$. ($this_script)"
         exit 1
      endif
    else
      echo "Error: /proc does not exist.  Is this Linux?"
      exit 1
    endif

    set script_dir=`dirname $script_path`

    setenv BBTB_ROOT $script_dir:q

endif

alias precmd 'source $BBTB_ROOT/setprompt.csh'
alias reprompt 'source $BBTB_ROOT/prompt_init.csh'
setenv p 'eval $BBTB_ROOT/setprompt.rb'
alias title 'setenv SETPROMPT_BANNER "\!*"'

