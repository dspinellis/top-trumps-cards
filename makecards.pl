#!/usr/bin/perl
#
# Copyright 2012-13 Diomidis Spinellis
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

use strict;
use warnings;

if ($#ARGV == -1) {
	print STDERR "usage: $0 language-code\n";
	exit 1;
}

my $language = $ARGV[0];
my $cardsPerPage = 6;
my $elementCount = 0;

my %attribution;

# Prepare directories
mkdir 'meta' unless (-d 'meta');
mkdir 'images/elements' unless (-d 'images/elements');

print qq{
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="$language">
<head>
<title>Elements</title>
<meta http-equiv="Content-type" content="text/html; charset=utf-8" />
<link href="style.css" rel="stylesheet" type="text/css" />
</head>
<body>
<div id='all'>
};

# Read local translations
my $fname;
open(IN, $fname = "localize/translate.$language") || die "Unable to open $fname: $!\n";
my %localName;
while(<IN>) {
	chop;
	next if (/^#/ || /^$/);
	my ($en, $local) = split(/\t+/, $_);
	$localName{$en} = $local;
}

# Set separator values
my $thousandSeparator;
my $decimalSeparator;

if (defined($localName{'thousandSeparator'})) {
	$thousandSeparator = $localName{'thousandSeparator'};
} else {
	$thousandSeparator = ',';
}
if (defined($localName{'decimalSeparator'})) {
	$decimalSeparator = $localName{'decimalSeparator'};
} else {
	$decimalSeparator = '.';
}

# Hide English translation in English
my $englishStyle;
if ($language eq 'en') {
	$englishStyle = 'display: none';
} else {
	$englishStyle = '';
}


# Read element template
open(IN, $fname = "template.html") || die "Unable to open $fname: $!\n";
my $template = join('', <IN>);

my @files = <data/*.info>;

# Template variables
my @vars = qw(
	localName
	englishName
	symbol
	phase
	series
	image
	number
	mass
	density
	melt
	boil
	soundSpeed

	leftMarginCm
	topMarginCm
	englishStyle
);

# Template localization variables
my @locVars = qw(
	lblAtomicNumber
	lblAtomicWeight
	lblMelt
	lblBoil
	lblDensity
	lblSoundSpeed
	instructionsHeader
	instructions
	licenseHeader
	license
	attributionsHeader
);

push(@vars, @locVars);

my $lblAtomicNumber;
my $lblAtomicWeight;
my $lblMelt;
my $lblBoil;
my $lblDensity;
my $lblSoundSpeed;
my $instructionsHeader;
my $instructions;
my $licenseHeader;
my $license;
my $attributionsHeader;

for my $v (@locVars) {
	eval(qq{\$$v = localize('$v', 'initialization')});
}


# Process all element files
for my $f (@files) {
	open(IN, "<:encoding(UTF-8)", $f) || die "Unable to open $f: $1\n";
	my $localName;
	my $englishName;
	my $symbol;
	my $phase;
	my $series;
	my $image;
	my $aspect;
	my $number;
	my $mass;
	my $density;
	my $leftMarginCm;
	my $topMarginCm;
	my $melt;
	my $boil;
	my $sublimation;
	my $soundSpeed;
	while (<IN>) {
		chop;
		s/\s+$//;
		s/{.*//;
		if (/^\s*\|\s*name\s*\=\s*(.*)/) {
			$englishName = $1;
			$englishName =~ s/^(.)(.*)/uc($1) . $2/e;
			$localName = localize($englishName, $englishName);
		} elsif (/^\s*\|\s*symbol\s*\=\s*(.*)/) {
			$symbol = $1;
		} elsif (/^\s*\|\s*phase\s*\=\s*(.*)/) {
			$phase = localize(lc($1), $englishName);
		} elsif (/^\s*\|\s*series\s*\=\s*(.*)/) {
			$series = $1;
		} elsif (/^\s*\|\s*image name\s*\=\s*(.*)/) {
			if (!defined($englishName)) {
				print STDERR "No name for $f\n";
			}
			$image = $1;
			if (! -r "meta/$englishName.txt") {
				system(qq{wget --local-encoding=UTF-8 -O meta/$englishName.txt "http://en.wikipedia.org/wiki/File:$image"});
			}
			if (! -r "images/elements/$englishName.jpg") {
				open(META, "meta/$englishName.txt") || die "Unable to open meta/$englishName.txt: $!\n";
				while(<META>) {
					if (/<div class="fullMedia"><a href="([^"]*)"/) {
						my $url = $1;
						system(qq{wget --local-encoding=UTF-8 -O "images/elements/$englishName.jpg" "http:$url"});
						last;
					}
				}
			}
			# Get author link
			open(META, "meta/$englishName.txt") || die "Unable to open meta/$englishName.txt: $!\n";
			while(<META>) {
				if (/Author</) {
					$attribution{$englishName} = <META>;
					$attribution{$englishName} =~ s|href="//|href="http://|;
				}
			}

			open(DIM, "jpegtopnm.exe <images/elements/$englishName.jpg | sed -n 2p|") || die "Unable to get image dimensions: $!";
			my $dim = <DIM>;
			my ($containerWidthCm, $containerHeightCm) = (5, 4);
			my ($imgWidthPixels, $imgHeightPixels) = split(/\s+/, $dim);
			my $pixelsPerCm;
			if ($imgWidthPixels / $containerWidthCm > $imgHeightPixels / $containerHeightCm) {
				$pixelsPerCm = $imgWidthPixels / $containerWidthCm;
				my $imgHeightCm = $imgHeightPixels / $pixelsPerCm;
				$topMarginCm = ($containerHeightCm - $imgHeightCm) / 2;
				$leftMarginCm = 0;
			} else {
				$pixelsPerCm = $imgHeightPixels / $containerHeightCm;
				my $imgWidthCm = $imgWidthPixels / $pixelsPerCm;
				$leftMarginCm = ($containerWidthCm - $imgWidthCm) / 2;
				$topMarginCm = 0;
			}
			close(DIM);
		} elsif (/^\s*\|\s*number\s*\=\s*(.*)/) {
			$number = $1;
		} elsif (/^\s*\|\s*atomic mass\s*\=\s*(.*)/) {
			$mass = $1;
		} elsif (/^\s*\|\s*density \w+\s*\=\s*(.+)/) {
			$density = $1;
		} elsif (/^\s*\|\s*melting point C\s*\=\s*(.*)/) {
			$melt = $1;
		} elsif (/^\s*\|\s*boiling point C\s*\=\s*(.*)/) {
			$boil = $1;
		} elsif (/^\s*\|\s*sublimation point C\s*\=\s*(.+)/) {
			$sublimation = $1;
		} elsif (/^\s*\|\s*speed of sound[^=]*\=\s*(.+)/) {
			$soundSpeed = $1;
		} elsif (/^\s*\|\s*number\s*\=\s*(.*)/) {
			$number = $1;
		}
	}


	$melt = "$sublimation!" if (!defined($melt));
	$boil = "$sublimation!" if (!defined($boil));

	# Replace template variables
	my $text = $template;
	for my $var (@vars) {
		# print STDERR "Evaluating \${$var}\n";
		my $value = eval("\${$var}");
		$value = '&mdash;' unless defined($value);
		if ($decimalSeparator ne '.' && $var !~ m/^margin\-|(top|left)/) {
			$value =~ s/\,/\001/g;
			$value =~ s/\./\002/g;
			$value =~ s/\001/$thousandSeparator/g;
			$value =~ s/\002/$decimalSeparator/g;
		}
		# Add a thousand separator, if needed
		if ($value =~ m/^\d{5,}$/) {
			$value =~ s/(\d{3})$/$thousandSeparator$1/;
		}
		$text =~ s/\$\{$var\}/$value/g;
		$text =~ s/\$$var\b/$value/g;
		# print STDERR "Changing \$$var to $value\n";
	}
	print "$text\n";
	if (++$elementCount % $cardsPerPage == 0) {
		print qq{<div id="pagebreak" />\n};
	}
}

