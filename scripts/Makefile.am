bin_SCRIPTS = cortical_surface msd_masks

EXTRA_DIST = cortical_surface.pl msd_masks.pl

SUFFIXES = .pl
.pl:
	@rm -f $@
	sed < $< > $@-t \
		-e 's,xPERLx,$(PERL),' \
		-e 's,xINCDIRx,$(perllibdir),g' \
		-e 's,xDATADIRx,$(datadir),g' \
		-e 's,xPKGDATADIRx,$(pkgdatadir),g' &&\
	mv $@-t $@

CLEANFILES = cortical_surface msd_masks
