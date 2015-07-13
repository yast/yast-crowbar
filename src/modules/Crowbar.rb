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

# File:	modules/Crowbar.ycp
# Package:	Configuration of crowbar
# Summary:	Crowbar settings, input and output functions
# Authors:     Jiri Suchomel <jsuchome@suse.cz>
#              Michal Filka <mfilka@suse.cz>
#
# $Id: Crowbar.ycp 41350 2007-10-10 16:59:00Z dfiser $
#
# Representation of the configuration of crowbar.
# Input and output routines.
require "yast"

module Yast
  class CrowbarClass < Module
    def main
      textdomain "crowbar"

      Yast.import "FileUtils"
      Yast.import "Json"
      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Message"

      # Path to the files with JSON data
      @network_file = "/etc/crowbar/network.json"
      @crowbar_file = "/etc/crowbar/crowbar.json"
      @provisioner_file = "/etc/crowbar/provisioner.json"
      @installed_file = "/opt/dell/crowbar_framework/.crowbar-installed-ok"

      # The keys are the names of default repositories available for current product
      # For Cloud5, we support mixed SLE11/SLE12 environments
      #
      # The values are target node platform for those repositories
      @default_repos = {
        "SLE-Cloud"                           => "suse-11.3",
        "SLE-Cloud-PTF"                       => "suse-11.3",
        "SUSE-Cloud-5-Pool"                   => "suse-11.3",
        "SUSE-Cloud-5-Updates"                => "suse-11.3",
        "SLES11-SP3-Pool"                     => "suse-11.3",
        "SLES11-SP3-Updates"                  => "suse-11.3",
        "SLE11-HAE-SP3-Pool"                  => "suse-11.3",
        "SLE11-HAE-SP3-Updates"               => "suse-11.3",
        "SLES12-Pool"                         => "suse-12.0",
        "SLES12-Updates"                      => "suse-12.0",
        "SLE12-Cloud-Compute"                 => "suse-12.0",
        "SLE12-Cloud-Compute-PTF"             => "suse-12.0",
        "SLE-12-Cloud-Compute5-Pool"          => "suse-12.0",
        "SLE-12-Cloud-Compute5-Updates"       => "suse-12.0",
        "SUSE-Enterprise-Storage-1.0-Pool"    => "suse-12.0",
        "SUSE-Enterprise-Storage-1.0-Updates" => "suse-12.0"
      }

      # map of network template configuration data
      @template_network = {}

      # map of crowbar template configuration data
      @template_crowbar = {}

      # map of provisioner configuration data
      @provisioner = {}

      # repos subset of global provisioner configuration map
      @repos = {}

      # networks subset of global network configuration map
      @networks = {}

      # conduit_map subset of global network configuration map
      @conduit_map = []


      # network teaming subset of global network configuration map
      @teaming = {}

      # network mode; valid values are: single | dual | team
      @mode = "single"

      # users subset of global crowbar configuration map
      @users = {}

      # If crowbar was installed
      @installed = false

      # Data was modified?
      @modified = false
    end

    # Adapt boolean values so they can be recognized by Perl
    # BEWARE: this will break any real true/false string values
    def adapt_value(value)
      value = deep_copy(value)
      if Ops.is_map?(value)
        return adapt_map(
          Convert.convert(value, :from => "any", :to => "map <string, any>")
        )
      end
      if Ops.is_list?(value)
        value = Builtins.maplist(Convert.to_list(value)) do |item|
          adapt_value(item)
        end
        return deep_copy(value)
      end
      return value == true ? "true" : "false" if Ops.is_boolean?(value)
      deep_copy(value)
    end
    def adapt_map(input_map)
      input_map = deep_copy(input_map)
      Builtins.foreach(input_map) do |key, val|
        Ops.set(input_map, key, adapt_value(val))
      end
      deep_copy(input_map)
    end

    # Data was modified?
    # @return true if modified
    def Modified
      Builtins.y2debug("modified=%1", @modified)
      @modified
    end


    # Read all crowbar settings
    # @return true on success
    def Read
      # Crowbar read dialog caption
      caption = _("Initializing crowbar Configuration")

      steps = 2

      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [
          # Progress stage
          _("Read the configuraton")
        ],
        [
          # Progress step
          _("Reading the configuration..."),
          # Progress finished
          _("Finished")
        ],
        ""
      )

      @installed = FileUtils.Exists(@installed_file)

      if !FileUtils.Exists(@network_file)
        Report.Error(Message.CannotOpenFile(@network_file))
        return false
      end

      if !FileUtils.Exists(@crowbar_file)
        Report.Error(Message.CannotOpenFile(@crowbar_file))
        return false
      end


      @template_network = Json.Read(@network_file)
      @networks = Ops.get_map(
        @template_network,
        ["attributes", "network", "networks"],
        {}
      )
      @teaming = Ops.get_map(
        @template_network,
        ["attributes", "network", "teaming"],
        {}
      )
      @mode = Ops.get_string(
        @template_network,
        ["attributes", "network", "mode"],
        ""
      )
      @conduit_map = Ops.get_list(
        @template_network,
        ["attributes", "network", "conduit_map"],
        []
      )

      @template_crowbar = Json.Read(@crowbar_file)
      @users = Ops.get_map(
        @template_crowbar,
        ["attributes", "crowbar", "users"],
        {}
      )

      if FileUtils.Exists(@provisioner_file)
        @provisioner = Json.Read(@provisioner_file)
      else
        @provisioner = {
          "attributes" => {
            "provisioner" => {
              "suse" => {
                "autoyast" => {
                  "repos" => {
                    "common"    => {},
                    "suse-11.3" => {},
                    "suse-12.0" => {}
                  }
                }
              }
            }
          }
        }
      end
      @repos = Ops.get_map(
        @provisioner,
        ["attributes", "provisioner", "suse", "autoyast", "repos"],
        {}
      )

      Ops.set(@repos, "common", {}) if !Builtins.haskey(@repos, "common")

      # fill in all the repo names for the UI
      Builtins.foreach(@default_repos) do |repo, target_product|
        if !Builtins.haskey(Ops.get(@repos, "common", {}), repo) &&
            !Builtins.haskey(Ops.get(@repos, "suse-11.3", {}), repo) &&
            !Builtins.haskey(Ops.get(@repos, "suse-12.0", {}), repo)
          Ops.set(@repos, [target_product, repo], { "url" => "" })
        end
      end

      Progress.NextStage

      @modified = false
      true
    end

    # Write all crowbar settings
    # @return true on success
    def Write
      # Crowbar read dialog caption
      caption = _("Saving crowbar Configuration")

      steps = 1

      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [
          # Progress stage 1/2
          _("Write the settings")
        ],
        [
          # Progress step 1/2
          _("Writing the settings..."),
          # Progress finished
          _("Finished")
        ],
        ""
      )


      Ops.set(
        @template_network,
        ["attributes", "network", "conduit_map"],
        @conduit_map
      )
      Ops.set(
        @template_network,
        ["attributes", "network", "networks"],
        @networks
      )
      Ops.set(@template_network, ["attributes", "network", "teaming"], @teaming)
      Ops.set(@template_network, ["attributes", "network", "mode"], @mode)

      if Json.Write(adapt_map(@template_network), @network_file) == nil
        Report.Error(Message.ErrorWritingFile(@network_file))
      end

      Ops.set(@template_crowbar, ["attributes", "crowbar", "users"], @users)
      if Json.Write(adapt_map(@template_crowbar), @crowbar_file) == nil
        Report.Error(Message.ErrorWritingFile(@crowbar_file))
      end

      Builtins.foreach(@repos) do |platform_name, platform|
        Builtins.foreach(
          Convert.convert(platform, :from => "map", :to => "map <string, map>")
        ) do |name, repo|
          # remove empty repo definitions
          if Ops.get_string(repo, "url", "") == "" &&
              !Ops.get_boolean(repo, "ask_on_error", false)
            Ops.set(
              @repos,
              platform_name,
              Builtins.remove(Ops.get(@repos, platform_name, {}), name)
            )
          # remove just url if it is empty and non-default ask_on_error stays
          elsif Ops.get_string(repo, "url", "") == ""
            Ops.set(@repos, [platform_name, name], Builtins.remove(repo, "url"))
          end
        end
      end

      Ops.set(
        @provisioner,
        ["attributes", "provisioner", "suse", "autoyast", "repos"],
        @repos
      )
      if Json.Write(adapt_map(@provisioner), @provisioner_file) == nil
        Report.Error(Message.ErrorWritingFile(@provisioner_file))
      end

      Progress.NextStage

      true
    end

    publish :variable => :network_file, :type => "string"
    publish :variable => :repos, :type => "map <string, map>"
    publish :variable => :networks, :type => "map <string, map>"
    publish :variable => :conduit_map, :type => "list <map>"
    publish :variable => :teaming, :type => "map <string, integer>"
    publish :variable => :mode, :type => "string"
    publish :variable => :users, :type => "map <string, map>"
    publish :variable => :installed, :type => "boolean"
    publish :function => :Modified, :type => "boolean ()"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
  end

  Crowbar = CrowbarClass.new
  Crowbar.main
end
