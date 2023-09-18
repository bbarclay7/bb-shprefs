#!/usr/bin/env ruby

def d(s)
  #$stderr.print("D>> #{s}\n")
  1
end


#end

require 'yaml'
require 'pathname'
require 'ostruct'

usual_user='bbarclay'

equivs = [["/home/bb/work","$HOME/work"]]

#
if not ENV.has_key?('BBTB_ROOT')
  puts "BBTB_ROOT not set.  abort."
  exit(1)
end
    

# lame but quick - global to tunnel env description from build_prompt to main
$envinfo = nil

$default_config = YAML::load '---
logical_paths:
  /logical/foo: /physical/path/to/foo
'

trap("SIGINT") { puts "prompt-aborted % "; exit!(0) } # cause ctrl-c to exit 0
$VERBOSE=nil

$debug = nil 
$config = {}
$users_group = 'users'
$git_exe = 'git'
$fsl_exe = 'fossil'
$slowdisk_mode = nil 


if not File.exists?($fsl_exe)
  if File.exists?('/usr/local/bin/fossil')
    $fsl_exe = '/usr/local/bin/fossil'
  end
end

$fsl_exe = nil

$stumbled_upon_file = ENV['HOME'] + "/.setprompt_found.yaml"

class ::Hash
    def deep_merge(second)
        merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
        self.merge(second, &merger)
    end
end

def xterm_title_str(title)
  "\033]0;#{title}\007"
end

def set_config(optsh={})
  d "set_config in"
  config_file = ENV['HOME']+"/.setprompt.yaml"
  if File.exists? config_file
    config_file_data = YAML::load_file(config_file)
    $config = $default_config.deep_merge( config_file_data ) 
    $config['config_file'] = config_file
  end
  d "sc bp 1"
  if File.exists? $stumbled_upon_file
      d "sc bp 2"
    config_file_data = YAML::load_file(File.open $stumbled_upon_file)
      d "sc bp 3"
    $config = $config.deep_merge( config_file_data )
      d "sc bp 4"
    $config['$stumbled_upon_file'] = $stumbled_upon_file
  end
  d "sc bp 5"
  # normalize logical_path priorities
  $config['logical_paths'] = { "etc" => 20} unless $config.has_key?('logical_paths')
  $config['logical_paths'].keys.each{|k|
    if $config['logical_paths'][k].class == String and $config['logical_paths'][k].match(/^\d+$/)
      $config['logical_paths'][k] = $config['logical_paths'][k].to_i 
    end

    $config['logical_paths'][k] = 0 if $config['logical_paths'][k].class == String

  }
  d "sc bp 6"
  d $config.to_yaml
  $config['sorted_logical_paths'] = 
    $config['logical_paths'].keys.find_all{|path|
    if File.directory?(path)
      1
    else
      nil
    end
  }.sort{|a,b|
    cmp_path_dod(a,b)
  }.map{|path|
    adder = ""
    adder = " => " + $config['logical_paths'][path].to_s if $config['logical_paths'].has_key?(path)
    [path,path.realpath]
  }
  d "sc bp 7"



  d "sc bp 7.1"
  # normalize envvar_path_substitution:
  if not $config.has_key?('envvar_root_substitution')
    $config['envvar_root_substitution'] = { 'REPO_ROOT' => 0}
  else 
    $config['envvar_root_substitution']['REPO_ROOT'] = 0
  end

  if not $config.has_key?('logical_maps')
    $config['logical_maps'] = {}
  end
  
  $config['sorted_envvar_root_substitution']=
    $config['envvar_root_substitution'].keys.find_all{|envvar|
    if ENV.has_key?(envvar) and File.directory?(ENV[envvar])
      1
    else
      nil
    end
  }.sort{|a,b|
    $config['envvar_root_substitution'][a] <=> $config['envvar_root_substitution'][b]
  }
    d "sc bp 8"
$config['opts'] = optsh
  d "set_config out"
  return $config
end


