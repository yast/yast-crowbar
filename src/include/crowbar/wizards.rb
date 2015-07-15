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

# File:	include/crowbar/wizards.ycp
# Package:	Configuration of crowbar
# Summary:	Wizards definitions
# Authors:     Jiri Suchomel <jsuchome@suse.cz>
#              Michal Filka <mfilka@suse.cz>
#
# $Id: wizards.ycp 65777 2011-09-19 08:06:31Z visnov $
module Yast
  module CrowbarWizardsInclude
    def initialize_crowbar_wizards(include_target)
      Yast.import "UI"

      textdomain "crowbar"

      Yast.import "Sequencer"
      Yast.import "Wizard"

      Yast.include include_target, "crowbar/complex.rb"
    end

    # Main workflow of the crowbar configuration
    # @return sequence result
    def MainSequence
      aliases = { "overview" => lambda { OverviewDialog() } }

      sequence = {
        "ws_start" => "overview",
        "overview" => { :abort => :abort, :next => :next }
      }

      Sequencer.Run(aliases, sequence)
    end

    # Whole configuration of crowbar
    # @return sequence result
    def CrowbarSequence
      aliases = {
        "read"  => [lambda { ReadDialog() }, true],
        "main"  => lambda { MainSequence() },
        "write" => [lambda { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "read",
        "read"     => { :abort => :abort, :next => "main" },
        "main"     => { :abort => :abort, :next => "write" },
        "write"    => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog

      Wizard.SetDesktopTitle("crowbar")
      Wizard.SetDesktopIcon("crowbar")

      ret = Sequencer.Run(aliases, sequence)

      UI.CloseDialog
      ret
    end

    # Whole configuration of crowbar but without reading and writing.
    # For use with autoinstallation.
    # @return sequence result
    def CrowbarAutoSequence
      # Initialization dialog caption
      caption = _("Crowbar Configuration")
      # Initialization dialog contents
      contents = Label(_("Initializing..."))

      Wizard.CreateDialog
      Wizard.SetContentsButtons(
        caption,
        contents,
        "",
        Label.BackButton,
        Label.NextButton
      )

      ret = MainSequence()
      UI.CloseDialog
      ret
    end
  end
end
