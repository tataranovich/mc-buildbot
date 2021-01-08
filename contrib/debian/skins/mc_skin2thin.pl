#!/usr/bin/perl

=head1 mc_skin2thin.pl

    Make "thin frame" variant of midnight-commander skins.

=head1 SYNOPSIS

    mc_skin2thin.pl [directory]

=head1 DESCRIPTION

    B<This program> will read all *.ini files in given directory,
    replace thick frame border characters with thin ones and save
    generated files to directory with '-thin' appended to
    the directory name and to all generated files,
    overwriting files in destination.

    It is meant to be used by maintainer to generate thin set of
    skins.

=head1 EXAMPLES

    mc_skin2thin.pl modarin-1.2

=head1 AUTHOR

    This script written by Dmitry Smirnov <onlyjob@member.fsf.org>
    on 2012-03-12

=cut

use strict;
use utf8;
use File::Find qw(finddepth find);

die "E: please invoke by giving directory with *.ini scripts as argument."
    if $#ARGV<0;

while(my $dir=shift @ARGV){
    my $newdir=$dir.'-thin';
    finddepth {
	no_chdir=>1,
	wanted=>sub{	s{.*/}{};
	    return if $_ eq '.' or $_ eq '..' or not m{\.ini\Z};
	    if(open my $INFIL, '<:encoding(UTF-8)', $File::Find::name){
		my $skintext;
		read $INFIL, $skintext, -s $INFIL;
		close $INFIL;
		if($skintext=~y{═║╔╗╚╝╤╧╟╢}{─│┌┐└┘──├┤}){
		    mkdir $newdir unless -d $newdir;
		    my $newfil=$_;
		    $newfil=~s{(\.ini)\Z}{-thin$1};
		    if(open my $OUFIL,'>:encoding(UTF-8)',"$newdir/$newfil"){
			print "Transforming $File::Find::name --> $newdir/$newfil\n";
			print $OUFIL $skintext;
			close $OUFIL;
		    }
		}
	    }else{ die "can't open file $File::Find::name" }
	}},
	$dir;
}
