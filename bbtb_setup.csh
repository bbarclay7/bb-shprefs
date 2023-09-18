set this_script=bbtb_setup.csh

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


setenv LS_COLORS 'no=00:fi=00:di=01;37;44:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.flac=01;35:*.mp3=01;35:*.mpc=01;35:*.ogg=01;35:*.wav=01;35:'

alias ls 'ls --color=tty'

source $BBTB_ROOT/prompt_init.csh
