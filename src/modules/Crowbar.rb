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

# File:	modules/Crowbar.rb
# Package:	Configuration of crowbar
# Summary:	Crowbar settings, input and output functions
# Authors:     Jiri Suchomel <jsuchome@suse.cz>
#              Michal Filka <mfilka@suse.cz>
#
require "yast"
require 'json'

module Yast
  class CrowbarClass < Module
    def main
      textdomain "crowbar"

      Yast.import "FileUtils"
      Yast.import "Installation"
      Yast.import "Message"
      Yast.import "Progress"
      Yast.import "Report"

      # Path to the files with JSON data
      @network_file = Installation.destdir + "/etc/crowbar/network.json"
      @crowbar_file = Installation.destdir + "/etc/crowbar/crowbar.json"
      @provisioner_file = Installation.destdir + "/etc/crowbar/provisioner.json"
      @installed_file = "/opt/dell/crowbar_framework/.crowbar-installed-ok"

      # The keys are the names of default repositories available for current product
      # For Cloud5, we support mixed SLE11/SLE12 environments
      #
      # The values are target node platform for those repositories
      @default_repos = {
        "Cloud"                                 => "suse-11.3",
        "SUSE-OpenStack-Cloud-SLE11-6-Pool"     => "suse-11.3",
        "SUSE-OpenStack-Cloud-SLE11-6-Updates"  => "suse-11.3",
        "SLES11-SP3-Pool"                       => "suse-11.3",
        "SLES11-SP3-Updates"                    => "suse-11.3",
        "SLE11-HAE-SP3-Pool"                    => "suse-11.3",
        "SLE11-HAE-SP3-Updates"                 => "suse-11.3",
        # sle12 based repos:
        "SLES12-Pool"                           => "suse-12.0",
        "SLES12-Updates"                        => "suse-12.0",
        "Cloud"                                 => "suse-12.0",
        "SUSE-OpenStack-Cloud-6-Pool"           => "suse-12.0",
        "SUSE-OpenStack-Cloud-6-Updates"        => "suse-12.0",
        "SUSE-Enterprise-Storage-1.0-Pool"      => "suse-12.0",
        "SUSE-Enterprise-Storage-1.0-Updates"   => "suse-12.0",
        # common repos
        "PTF"                                   => "common"
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

    # Data was modified?
    # @return true if modified
    def Modified
      Builtins.y2debug("modified=%1", @modified)
      @modified
    end

    # read given json file and return the content as a map
    def json2hash(file_name)
      ret = JSON.parse(File.read(file_name))
      ret = {} unless ret.is_a? Hash
      ret
    end

    # write whole json map into new file
    def hash2json(data,file_name)
      if data.is_a? Hash
        begin
          File.open(file_name, 'w') do |f|
            f.puts JSON.pretty_generate data
          end
        rescue Errno::EACCES => e
          Builtins.y2error("exception while trying to write to %1: %2", file_name, e)
          return false
        end
      else
        Builtins.y2error("wrong data format passed as json hash!")
        return false
      end
      return true
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

      unless FileUtils.Exists(@network_file)
        Report.Error(Message.CannotOpenFile(@network_file))
        return false
      end

      unless FileUtils.Exists(@crowbar_file)
        Report.Error(Message.CannotOpenFile(@crowbar_file))
        return false
      end


      @template_network = json2hash(@network_file)

      network = @template_network["attributes"]["network"] rescue {}
      @networks = network["networks"] || {}
      @teaming = network["teaming"] || {}
      @mode = network["mode"] || ""
      @conduit_map = network["conduit_map"] || []

      @template_crowbar = json2hash(@crowbar_file)
      @users = @template_crowbar["attributes"]["crowbar"]["users"] rescue {}

      if FileUtils.Exists(@provisioner_file)
        @provisioner = json2hash(@provisioner_file)
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
      @repos = @provisioner["attributes"]["provisioner"]["suse"]["autoyast"]["repos"] rescue {}

      ["common", "suse-11.3", "suse-12.0"].each do |target_product|
        @repos[target_product] ||= {}
      end

      # fill in all the repo names for the UI
      @default_repos.each do |repo, target_product|
        unless (@repos["common"].key?(repo) ||
                @repos["suse-11.3"].key?(repo) ||
                @repos["suse-12.0"].key?(repo))
          @repos[target_product][repo]  = { "url" => "" }
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


      @template_network["attributes"]["network"]["conduit_map"] = @conduit_map
      @template_network["attributes"]["network"]["teaming"]     = @teaming
      @template_network["attributes"]["network"]["mode"]        = @mode

      unless hash2json(@template_network, @network_file)
        Report.Error(Message.ErrorWritingFile(@network_file))
      end

      @template_crowbar["attributes"]["crowbar"]["users"]       = @users
      unless hash2json(@template_crowbar, @crowbar_file)
        Report.Error(Message.ErrorWritingFile(@crowbar_file))
      end

      @repos.each do |product_name, product|
        product.each do |repo_name, repo|
          # remove empty repo definitions
          if repo["url"].empty? && !(repo["ask_on_error"] || false)
            @repos[product_name].delete(repo_name)
          # remove just url if it is empty and non-default ask_on_error stays
          elsif repo["url"].empty?
            @repos[product_name][repo_name].delete("url")
          end
        end
      end

      @provisioner["attributes"]["provisioner"]["suse"]["autoyast"]["repos"] = @repos

      unless hash2json(@provisioner, @provisioner_file)
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
