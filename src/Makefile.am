# Makefile.am for crowbar/src

yncludedir = @yncludedir@/crowbar

client_DATA =			\
	crowbar.ycp

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	complex.ycp

desktop_DATA =			\
	crowbar.desktop

module_DATA =			\
        JSON.rb                 \
	Crowbar.ycp

# create a symlink for local build, #145327
crowbar:
	ln -sf . $@
ycpchook = crowbar

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