def getopts(opts_list, opts_with_arg, argv=ARGV.clone)
  d "getops in"
  optsh = {}
  left_argv = []
  while o = argv.shift
    if m = o.match(/^-([a-zA-Z]{2,})$/)
      m[1].split(//).reverse.each{|letter| argv.unshift "-#{letter}" }
      next
    end
    if opts_with_arg.member?(o)
      optsh[o.sub(/^-/,'')] = argv.shift
      next
    end
    if opts_list.member?(o)
      optsh[o.sub(/^-/,'')] = 1
      next
    end
    left_argv.push(o)
  end
opts = OpenStruct.new(optsh)
  d "getops out"
  return opts, optsh
end

$ansi_lut = YAML::load 'black_text: "\e[30m"
red_text: "\e[31m"
green_text: "\e[32m"
brown_text: "\e[33m"
yellow_text: "\e[33m"
blue_text: "\e[34m"
magenta_text: "\e[35m"
cyan_text: "\e[36m"
gray_text: "\e[37m"
black_back: "\e[40m"
red_back: "\e[41m"
green_back: "\e[42m"
brown_back: "\e[43m"
blue_back: "\e[44m"
magenta_back: "\e[45m"
cyan_back: "\e[46m"
white_back: "\e[47m"
reset_colors: "\e[0m"
bold_on: "\e[1m"
blink_on: "\e[5m"
reverse_on: "\e[7m"
bold_off: "\e[22m"
blink_off: "\e[25m"
reverse_off: "\e[27m"
'


def color_code(code)
  code = code.to_s if code.class == Symbol
#  bright=nil
  if m=code.match(/^(bright|brite|hi)_(\S+)(_text)?$/)
    code=color_code(m[2])
    return nil unless code
    return code.sub(/\[/,'[1;')
  end
  return $ansi_lut[code] if $ansi_lut.has_key?(code)
  return $ansi_lut[code+"_text"] if $ansi_lut.has_key?(code+"_text")
  return nil
end

class String
  def colorize(code)
    "%{#{color_code(code)}%}#{self}%{\e[0m%}"  # for csh prompt
#    "#{color_code(code)}#{self}\e[0m"         # for terminal directly
  end

  def realpath
    return self unless File.exists?(self)
    Pathname.new(self).realpath.to_s
  end

  def logicalize_path
    do_logicalize_path(self)
  end

  def do_root_envvar_substitution

    path = self.logicalize_path
    return path unless $config and $config.has_key?('sorted_envvar_root_substitution')
    
    $config['sorted_envvar_root_substitution'].each{|envvar|
      next unless ENV.has_key?(envvar)
      next unless File.directory?(ENV[envvar])
      check_root = ENV[envvar]
      return '$' + envvar if path == check_root
      if m=path.match(/#{check_root}\/(.*)/)
        return '$' + envvar + "/" + m[1]
      end
    }
    return path
  end
end
  



# store stumbled upon logical paths
def stumbled_upon(logicalpath)
  d "stumbled_upon in"
  unless File.exists?($stumbled_upon_file)
    File.open($stumbled_upon_file,"w"){|fh|
      fh.puts "---\nlogical_paths: {}"
    }
    system "chgrp #{$users_group} #{$stumbled_upon_file}"
    system "chmod g+w #{$stumbled_upon_file}"
  end
  stumbled_upon_config = YAML::load( File.open( $stumbled_upon_file ) )

        

  
  # add newly discovered logical path
  stumbled_upon_config['logical_paths'][logicalpath] = Time.now.to_i.to_s
  
  # clean it out stale references
  deletes = []
  stumbled_upon_config['logical_paths'].keys.each{|path|
    deletes << path unless File.exists?(path)
  }
  deletes.each{|key| stumbled_upon_config['logical_paths'].delete(key)}
  
  File.open($stumbled_upon_file,"w"){|fh|
    fh.puts stumbled_upon_config.to_yaml
}
  d "stumbled_upon out"
end

# get paths in descending order by path depth
def cmp_path_dod(as,bs)
  d "cmp_path_dod in"
  # this is intended to be used in a sort
  # prioritize logical path substitutions based on precedence stored as value 
   if $config['logical_paths'].has_key?( as ) and $config['logical_paths'].has_key?( bs )
     
     priority_cmp= $config['logical_paths'][as] <=> $config['logical_paths'][bs]
     
     if not priority_cmp
       $stderr.puts "#{as} cmp #{bs}: #{priority_cmp}"
       $stderr.puts "before die? as=#{as} bs=#{bs}\nas_prio=#{$config['logical_paths'][as]} bs_prio=#{$config['logical_paths'][bs]}"
       $stderr.puts "should not get here.  may need to debug #normalize logical_path priorities"
     end
       d "cmp_path_dod out"
     return priority_cmp
   end

  aa=as.split('/')
  ba=bs.split('/')

  return 1 if aa.length < ba.length
  return -1 if aa.length > ba.length
  
         d "cmp_path_dod out"
  return 0
end


$logicalized_path_cache = {}
def do_logicalize_path(inpath, logical_paths=$config['logical_paths'], logical_maps=$config['logical_maps'])
  d "do_logicalize_path in"
  rv = inpath
  return $logicalized_path_cache[rv] if $logicalized_path_cache.has_key?(rv)

  real_inpath = rv.sub(/^\$[^\/]+/){|x| var=x.sub(/^\$/,'') ; ENV.has_key?(var)?ENV[var]:x}.realpath


  $config['logical_maps'].each{|k,v|
    #$stderr.puts("BB> #{real_inpath} : ^#{k}/ -> #{v}/")
    new = real_inpath.sub(%r"^#{k}/","#{v}/")
    if new != real_inpath 
      $logicalized_path_cache[real_inpath] = new
    end
    #$stderr.puts("BB> #{real_inpath} .")
  }

  
  # try different strategies to translate a physical disk path to a logical one, reachable by symlinks
  # try 0 - direct map
  path_check = []
  # try 1 - match realpath
  if $config.has_key?( 'logical_paths') and $config['logical_paths'].class == Hash
    # get paths in descending order by path depth
    repl = nil
    $config['sorted_logical_paths'].each{|logical,real|
      if real_inpath == real
        rv = logical
        $logicalized_path_cache[inpath] = rv
        return rv
      elsif real_inpath.match(/^#{real}\//)
        repl = real_inpath.sub(/^#{real}\//, logical+"/") 
        rv = repl
        $logicalized_path_cache[inpath] = rv
        return rv
      else
      end
    }
  end
  
  inparts = inpath.split('/')

  # # try 2 - [ doesnt work, not needed ]
  parts = inpath.split('/')
  if parts.length > 3
    base = parts.clone
    endent = base.pop
    basepath = base.join("/")
    lized_base = do_logicalize_path(basepath)
#    $stderr.puts "#{basepath} => #{lized_base}"
    if lized_base != basepath
      rv = lized_base + '/' + endent
      $logicalized_path_cache[inpath] = rv
      return rv
    end
  end

  # try 3 - maybe leaf is a symlink
  if path_check.length > 0
    lookup = 2 # the deeper, the more dirchecks, slowing it down
    path_check.each{|logical,real|
      0.upto(lookup).each{|depth|
        next if depth > inparts.length
        myslice = inparts.slice(-1*lookup,lookup)
        next unless myslice
        testpath = logical + "/" + (myslice.join('/'))
        if File.exists?(testpath)
          if testpath.realpath == real_inpath
            rv = testpath
            stumbled_upon(testpath)
            $logicalized_path_cache[inpath]  = rv
            return rv
          end
        end
      }
    }
  end

$logicalized_path_cache[inpath] = rv
  d "do_logicalize_path out"
  return rv
end


def pwd
  ENV['PWD'].logicalize_path
end

# eqivalent to this but fast:  git_root = `#{$git_exe} rev-parse --show-toplevel`.chomp
def git_find_toplevel(dir=ENV['PWD'])
  d "git_find_toplevel in"
dir_els = dir.split("/")
  while dir_els.size > 1
    git_toplevel_candidate = dir_els.join("/") 
    path = git_toplevel_candidate + "/.git"
    if (File.exists?(path) and File.directory?(path)   )
      return git_toplevel_candidate
    end
    dir_els.pop
  end
  d "git_find_toplevel out"
return nil

end

def fsl_find_toplevel(dir=ENV['PWD'])
  return nil
  dir_els = dir.split("/")
  #$stderr.puts "BB> #{dir}\n"
  if ENV['HOME'].realpath == dir.realpath
    return nil
  end
  while dir_els.size > 1
    fsl_toplevel_candidate = dir_els.join("/") 
    
    %W(.fslckout).each{|thing|
      path = fsl_toplevel_candidate + "/" + thing
      if (File.exists?(path)  )
        return fsl_toplevel_candidate
      end
    }
    dir_els.pop
  end
  #$stderr.puts "BB> nope #{dir}\n"
  return nil
end

# equivalent to git branch but fast
def get_git_branch(dir=ENV['PWD'])
  d "get_git_branch in"
  git_root = git_find_toplevel(dir)
  return nil unless git_root
  head_file = git_root + "/.git/HEAD"
  fh = File.open(head_file) or return '???'
  line = fh.read.chomp
fh.close
  d "get_git_branch out"
  if m=line.match(/^ref: refs\/heads\/(.*)/)
    return m[1]
  end
  if m=line.match(/^([0-9a-f]{6,6})[0-9a-f]+$/)
    return 'commit='+m[1]
  end
  return '???'
end

def get_fsl_branch(dir=ENV['PWD'])
  branch = nil
  return nil
  if not fsl_find_toplevel(dir)
    return branch
  end

  if $fsl_exe
    result=`cd #{dir} && #{$fsl_exe} branch`
    result.split(/\n/).each{|l|
      if m=l.match(/^\* (\S+)/)
        branch=m[1]
      end
    }
  end
  return branch
end

def build_prompt
  
  show_envvars = []
  
  lines=[]
  lines << ''


  # gather env info into proj cluster step

  ## proj variable shows up im prompt; set it appropriately
  proj = nil
  cluster=nil
  step=nil
  
  if ENV.has_key? 'PROJECT_ROOT'
    proj=ENV['PROJECT_ROOT'] 
  end

  # display collected env vars to display
  if ENV.has_key? 'SHOWVARS'
    ENV['SHOWVARS'].split(/[:, ]/).each{|var|
      show_envvars << var
  }
  end

  

  
  show_envvars.each{|k|
    v='UNDEFINED'
    v=ENV[k] if ENV.has_key? k
    lines << "  - #{k} = >#{v}<"
  }
  
  ## extras appear in {} after the path
  extras = []
  
  ## env't blurb

  projinfo = []
  if proj 
    debug "we have proj"
    projinfo << proj 
  else 
    debug "we dont have proj"
  end
  extras << 'nocwd' unless File.exists?(ENV['PWD'])
  $envinfo = projinfo.join('/') if projinfo.size > 0
  extras << $envinfo if $envinfo

  extra = extras.size>0? "{ #{extras.join(" ; ")} }":''

  lines << "#{extra}" if $extras_on_top and extra.match(/./)
  # show $PWD in brackets
  # with git info
  pline = nil
  pretty_pwd = pwd.logicalize_path.do_root_envvar_substitution
  if $slowdisk_mode
    root_envvar = 'REPO_ROOT'
    root_path = ENV[root_envvar]

    if ENV.has_key?(root_envvar) and m=pwd.realpath.match(/^#{root_path.realpath}\/?(.*)$/)
      ext_path = m[1]
      pline = "["+root_envvar.colorize(:cyan)+"/" + ext_path.colorize(:yellow)+"]"
    else
      pline = "["+pretty_pwd.colorize(:yellow)+"]"
    end

  else # not slow disk mode
    git_branch = nil
    fsl_branch = nil
    if git_find_toplevel
        git_branch = get_git_branch # returns nil if not in a git repo, branch name otherwise
    end
    if fsl_find_toplevel
      fsl_branch = get_fsl_branch 
    end
    repo_root = nil
    repo_branch = nil
    repo_branch_color = :hi_green
    if git_branch
      repo_root = git_find_toplevel
      repo_branch = git_branch
      repo_branch_color = :hi_green
    elsif fsl_branch
      repo_root = fsl_find_toplevel
      repo_branch = fsl_branch
      repo_branch_color = :hi_red
    end


    if repo_branch
      if m=pwd.realpath.match(/^#{repo_root.realpath}\/(.*)$/) # in subdir of git root
        base_path = repo_root.logicalize_path.do_root_envvar_substitution
        ext_path = m[1]
        pline = "["+base_path.colorize(:cyan)+"/" + ext_path.colorize(:yellow)+"]["+repo_branch.colorize(repo_branch_color)+"]"
      else # at git root
        pline = "["+pretty_pwd.colorize(:cyan)+"]["+repo_branch.colorize(repo_branch_color)+"]"
      end
    else # not in a git repo
      pline = "["+pretty_pwd.colorize(:yellow)+"]"
    end
  end



  pline += " #{extra}" unless $extras_on_top
  lines << pline

  # show user @ host
  user=ENV['USER']

  user = user.colorize(:red_back) if user != usual_user


  host=ENV['HOST']

  shlvl=""
  if ENV.has_key? 'SHLVL'
     shlvl=ENV['SHLVL']+" "
  end

  desktopname = `desktopname`.chomp
  
  lines << shlvl+"#{user}@#{host} #{desktopname} "
  
  return lines.join('\n')
end #def puts_prompt

## MAIN

# get args
opts_list = %w( -p -h -d -s)
opts_with_arg = %w( )
opts,optsh = getopts(opts_list, opts_with_arg)

if opts.h
  puts "usage:
source #{ENV['BBTB_ROOT']}/prompt_init.csh  # init prompt
setenv SETPROMPT_SLOWDISK 1                    # disable git queries
setenv SETPROMPT_DEBUG 1                       # enable debug messages
reprompt   # reset precmd alias in case it was removed
$p -d      # debug notes
$p -h      # this help
$p -s      # grow found file from seed
$p --sde-seed
$EDITOR ~/.setprompt.yaml         # edit prefs
$EDITOR ~/.setprompt_found.yaml   # edit stumbled upon logical paths

setenv SETPROMPT_BANNER 'foo' # prefix xterm banner
alias title 'setenv SETPROMPT_BANNER \"\\!*\"'
title foo

"
  exit 1
end

$debug = 1 if opts.d or ENV.has_key? 'SETPROMPT_DEBUG'

def debug(str)
  $stderr.puts "-SPD- > #{str}" if $debug
end

debug "debug mode on"


# populate $config
set_config(optsh)

# set preferences
$slowdisk_mode = 1 if ENV.has_key? 'SETPROMPT_SLOWDISK'
$slowdisk_mode = 1 if $config.has_key?('prefs') and $config['prefs'].has_key?('slowdisk') and $config['prefs']['slowdisk']

$extras_on_top = nil
$extras_on_top = 1 if $config.has_key?('prefs') and $config['prefs'].has_key?('extras_location') and $config['prefs']['extras_location']


# show debug
if opts.d
  puts $config.to_yaml
  exit 0
end

  

# grow found file
if (opts.s)
  exit 1 unless File.exists? $stumbled_upon_file
  data = YAML::load_file(File.open $stumbled_upon_file)
  seeds = data['logical_paths'].keys.sort{|a,b|
    data['logical_paths'][a] <=> data['logical_paths'][b]
  }.
    map{|x| x.sub(/\/[^\/]+$/,'')}.uniq
  seeds.each{|seed|
    Dir.glob("#{seed}/*").each{|logical| 
      next if logical.match(/\/\.\.?$/)
      real = logical.realpath
      if real != logical and not $config['logical_paths'].has_key?(logical)
        stumbled_upon(logical)
        dummy = real.logicalize_path
        puts "added #{dummy} to #{$stumbled_upon_file}"
      end
    }
  }
  
  exit 0
end


# show prompt
if opts.p
  # do prompt
  puts build_prompt 

  # add in xterm title, set to env
  if ENV['USER'] == usual_user
    banner = "#{ENV['HOST']}"
  else
    banner = "#{ENV['USER']}@#{ENV['HOST']}"
  end
  banner += " "+ENV["SETPROMPT_BANNER"] if ENV.has_key?("SETPROMPT_BANNER")
  banner += " "+$envinfo if $envinfo
  debug "banner is #{banner}"

  if not ENV.has_key? 'SETPROMPT_NO_XTERM_BANNER'
    $stderr.print xterm_title_str(banner) if banner and banner.match(/\S/)
  end
  exit 0
end
