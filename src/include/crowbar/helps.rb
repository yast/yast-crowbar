# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2006 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# File:	include/crowbar/helps.ycp
# Package:	Configuration of crowbar
# Summary:	Help texts of all the dialogs
# Authors:     Jiri Suchomel <jsuchome@suse.cz>
#              Michal Filka <mfilka@suse.cz>
#
# $Id: helps.ycp 27914 2006-02-13 14:32:08Z locilka $
module Yast
  module CrowbarHelpsInclude
    def initialize_crowbar_helps(include_target)
      textdomain "crowbar"

      # All helps are here
      @HELPS = {
        # Read dialog help
        "read"     => _(
          "<p><b><big>Initializing Crowbar Configuration</big></b><br>\nPlease wait...<br></p>\n"
        ),
        # Write dialog help
        "write"    => _(
          "<p><b><big>Saving Crowbar Configuration</big></b><br>\nPlease wait...<br></p>\n"
        ),
        # Overview dialog help
        "overview" => _(
          "<p><b>Crowbar Configuration Overview</b>\n<br></p>"
        ) +
          # Ovreview dialog help
          _(
            "<p>\n" +
              "See the SUSE Cloud deployment guide for details on the network\n" +
              "configuration and on using this YaST module.\n" +
              "</p>"
          )
      } 

      # EOF
    end
  end
end
