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

# Package:     Crowbar configuration
# Summary:     Client for running configuration during installation
# Authors:     Jiri Suchomel <jsuchome@suse.cz>
#              Michal Filka <mfilka@suse.cz>
#
#
# This client should be called during 2nd stage of installation
module Yast
  class InstCrowbarClient < Client
    def main
      Yast.import "UI"
      textdomain "crowbar"

      Yast.import "Mode"
      Yast.import "Package"
      Yast.import "Progress"
      Yast.import "Stage"
      Yast.import "Wizard"

      Yast.include self, "crowbar/wizards.rb"

      Builtins.y2milestone(
        "Crowbar configuration client (%1, %2)",
        Mode.mode,
        Stage.stage
      )

      @dialog_ret = :auto

      if Package.Installed("crowbar-core")

        Wizard.CreateDialog if Mode.normal

        Progress.off
        @dialog_ret = CrowbarSequence()
        Progress.on

        Wizard.CloseDialog if Mode.normal
      else
        Builtins.y2milestone("Necessary packages not installed, skipping Crowbar configuration...")
      end

      @dialog_ret
    end
  end
end

Yast::InstCrowbarClient.new.main
