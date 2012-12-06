#!/usr/bin/perl -w

use strict;

my @rawProgText      = ();

my $lineNbFile       = ($#ARGV >= 0 ? $ARGV[0] : '');

shift if($lineNbFile);

while(<>) {
    my $line         = $_;
    next if($line    =~ m/^\#/);
    chomp($line);
    push @rawProgText,$line;
}

my @LNprogText       = ();
my $lineNumber       = 0;
my %label2LineNbr    = ();

foreach my $line (@rawProgText) {
    my $wouldBeLabel = $line;
    if($line =~ m/;LNR=\$/) {
	$wouldBeLabel =~ s/^.*;LNR=\$(.[^:]*):.*$/$1/;
	die "Duplicate label '$wouldBeLabel'\n" if(exists $label2LineNbr{$wouldBeLabel});
	$label2LineNbr{$wouldBeLabel} = $lineNumber;
    }
    my $nbLine       = $line;
    $nbLine          =~ s/;LNR/;$lineNumber/;
    push @LNprogText,$nbLine;
    $lineNumber++;
}

if($lineNbFile) {
    my $intermediateFile;
    open $intermediateFile,">$lineNbFile" or die "Could not open intermediateFile '$lineNbFile' for writing\n";
    print $intermediateFile join("\n",@LNprogText),"\n";
    close $intermediateFile;
}

$lineNumber          = 0;
my %instrAbsValLabel = ('JMBSI' => 1, 'SETRI' => 1);

foreach my $line (@LNprogText) {
    my $okLine       = $line;
    my $wouldBeLabel = $okLine;
    $wouldBeLabel    =~ s/^[^;]* \$(.[^ ]*) .*$/$1/;
    if($wouldBeLabel ne $okLine) {
	die "Unknown label '$wouldBeLabel' in line '$line'" 
	    unless(exists  $label2LineNbr{$wouldBeLabel});
	my $instruct = $line;
	$instruct    =~ s/^(.....).*/$1/;
	my $qAbsVal  = (exists $instrAbsValLabel{$instruct});
	my $addrVal  = $label2LineNbr{$wouldBeLabel} - 
    	               ($qAbsVal ? 0 : ($lineNumber + 1));
	$okLine      =~ s/^([^;]*) \$(.[^ ]*) (.*)$/$1 $addrVal $3/; 	
    }
    print $okLine,"\n";
    $lineNumber++;
}

