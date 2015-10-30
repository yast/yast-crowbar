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
require 'yaml'

module Yast
  class CrowbarClass < Module
    include Yast::Logger

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
      @installed_file = "/opt/dell/crowbar_framework/.crowbar-installed-ok"
      @repos_file = "/opt/dell/crowbar_framework/config/repos-cloud.yml"
      @etc_repos_file = Installation.destdir + "/etc/crowbar/repos.yml"

      # map of network template configuration data
      @template_network = {}

      # map of crowbar template configuration data
      @template_crowbar = {}

      # repos map
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

    # read given yaml file and return the content as a map
    def yaml2hash(file_name)
      ret = YAML.load(File.read(file_name))
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

    # write whole yaml map into new file
    def hash2yaml(data,file_name)
      if data.is_a? Hash
        begin
          File.open(file_name, 'w') do |f|
            f.puts YAML.dump data
          end
        rescue Errno::EACCES => e
          Builtins.y2error("exception while trying to write to %1: %2", file_name, e)
          return false
        end
      else
        Builtins.y2error("wrong data format passed as yaml hash!")
        return false
      end
      return true
    end

    def same_repos?(repo_a, repo_b)
      url_a = repo_a["url"] || ""
      url_b = repo_b["url"] || ""
      ask_on_error_a = repo_a["ask_on_error"] || false
      ask_on_error_b = repo_b["ask_on_error"] || false

      url_a == url_b && ask_on_error_a == ask_on_error_b
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

      if FileUtils.Exists(@repos_file)
        @repos = yaml2hash(@repos_file)
      else
        @repos = {}
      end

      if FileUtils.Exists(@etc_repos_file)
        etc_repos = yaml2hash(@etc_repos_file)

        etc_repos.each do |platform, arches|
          if @repos.key? platform
            arches.each do |arch, repos|
              if @repos[platform].key? arch
                repos.each do |id, repo|
                  # for repos that exist in our hard-coded file, we only allow
                  # overwriting a subset of attributes
                  if @repos[platform][arch].key? id
                    %w(url ask_on_error).each do |key|
                      @repos[platform][arch][id][key] = repo[key] if repo.key? key
                    end
                  else
                    @repos[platform][arch][id] = repo
                  end
                end
              else
                @repos[platform][arch] = repos
              end
            end
          else
            @repos[platform] = arches
          end
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

      if FileUtils.Exists(@repos_file)
        default_repos = yaml2hash(@repos_file)
      else
        default_repos = {}
      end

      @repos.each do |platform, arches|
        arches.each do |arch, repos|
          default_repos_prod = default_repos.fetch(platform, {}).fetch(arch, {})
          repos.each do |repo_name, repo|
            if default_repos_prod.key? repo_name
              # remove repos that have no change compared to defaults
              if same_repos?(default_repos_prod[repo_name], repo)
                @repos[platform][arch].delete(repo_name)
              else
                repo.each do |key, val|
                  repo.delete(key) unless %w(url ask_on_error).include? key
                end
              end
            end
          end
          @repos[platform].delete(arch) if @repos[platform][arch].empty?
        end
        @repos.delete(platform) if @repos[platform].empty?
      end

      if @repos.empty?
        File.delete(@etc_repos_file) if File.exist?(@etc_repos_file)
      else
        unless hash2yaml(@repos, @etc_repos_file)
          Report.Error(Message.ErrorWritingFile(@etc_repos_file))
        end
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
