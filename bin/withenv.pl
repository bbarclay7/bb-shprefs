#!/usr/bin/env perl
# -*- Mode: Perl; -*-

if (@ARGV < 2){
    print "This script runs a command using env captured by an envdump.\n";
    print "Usage example: 
\% env > /tmp/this.env
...
\% $0 /tmp/this.env command -arg option

";
      die "Usage: $0 <env dump file> <command line ... >"
}

my $envfile = shift @ARGV;
open my $envdump, $envfile or die "Can't read $envfile because $!";
my @del_keys = keys %ENV;
foreach my $delkey (@del_keys){
     delete $ENV{$delkey};
}
while (my $line = <$envdump>){
      chomp $line;
    my ($var,$val) = split /=/, $line, 2;
    $ENV{$var} = $val;
}

# locate exe on new PATH if needful
my $exe = $ARGV[0];
unless ($exe =~ /\//){
    
}

exec @ARGV;
