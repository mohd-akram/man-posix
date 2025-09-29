MKDIR_P = mkdir -p
INSTALL_DATA = cp

FIND = find
SED = sed

CURL = curl
PANDOC = pandoc
TAR = tar

prefix = /usr/local
mandir = $(prefix)/share/man

files = $(shell $(FIND) susv5-html \( \
		-path "*/utilities/*.html" -o \
		-path "*/functions/*.html" -o \
		-path "*/basedefs/*.html" \
	\) \
		! -name builtins-redirector.html \
		! -name contents.html \
		! -name toc.html \
		! -name V2_chap03.html \
		! -name V3_chap03.html \
	| $(SED) -E \
		-e 's|susv5-html/utilities/(.*)\.html|man1p/\1.1p|' \
		-e 's|susv5-html/functions/(.*)\.html|man3p/\1.3p|' \
		-e 's|susv5-html/basedefs/(.*)\.h\.html|man3p/\1.h.3p|' \
		-e 's|susv5-html/basedefs/(.*)\.html|man7p/\1.7p|' \
		-e 's/V1_chap01/intro/' -e 's/V1_chap02/posix/' \
		-e 's/V1_chap03/terms/' -e 's/V1_chap04/concepts/' \
		-e 's/V1_chap05/format/' -e 's/V1_chap06/charset/' \
		-e 's/V1_chap07/locale/' -e 's/V1_chap08/environ/' \
		-e 's/V1_chap09/regex/' -e 's/V1_chap10/hier/' \
		-e 's/V1_chap11/termios/' -e 's/V1_chap12/syntax/' \
		-e 's/V1_chap13/namespace/' -e 's/V1_chap14/headers/' \
		-e 's/V2_chap01/intro/' -e 's/V2_chap02/info/' \
		-e 's/V3_chap01/intro/' -e 's/V3_chap02/shell/' \
		-e 's|man7p/termios\.7p|man4p/termios.4p|')

all: man1p man3p man4p man7p susv5-html
	@$(MAKE) $(files)

$(DESTDIR)$(mandir)/man%:
	$(MKDIR_P) $@

install: \
	$(DESTDIR)$(mandir)/man1p \
	$(DESTDIR)$(mandir)/man3p \
	$(DESTDIR)$(mandir)/man4p \
	$(DESTDIR)$(mandir)/man7p

	$(INSTALL_DATA) man1p/* $(DESTDIR)$(mandir)/man1p
	$(INSTALL_DATA) man3p/* $(DESTDIR)$(mandir)/man3p
	$(INSTALL_DATA) man4p/* $(DESTDIR)$(mandir)/man4p
	$(INSTALL_DATA) man7p/* $(DESTDIR)$(mandir)/man7p

clean:
	$(RM) -r man1p man3p man4p man7p susv5-html

susv5.tgz:
	$(CURL) -O https://pubs.opengroup.org/onlinepubs/9799919799/download/susv5.tgz

susv5-html: susv5.tgz
	$(TAR) -xf susv5.tgz

clean = $(SED) -E ' \
	/<title>/{ \
		s/&[lg]t;//g; \
		s/([^<])\//\1_/g; \
		s/Introduction/Intro/; \
		s/Conformance/POSIX/; \
		s/Definitions/Terms/; \
		s/General Concepts/Concepts/; \
		s/File Format Notation/Format/; \
		s/Character Set/Charset/; \
		s/Environment Variables/Environ/; \
		s/Regular Expressions/Regex/; \
		s/Directory Structure and Devices/Hier/; \
		s/General Terminal Interface/Termios/; \
		s/Utility Conventions/Syntax/; \
		s/Namespace and Future Directions/Namespace/; \
		s/Shell Command Language/Shell/; \
		s/General Information/Info/; \
		y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/; \
	}; \
	/<(a|img)[^>]*$$/N; //N; //N; //N; //N; \
	/<a[^>]*>[^<]*$$/N; \
	s/<hr[^>]*>//; \
	s/<dd><\/dd>//g; \
	s/<img[^>]*>//g; \
	s/—|&mdash;/-/g; \
	s/<\/?blockquote[^>]*>//g; \
	s/<p>&nbsp;<\/p>//g; \
	s/<\/(body|html)>//g; \
	s/<sup>\[<a [^>]*>([^>]*)<\/a>]<\/sup>/[\1]/g; \
	s/<h4 class="mansect">(.*)<\/h4>/<h2>\1<\/h2>/; \
	/^<a href="\#top"><span class="topOfPage">return to top of page<\/span><\/a><br>$$/d; \
	/^\[ <a href="\.\.\/mindex.html">/,/^.*]/s/^[^]]*(]|$$)//; \
	/<center.*registered Trademark/,/<\/center>/{ \
		s/.*<center.*/<h2>COPYRIGHT<\/h2>\n&/; H; d; \
	}; \
	/^<(div|DIV) (class|CLASS)="NAVHEADER">$$/,/^<a name="top" id="top">/{ \
		$$!d; $$s/.*//; \
	}; \
	$${ p; g; s/$$/<\/body><\/html>/; } \
	'

