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

# File:	clients/crowbar.ycp
# Package:	Configuration of crowbar
# Summary:	Main file
# Authors:     Jiri Suchomel <jsuchome@suse.cz>
#              Michal Filka <mfilka@suse.cz>
#
# $Id: crowbar.ycp 27914 2006-02-13 14:32:08Z locilka $
#
# Main file for crowbar configuration. Uses all other files.
module Yast
  class CrowbarClient < Client
    def main

      textdomain "crowbar"

      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("Crowbar module started")

      Yast.import "CommandLine"
      Yast.import "Crowbar"
      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"

      Yast.include self, "crowbar/wizards.rb"

      @cmdline_description = {
        "id"         => "crowbar",
        # Command line help text for the Xcrowbar module
        "help"       => _(
          "Configuration of crowbar"
        ),
        "guihandler" => fun_ref(method(:CrowbarSequence), "any ()")
      }

      # is path to data file given?
      @custom_path = false

      args = WFM.Args || []
      if args.size > 0
        arg = args[0]
        if arg.is_a? ::String
          Builtins.y2milestone("taking path to network config file from command line: %1", arg)
          Crowbar.network_file = arg
          @custom_path = true
        end
      end

      ret = @custom_path ?
        CrowbarSequence() :
        CommandLine.Run(@cmdline_description)

      Builtins.y2debug("ret=%1", @ret)

      Builtins.y2milestone("Crowbar module finished")
      Builtins.y2milestone("----------------------------------------")

      ret
    end
  end
end

Yast::CrowbarClient.new.main
