#!/usr/bin/perl -w

use strict;

while(defined(my $line = <STDIN>)) {
    if ($line =~ /^Student/) {
	next;
    }
    if ($line =~ /^\s+Points Possible/) {
	next;
    }
    if ($line =~ /Student\, Test/) {
	next;
    }
    chomp($line);
    my @fields = split(/\t/, $line);
    my $fullname = $fields[0];
    my $numericid = $fields[2];
    my $email = $fields[3];
    my $onid = do {(my $onid2 = $email) =~ s/\@oregonstate\.edu//; $onid2};
    my $encpass = `echo $numericid | openssl passwd -1 -stdin`;
    chomp($encpass);
    print $onid . "\t" . $encpass . "\t" . $fullname . "\n";
}