print qq{
</div>
<div id="pagebreak" />
<h1>$instructionsHeader</h1>
<div id="instructions">
$instructions
</div>

<h1>$licenseHeader</h1>
<div id="license">
<a rel="license" href="http://creativecommons.org/licenses/by/3.0/"><img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by/3.0/88x31.png" /></a><br />$license
</div>

<h1>$attributionsHeader</h1>
<div id="attributions">
<a href="http://en.wikipedia.org/wiki/File:Helium_atom_QM.svg">Atomic number: <a href="http://commons.wikimedia.org/wiki/User:Yzmo">Yzmo</a>;
<a href="http://www.flickr.com/photos/sepehrehsani/5766453552/">Atomic mass icon: Sepehr Ehsani;
<a href="http://www.flickr.com/photos/mauroescritor/7297023536/">Density icon</a>:Mauro Cateb.
<a href="http://www.flickr.com/photos/sharynmorrow/3717319643/">Melting point icon</a>: Sharyn Morrow;
<a href="http://www.flickr.com/photos/andrewmalone/1266333093/">Boiling point icon</a>: Andrew Malone;
</div>
<div id="attributions">
};

my $attribution;
for my $element (keys %attribution) {
	$attribution .= qq{<a href="http://en.wikipedia.org/wiki/$element">$element</a></td>: $attribution{$element}; };
}
$attribution =~ s/;$/./;

print "$attribution\n";

print q{
</div>
</body>
</html>
};

sub
localize
{
	my ($en, $name) = @_;

	my $lname = $localName{$en};
	if (!defined($lname)) {
		print STDERR "No local name for [$en] in $name\n";
	}
	return $lname;
}

