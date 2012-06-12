# Makefile.am for crawbar/src

yncludedir = @yncludedir@/crawbar

client_DATA =			\
	crawbar.ycp

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	complex.ycp

desktop_DATA =			\
	crawbar.desktop

module_DATA =			\
	Crawbar.rb

# create a symlink for local build, #145327
crawbar:
	ln -sf . $@
ycpchook = crawbar

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
