extproc perl -S

#
# Copyright (c) 2005 Mike O'Connor
# All rights reserved.
# Author Mike O'Connor <stew@vireo.org>
#
# Modified by Shawn Betts.
#
# code was adapeted from rpws that comes from ratpoison containing the follwing copyright:
# Copyright (C) 2003 Shawn Betts
# Author: Shawn Betts
#

use strict;
use Fcntl qw (:flock);
use Getopt::Std;

my $ratpoison = $ENV{ "RATPOISON" } || "ratpoison";
my $tmp=$ENV{ "TMP" } || "/tmp";
my $lockfile = $ENV{ "RPWS_LOCKFILE" } || "$tmp/rpws.$<.lock";

sub help
{
    system("pod2usage", $0);
    print( "for more detailed documentation run \"perldoc $0\"\n" );
}

sub rp_call
{
    my $result = `$ratpoison -c "@_"`;
    chomp( $result );
    chomp( $result );
    return $result;
}

sub ws_init_ws
{

    my $num = shift;

    rp_call( "gnew wspl$num" );
    my $fd = fdump();
    rp_call( "setenv fspl$num $fd" )
}

sub fdump
{
    return rp_call( "fdump" );
}

sub ws_init
{
    my $num = shift;

    # Backup the frames
    my $fd = fdump();

    rp_call( "select -" );
    rp_call( "only" );

    my $i;
    for( my $i = 1; $i < $num; $i++ )
    {
        ws_init_ws( $i );
    }

    # Workspace 1 uses the 'default' group.
    # Start in workspace 1.
    $fd = fdump();
    rp_call( "gselect default" );
    rp_call( "setenv fspl1 $fd" );
    rp_call( "setenv wspl 1" );

    # restore the frames
    rp_call( "frestore $fd" );

    if( -e "$lockfile" )
    {
        unlink ("$lockfile" );
    }
}

sub ws_save
{
    my $ws = rp_call( "getenv wspl" );
    my $fd = fdump();
    rp_call( "setenv fspl$ws $fd" );
}

sub ws_restore
{
    my $which = shift;

    ws_save();

    if( $which == 1 )
    {
        rp_call( "gselect default" );
    }
    else
    {
        rp_call( "gselect wspl$which");
    }

    rp_call( "echo Workspace $which" );
    my $last = rp_call( "getenv fspl$which" );
    rp_call( "frestore $last" );
    rp_call( "setenv wspl $which" );
}

sub add_aliases
{
    my $n = shift;
    foreach my $i (1..$n) {
        rp_call ( "alias rpws$i exec $0 $i" );
    }
}

sub add_keys
{
    my $n = shift;
    foreach my $i (1..$n) {
        rp_call ( "definekey top M-F$i rpws$i" );
    }
}

my $arg = shift @ARGV || 'help';

if( $arg eq "help" ) {
    help();
} elsif( $arg eq "init" ) {
    my $num = shift @ARGV;
    my %opts;
    ws_init( $num );
    getopts('ka', \%opts);
    add_aliases( $num ) if $opts{'a'} || $opts{'k'};
    add_keys ( $num ) if $opts{'k'};
} else {
   open LOCK, ">>$lockfile" or die "Cannot open lockfile: $lockfile";
   flock(LOCK, LOCK_EX);
   ws_restore( $arg );
}

__END__

=head1 NAME

rpws - Implements multiple workspaces in ratpoison

=head1 SYNOPSIS

 rpws init n [-k] [-a]  - setup rpws with n workspaces.
                            -a sets up command aliases;
                            -k sets up key bindings and aliases.
 rpws help              - this documentation
 rpws n                 - switch to this workspace


=head1 DESCRIPTION

 B<rpws> implements multiple workspaces in ratpoison by making calls
 to fdump, freestore.  It was adapted from rpws which comes with
 ratpoison in the contrib directory.

=head1 USAGE

Add the following line in ~/.ratpoisonrc

     exec /path/to/rpws init 6 -k

This creates 6 aliases rpws1, rpws2, etc. It also binds the keys M-F1,
M-F2, etc to each rpwsN alias.

=head1 FILES

 rpws requires use of a lockfile.  It defaults to using
/tmp/rpws.<UID>.lock but this can be changed by setting the
environment variable RPWS_LOCKFILE to your desired lockfile.

=head1 AUTHOR

 Mike O'Connor <stew@vireo.org>

=head1 COPYRIGHT

 Copyright (c) 2005 Mike O'Connor
 All rights reserved.

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
