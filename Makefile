### Remove GNU make implicit rules

## This speeds things up since we don't need to look for and stat() a
## "foo.c,v" every time a rule referring to "foo.c" is in play. See
## "make -p -f/dev/null | grep ^%::'", and in this trivial makefile
## makes "make --debug=a" output easier to read.
%:: %,v
%:: RCS/%,v
%:: RCS/%
%:: s.%
%:: SCCS/s.%

## Likewise delete default $(SUFFIXES). See:
##
##     info make --index-search=.DELETE_ON_ERROR
.SUFFIXES:

### Flags affecting all rules

# A GNU make extension since gmake 3.72 (released in late 1994) to
# remove the target of rules if commands in those rules fail. The
# default is to only do that if make itself receives a signal. Affects
# all targets, see:
#
#    info make --index-search=.DELETE_ON_ERROR
.DELETE_ON_ERROR:

# Don't delete intermediate files, makes ad-hoc debugging inspections
# easier.
.PRECIOUS: .build/%.adoc

prefix = $(HOME)/local
bindir = $(prefix)/bin
mandir = $(prefix)/share/man
man1dir = $(mandir)/man1

INSTALL = install
ASCIIDOCTOR = asciidoctor

SRC = git-hyperfine
MAN = $(SRC:%=.build/%.1)
XML = $(SRC:%=.build/%.xml)

# Advanced mkdir technology stolen from my git.git changes
define mkdir_p_parent_template
$(if $(wildcard $(@D)),,$(shell mkdir -p $(@D)))
endef

.build/%.adoc: $(SRC)
	$(call mkdir_p_parent_template)
	./$< --help >$@

.build/%.1: .build/%.adoc
	$(call mkdir_p_parent_template)	
	$(ASCIIDOCTOR) -b manpage -o - $< >$@

.build/%.xml: .build/%.adoc
	$(call mkdir_p_parent_template)
	$(ASCIIDOCTOR) -b docbook -o - $< >$@

.build/%.md: .build/%.xml
	pandoc -f docbook -t gfm $< -o - >$@

README.md: .build/$(SRC).md
	cp $< $@

.PHONY: doc
doc: $(XML)

.PHONY: man
man: $(MAN)

.PHONY: all
all: man doc

.PHONY: install-man
install-man: .build/$(MAN)
	$(INSTALL) -d -m 755 $(DESTDIR)$(man1dir)
	$(INSTALL) -m 644 $< $(DESTDIR)$(man1dir)

.PHONY: install-bin
install-bin: $(SRC)
	$(INSTALL) $< $(DESTDIR)$(bindir)

.PHONY: install
install: install-man install-bin

.PHONY: clean
clean:
	$(RM) -r .build
