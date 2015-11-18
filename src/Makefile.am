# Sources for crowbar

module_DATA = \
  modules/Crowbar.rb

client_DATA = \
  clients/inst_crowbar.rb \
  clients/inst_crowbar_patterns.rb \
  clients/crowbar.rb

yncludedir = @yncludedir@/crowbar
ynclude_DATA = \
  include/crowbar/wizards.rb \
  include/crowbar/complex.rb \
  include/crowbar/helps.rb

desktop_DATA = \
  desktop/crowbar.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
