#!/usr/bin/perl
#
# Generate more verbose messages of missing translations
#
# Input: language.h common.h  Output: langerr.h
#

use strict;
use warnings;

print <<INTRO;
// This file is autogenerated. DO NOT EDIT."
// Edit perl/langerr.pl instead."

INTRO

my @langcodes;
my @switches;
while (<>) {
	if (/^\s*enum\s+langtextids\s*{/ .. /^\s*LANG_LASTSTRING\W/) {
		next unless /^\s*(\w+)\s*,/;
		my $langcode = $1;
		$langcode =~ tr/,//d;
		push @langcodes, $langcode;
	} elsif (/^\/\/ BEGIN PATCHFLAGS/ .. /^\/\/ END PATCHFLAGS/) {
		next unless /^#define\s+([a-z0-9]+)\s+(\d+)\s*/;
		$switches[$2]=$1 unless /META:/;
	}
}

# deal with missing entries
$langcodes[$_] ||= "UNDEFINED:$_" for 0..$#langcodes;
$switches[$_] ||= "UNDEFINED:$_" for 0..$#switches;

print	"const char *switchcodes[", scalar @langcodes, "] = {\n",
		map(qq(\t"$langcodes[$_]",\t// $_\n), 0..$#langcodes),
	"};\n",
	"const char *switchname[", scalar @switches, "] = {\n",
		map(qq(\t"SWITCHTEXT($switches[$_])",\t// $_\n), 0..$#switches),
	"};\n";
