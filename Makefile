.SUFFIXES:
.DELETE_ON_ERROR:

SRC = git-hyperfine

%.asciidoc: $(SRC)
	./$< --help >$@

$(SRC:%=%.1): %.1: % %.asciidoc
	asciidoctor --trace -b manpage - < $< >$@