header = The Open Group Base Specifications Issue 8 / IEEE Std 1003.1-2024
footer = POSIX.1-2024
date = 2024

html2man = $(PANDOC) --fail-if-warnings -s -f html -t man \
	--lua-filter=filter.lua --shift-heading-level-by=-1 \
	-V date=$(date) -V header="$(header)" -V footer="$(footer)"

convert = echo Generating $@; $(clean) $^ | $(html2man)

title = $$(basename $@ .1p)

builtin = echo Generating $@; $(SED) -n \
	-e "$$(printf '1i\\\n<!doctype html><html><head><title>%s</title></head><body>' "$(title)")" \
	-e "/<a name=\"$(title)\" id=\"$(title)\">/,/<em>End of informative text.<\/em>/p" \
	-e '/<center.*registered Trademark/,/<\/center>/p' \
	$^ | $(clean) | $(html2man) -V section=1P >$@

man1p man3p man4p man7p:
	$(MKDIR_P) $@

# Specification

man1p/intro.1p: susv5-html/utilities/V3_chap01.html
	@$(convert) -V section=1P >$@

man1p/shell.1p: susv5-html/utilities/V3_chap02.html
	@$(convert) -V section=1P >$@

man3p/intro.3p: susv5-html/functions/V2_chap01.html
	@$(convert) -V section=3P >$@

man3p/info.3p: susv5-html/functions/V2_chap02.html
	@$(convert) -V section=3P >$@

man4p/termios.4p: susv5-html/basedefs/V1_chap11.html
	@$(convert) -V section=4P >$@

man7p/intro.7p: susv5-html/basedefs/V1_chap01.html
	@$(convert) -V section=7P >$@

man7p/posix.7p: susv5-html/basedefs/V1_chap02.html
	@$(convert) -V section=7P >$@

man7p/terms.7p: susv5-html/basedefs/V1_chap03.html
	@$(convert) -V section=7P >$@

man7p/concepts.7p: susv5-html/basedefs/V1_chap04.html
	@$(convert) -V section=7P >$@

man7p/format.7p: susv5-html/basedefs/V1_chap05.html
	@$(convert) -V section=7P >$@

man7p/charset.7p: susv5-html/basedefs/V1_chap06.html
	@$(convert) -V section=7P >$@

man7p/locale.7p: susv5-html/basedefs/V1_chap07.html
	@$(convert) -V section=7P >$@

man7p/environ.7p: susv5-html/basedefs/V1_chap08.html
	@$(convert) -V section=7P >$@

man7p/regex.7p: susv5-html/basedefs/V1_chap09.html
	@$(convert) -V section=7P >$@

man7p/hier.7p: susv5-html/basedefs/V1_chap10.html
	@$(convert) -V section=7P >$@

man7p/syntax.7p: susv5-html/basedefs/V1_chap12.html
	@$(convert) -V section=7P >$@

man7p/namespace.7p: susv5-html/basedefs/V1_chap13.html
	@$(convert) -V section=7P >$@

man7p/headers.7p: susv5-html/basedefs/V1_chap14.html
	@$(convert) -V section=7P >$@

# Shell built-ins

man1p/break.1p \
man1p/colon.1p \
man1p/continue.1p \
man1p/dot.1p \
man1p/eval.1p \
man1p/exec.1p \
man1p/exit.1p \
man1p/export.1p \
man1p/readonly.1p \
man1p/return.1p \
man1p/set.1p \
man1p/shift.1p \
man1p/times.1p \
man1p/trap.1p \
man1p/unset.1p \
: susv5-html/utilities/V3_chap02.html
	@$(builtin)

# Utilities, headers and functions

man1p/%.1p: susv5-html/utilities/%.html
	@$(convert) -V section=1P >$@

man3p/%.h.3p: susv5-html/basedefs/%.h.html
	@$(convert) -V section=3P >$@

man3p/%.3p: susv5-html/functions/%.html
	@$(convert) -V section=3P >$@
