# Makefile to fetch needed data and create the trump card HTML files
#
# Copyright 2012 Diomidis Spinellis
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

# Target files
HTMLFILES=cards-en.html cards-de.html cards-el.html

# Source files needed to run makecards.pl
SRCFILES=makecards.pl template.html data

all: $(HTMLFILES)

# Rule for each file
cards-de.html: $(SRCFILES) localize/translate.de
	perl makecards.pl de >$@

cards-el.html: $(SRCFILES) localize/translate.el
	perl makecards.pl el >$@

cards-en.html: $(SRCFILES) localize/translate.en
	perl makecards.pl en >$@

# Fetch the elements' physical data
data:
	(mkdir -p data && cd tools && sh getinfo.pl)
