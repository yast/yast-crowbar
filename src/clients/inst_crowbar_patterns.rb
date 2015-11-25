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
# Summary:     Client for selecting Cloud pattern(s) for the installation 
# Authors:     Jiri Suchomel <jsuchome@suse.cz>
#
module Yast
  class InstCrowbarPatternsClient < Client
    include Yast::Logger
    def main

      Yast.import "GetInstArgs"
      Yast.import "Installation"
      Yast.import "Kernel"
      Yast.import "PackagesProposal"
      Yast.import "PackagesUI"
      Yast.import "Pkg"
      Yast.import "Stage"

      dialog_ret = :auto
      patterns = [ "cloud_admin" ]

      return dialog_ret if GetInstArgs.going_back

      if Stage.normal
        # In normal stage, we need to use the functionality from
        # inst_add-on_software to setup source and target

        Pkg.TargetInit(Installation.destdir, false)
        Pkg.SourceStartManager(true)
        patterns.each do |pattern|
          Pkg.ResolvableInstall(pattern, :pattern)
        end

        ret = PackagesUI.RunPatternSelector
        log.info "RunPatternSelector returned #{ret}"

        dialog_ret = (ret == :cancel) ? :abort : :next

        if ret == :accept || ret == :ok
          # Add-on requires packages to be installed right now
          log.info "Selected resolvables will be installed now"

          if WFM.CallFunction("inst_rpmcopy", [GetInstArgs.Buttons(false, false)]) == :abort
            dialog_ret = :abort
          else
            Kernel.InformAboutKernelChange
          end
        end
      else
        # During installation workflow, just preselect extra pattern
        log.info "Selecting Cloud Admin pattern for installation..."
        PackagesProposal.SetResolvables("crowbar_patterns", :pattern, patterns)
      end

      dialog_ret
    end
  end
end

Yast::InstCrowbarPatternsClient.new.main
