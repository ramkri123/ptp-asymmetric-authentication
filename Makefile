# Makefile for IETF Draft

DRAFT := draft-ramki-ptp-hardware-rooted-attestation-00
MMARK := $(HOME)/go/bin/mmark
XML2RFC := xml2rfc

# If xml2rfc is not in path, use the local one
ifeq (, $(shell which xml2rfc))
	XML2RFC := $(HOME)/.local/bin/xml2rfc
endif

.PHONY: all clean txt html xml

all: txt html

txt: $(DRAFT).txt
html: $(DRAFT).html
xml: $(DRAFT).xml

$(DRAFT).xml: draft-ramki-ptp-hardware-rooted-attestation-latest.md
	$(MMARK) $< > $@

$(DRAFT).txt: $(DRAFT).xml
	$(XML2RFC) --text $< -o $@

$(DRAFT).html: $(DRAFT).xml
	$(XML2RFC) --html $< -o $@

clean:
	rm -f $(DRAFT).xml $(DRAFT).txt $(DRAFT).html
