#!/bin/tcsh -f
 
# Utility to run command in an interactive sub-shell
#
# Usage:
# 1) set this alias:
# alias subcsh 'set subcsh_args=(\!*); source .../subcsh.tcsh; unset subcsh_args'
# 2) run subcsh <command>
#
setenv orig_home $home
setenv EPHEM_CSHRC_HOME /tmp/subcsh_$user.temp_home.$HOST.$$
setenv EPHEM_CSHRC $EPHEM_CSHRC_HOME/.cshrc
/bin/mkdir -p $EPHEM_CSHRC_HOME >& /dev/null

if ( ! -e $EPHEM_CSHRC_HOME) then
  echo "Failed to create dir $EPHEM_CSHRC_HOME"
  exit 1
endif

# in the sub-shell redefine the value of ~ to be the users real home dir...
echo "set home=$orig_home" >> $EPHEM_CSHRC
echo "setenv HOME $orig_home" >> $EPHEM_CSHRC
echo "unset autologout" >> $EPHEM_CSHRC

# The following bit of code captures all aliases in the current shell by
# generating an alias command for each existing alias, and appending it to
# the temporary .cshrc. To generate the alias commands it must quote special
# characters !, \ and ' and encloses the command string in ''.


alias | perl -ne 'chop;($name,$value)=split(" ",$_,2);$value =~ s/'"'/'"'"'"'"'"'"'"'/g;$value =~ s/\!/\\\!/g;printf "alias %s '"'"'%s'"'"'\n", $name, $value;' >> $EPHEM_CSHRC


# Set the temporary home for the sub-shell, so it picks up the ephemeral .cshrc
set home = $EPHEM_CSHRC_HOME
setenv HOME $EPHEM_CSHRC_HOME
set user_shell = $SHELL
echo "" >> $EPHEM_CSHRC
echo "$subcsh_args" >> $EPHEM_CSHRC

## entering shell
echo "Begin subcsh '$subcsh_args'"
eval $user_shell
echo "Done with subcsh '$subcsh_args'"
## exited shell
set home = $orig_home
setenv HOME $orig_home

if ($?EPHEM_CSHRC_HOME) then
   /bin/rm -rf $EPHEM_CSHRC_HOME >& /dev/null
endif
