.PHONY: all
all: pdf html md

.PHONY: pdf
pdf: ../README.md
	pandoc --listings -H prelude.tex -V geometry:"left=1cm, top=1cm, right=1cm, bottom=2cm" -V fontsize=12pt ../README.md -o instructions.pdf

.PHONY: html
html: ../README.md
	pandoc ../README.md -o instructions.html

.PHONY: md
md: ../README.md
	cp ../README.md ./instructions.md
