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

# File:	include/crowbar/complex.rb
# Package:	Configuration of crowbar
# Summary:	Dialogs definitions
# Authors:     Jiri Suchomel <jsuchome@suse.cz>,
#              Michal Filka <mfilka@suse.cz>
#
module Yast
  module CrowbarComplexInclude
    def initialize_crowbar_complex(include_target)
      Yast.import "UI"

      textdomain "crowbar"

      Yast.import "Confirm"
      Yast.import "Crowbar"
      Yast.import "CWM"
      Yast.import "CWMTab"
      Yast.import "FileUtils"
      Yast.import "Hostname"
      Yast.import "Label"
      Yast.import "Popup"
      Yast.import "Stage"
      Yast.import "Wizard"
      Yast.import "IP"
      Yast.import "Netmask"

      Yast.include include_target, "crowbar/helps.rb"

      @small_screen = UI.GetDisplayInfo["Height"].to_i < 23

      # local copy of network settings
      @networks = {}

      # local copy of admin credentials
      @admin_user = ""
      @admin_password = ""

      # local copy of teaming options
      @teaming = {}

      # local copy of repositories
      @repos = {}

      # local copy of conduit_map
      @conduit_map = []

      # if bastion network should be added
      @enable_bastion = false

      # local copy of mode
      @mode = "single"

      # bastion network interfaces (present in conduit_map)
      @conduit_if_list = []

      # initial router_pref value for bastion network
      @initial_router_pref = 10

      @current_network = "admin"

      @current_user = ""

      # currently selected repository
      @current_repo = ""

      # platform value for currently selected repository
      @current_repo_platform = "suse-12.4"

      # arch value for currently selected repository
      @current_arch = "x86_64"

      @platform2label = {
        # target platform name
        "suse-12.4" => _("SLES 12 SP4")
      }

      @repos_location         = ""
      @remote_server_url      = ""

      @widget_description = {
        # ---------------- widgets for Repositories tab
        "repos_combo"     => {
          "widget" => :combobox,
          "opt"    => [:hstretch, :notify],
          # combobox label
          "label"  => _("&Location of Repositories"),
          "init"   => fun_ref(method(:InitReposCombo), "void (string)"),
          "handle" => fun_ref(method(:HandleReposCombo), "void (string, map)"),
          "help"   => _(
            "<p>Here you can edit the location of your <b>Update Repositories</b>.</p>\n" +
              "<p>\n" +
              "If repositories are stored at SMT server or SUSE Manager server, it's enough to enter server's URL and the paths
              to repositories will be filled automatically." +
              "</p>" +
              "It is also possible to use custom paths. Some examples of how the URL could look like:\n" +
              "</p><p>\n" +
              "<ul>\n" +
              "<li><i>http://smt.example.com/repo/SUSE/Products/SLE-HA/12-SP4/x86_64/product</i> for SMT server\n" +
              "<li><i>http://manager.example.com/ks/dist/child/suse-openstack-cloud-9-pool-x86_64/sles12-sp4-pool-x86_64/</i> for SUSE Manager Server.\n" +
              "</p><p>\n" +
              "For detailed description, check the Deployment Guide.\n" +
              "</p>"
          )
        },
        "repos_rp"        => {
          "widget"        => :custom,
          "no_help"       => true,
          "custom_widget" => ReplacePoint(
            Id("repos_rp"),
            VBox(VStretch())
          ),
          "init"          => fun_ref(method(:InitRPRepos), "void (string)"),
          "handle"        => fun_ref(
            method(:HandleRPRepos),
            "void (string, map)"
          )
        },
        # ---------------- widgets for Users tab
        "users_help"    => {
          "widget" => :empty,
          # generic help for Network tab
          "help"   => @HELPS["overview"] || ""
        },
        "admin_user" => {
          "widget"             => :textentry,
          "label"              => _("&Administrator User Name"),
          "opt"                => [:hstretch],
          "no_help"            => true,
          "init"               => fun_ref(method(:InitAdminUser), "void (string)"),
          "store"              => fun_ref(method(:StoreAdminUser), "void (string, map)"),
          "validate_type"      => :function_no_popup,
          "validate_function"  => fun_ref(method(:ValidateAdminUser), "boolean (string, map)"),
          "validate_help"      => _("User name cannot be empty.")
        },
        "admin_password" => {
          "widget"             => :password,
          "label"              => _("Pass&word"),
          "opt"                => [:hstretch],
          "no_help"            => true,
          "init"               => fun_ref(method(:InitAdminPassword), "void (string)"),
          "store"              => fun_ref(method(:StoreAdminPassword), "void (string, map)"),
          "validate_type"      => :function_no_popup,
          "validate_function"  => fun_ref(method(:ValidateAdminUser), "boolean (string, map)"),
          "validate_help"      => _("Password cannot be empty.")
        },
        # ---------------- widgets for Network Mode tab
        "mode"            => {
          "widget" => :combobox,
          "opt"    => [:hstretch, :notify],
          # textentry label
          "label"  => _("&Mode"),
          # help text for the Network mode tab (do not translate bastion)
          "help"   => _(
            "<p>Here, define a <b>Network Mode</b> with relevant <b>Bonding Policy</b>.</p>\n<p>You can also specify interface names for the bastion network conduits as space-separated list.</p>"
          ),
          "init"   => fun_ref(method(:InitMode), "void (string)"),
          "store"  => fun_ref(method(:StoreMode), "void (string, map)"),
          "handle" => fun_ref(method(:HandleMode), "symbol (string, map)")
        },
        "teaming"         => {
          "widget"  => :combobox,
          # textentry label
          "label"   => _("Bonding &Policy"),
          "no_help" => true,
          "init"    => fun_ref(method(:InitTeaming), "void (string)"),
          "store"   => fun_ref(method(:StoreTeaming), "void (string, map)"),
          "handle"  => fun_ref(method(:HandleTeaming), "symbol (string, map)")
        },
        "conduit_if_list" => {
          "widget"            => :textentry,
          # textentry label
          "label"             => _(
            "P&hysical interfaces mapping for bastion network"
          ),
          "validate_type"     => :function,
          "validate_function" => fun_ref(
            method(:ValidateConduitList),
            "boolean (string, map)"
          ),
          # help text for conduit if list
          "help"              => _(
            "<p>Each physical interface definition needs to fit the pattern\n" +
              "<tt>[Quantifier][Speed][Order]</tt>.\n" +
              "Valid examples are <tt>+1g2</tt>, <tt>10g1</tt> or <tt>?1g2</tt>.</p>"
          ),
          "init"              => fun_ref(
            method(:InitConduitList),
            "void (string)"
          ),
          "store"             => fun_ref(
            method(:StoreConduitList),
            "void (string, map)"
          )
        },
        # ---------------- widgets for Network tab
        "network_help"    => {
          "widget" => :empty,
          # generic help for Network tab
          "help"   => @HELPS["overview"] || ""
        },
        "network_select"  => {
          "widget"        => :custom,
          "custom_widget" => VBox(
            VWeight(
              2,
              Table(
                Id("network_select"),
                Opt(:notify, :immediate, :hstretch),
                # table header
                Header(
                  _("Network"),
                  _("Subnet Address"),
                  _("Network Mask"),
                  _("VLAN")
                )
              )
            )
          ),
          "init"          => fun_ref(
            method(:InitNetworkSelect),
            "void (string)"
          ),
          "handle"        => fun_ref(
            method(:HandleNetworkSelect),
            "symbol (string, map)"
          ),
          "no_help"       => true
        },
        "use_vlan"        => {
          "widget"  => :checkbox,
          # checkbox label
          "label"   => _("Use &VLAN"),
          "no_help" => true,
          "init"    => fun_ref(method(:InitCheckBox), "void (string)"),
          "store"   => fun_ref(method(:StoreNetwork), "void (string, map)"),
          "handle"  => fun_ref(method(:HandleNetwork), "symbol (string, map)"),
          "opt"     => [:notify]
        },
        "vlan"            => {
          "widget"  => :intfield,
          # textentry label
          "label"   => _("VLAN &ID"),
          "no_help" => true,
          "init"    => fun_ref(method(:InitInteger), "void (string)"),
          "store"   => fun_ref(method(:StoreNetwork), "void (string, map)"),
          "handle"  => fun_ref(method(:HandleNetwork), "symbol (string, map)"),
          "opt"     => [:notify, :hstretch]
        },
        "router"          => {
          "widget"            => :textentry,
          # textentry label
          "label"             => _("Rou&ter"),
          "validate_type"     => :function,
          "validate_function" => fun_ref(
            method(:ValidateNetwork),
            "boolean (string, map)"
          ),
          "valid_chars"       => IP.ValidChars4 + IP.ValidChars6,
          "no_help"           => true,
          "init"              => fun_ref(method(:InitNetwork), "void (string)"),
          "store"             => fun_ref(
            method(:StoreNetwork),
            "void (string, map)"
          ),
          "handle"            => fun_ref(
            method(:HandleNetwork),
            "symbol (string, map)"
          ),
          "opt"               => [:notify]
        },
        "router_pref"     => {
          "widget"  => :intfield,
          # textentry label
          "label"   => _("Router pre&ference"),
          "no_help" => true,
          "init"    => fun_ref(method(:InitInteger), "void (string)"),
          "store"   => fun_ref(method(:StoreNetwork), "void (string, map)"),
          "handle"  => fun_ref(method(:HandleNetwork), "symbol (string, map)"),
          "opt"     => [:notify, :hstretch]
        },
        "subnet"          => {
          "widget"            => :textentry,
          # textentry label
          "label"             => _("&Subnet"),
          "handle_events"     => ["ValueChanged"],
          "validate_type"     => :function,
          "validate_function" => fun_ref(
            method(:ValidateNetwork),
            "boolean (string, map)"
          ),
          "valid_chars"       => IP.ValidChars4 + IP.ValidChars6,
          "no_help"           => true,
          "init"              => fun_ref(method(:InitNetwork), "void (string)"),
          "store"             => fun_ref(
            method(:StoreNetwork),
            "void (string, map)"
          ),
          "handle"            => fun_ref(
            method(:HandleNetwork),
            "symbol (string, map)"
          ),
          "opt"               => [:notify]
        },
        "netmask"         => {
          "widget"            => :textentry,
          # textentry label
          "label"             => _("Net&mask"),
          "handle_events"     => ["ValueChanged"],
          "validate_type"     => :function,
          "validate_function" => fun_ref(
            method(:ValidateNetwork),
            "boolean (string, map)"
          ),
          "valid_chars"       => IP.ValidChars4 + IP.ValidChars6,
          "no_help"           => true,
          "init"              => fun_ref(method(:InitNetwork), "void (string)"),
          "store"             => fun_ref(
            method(:StoreNetwork),
            "void (string, map)"
          ),
          "handle"            => fun_ref(
            method(:HandleNetwork),
            "symbol (string, map)"
          ),
          "opt"               => [:notify]
        },
        "broadcast"       => {
          "widget"      => :textentry,
          "label"       => _("Broa&dcast"),
          "valid_chars" => IP.ValidChars4 + IP.ValidChars6,
          "no_help"     => true,
          "init"        => fun_ref(method(:InitNetwork), "void (string)"),
          "store"       => fun_ref(method(:StoreNetwork), "void (string, map)"),
          "opt"         => [:disabled]
        },
        "add_bridge"      => {
          "widget"  => :checkbox,
          # checkbox label
          "label"   => _("&Add Bridge"),
          "no_help" => true,
          "init"    => fun_ref(method(:InitCheckBox), "void (string)"),
          "store"   => fun_ref(method(:StoreNetwork), "void (string, map)"),
          "handle"  => fun_ref(method(:HandleNetwork), "symbol (string, map)")
        },
        "ranges_button"   => {
          "widget"  => :push_button,
          # push button label&
          "label"   => _("Edit Ran&ges..."),
          "no_help" => true,
          "handle"  => fun_ref(
            method(:HandleRangesButton),
            "symbol (string, map)"
          )
        },
        # ---------------- widgets for Bastion
        "enable_bastion"  => {
          "widget" => :checkbox,
          # checkbox label
          "label"  => _("Add &Bastion Network"),
          "help"   => @HELPS["bastion"] || "",
          "init"   => fun_ref(method(:InitBastionCheckbox), "void (string)"),
          "handle" => fun_ref(
            method(:HandleBastionCheckbox),
            "symbol (string, map)"
          ),
          "opt"    => [:notify]
        },
        "ip"              => {
          "widget"            => :textentry,
          # textentry label
          "label"             => _("&IP Address"),
          "handle_events"     => ["ValueChanged"],
          "validate_type"     => :function,
          "validate_function" => fun_ref(
            method(:ValidateNetwork),
            "boolean (string, map)"
          ),
          "valid_chars"       => IP.ValidChars4 + IP.ValidChars6,
          "no_help"           => true,
          "init"              => fun_ref(method(:InitNetwork), "void (string)"),
          "store"             => fun_ref(
            method(:StoreNetwork),
            "void (string, map)"
          ),
          "handle"            => fun_ref(
            method(:HandleNetwork),
            "symbol (string, map)"
          ),
          "opt"               => [:notify]
        }
      }
    end

    def ReallyAbort
      !Crowbar.Modified || Popup.ReallyAbort(true)
    end

    # Read settings dialog
    # @return `abort if aborted and `next otherwise
    def ReadDialog
      Wizard.RestoreHelp(@HELPS["read"] || "")
      return :abort unless Confirm.MustBeRoot
      ret = Crowbar.Read
      ret ? :next : :abort
    end

    # Write settings dialog
    # @return `abort if aborted and `next otherwise
    def WriteDialog
      Wizard.RestoreHelp(@HELPS["write"] || "")
      ret = Crowbar.Write
      ret ? :next : :abort
    end

    def InitAskOnError(id)
      ask = @repos.fetch(@current_repo_platform,{}).fetch(@current_arch,{}).fetch(@current_repo,{}).fetch("ask_on_error", false)
      UI.ChangeWidget(Id(id), :Value, ask)
      nil
    end

    def InitRepoURL(id)
      url = @repos[@current_repo_platform][@current_arch][@current_repo]["url"] rescue ""
      url ||= ""
      UI.ChangeWidget(Id(id), :Value, url)
      nil
    end

    # initialize the value of repo table
    def InitReposTable(id)
      repo_items = []
      @repos.each do |platform, arches|
        arches.each do |arch, repos|
          repos.each do |repo_id, repo|
            repo_items <<
              Item(
                Id("#{platform}|#{arch}|#{repo_id}"),
                repo["name"] || repo_id,
                repo["url"] || "",
                (repo["ask_on_error"] || false) ?  UI.Glyph(:CheckMark) : " ",
                "#{@platform2label[platform] || platform} (#{arch})"
              )
          end
        end
      end
      UI.ChangeWidget(Id(id), :Items, repo_items)
      UI.ChangeWidget(Id(id), :CurrentItem, "#{@current_repo_platform}|#{@current_arch}|#{@current_repo}") unless @current_repo.empty?
      nil
    end

    # handler for repo selection table
    def HandleReposTable(key, event)
      selected = UI.QueryWidget(Id(key), :Value)
      if !selected.nil? && (selected != @current_repo || event["force"])
        @current_repo_platform, @current_arch, @current_repo = selected.split("|")
        InitRepoURL("repo_url")
        InitAskOnError("ask_on_error")
      end
      nil
    end

    # handler for adding new repository button
    def HandleAddRepositoryButton(key, event)
      return nil unless event["ID"] == key

      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          HSpacing(1),
          VBox(
            VSpacing(0.5),
            HSpacing(65),
            # text entry label
            InputField(Id(:name), Opt(:hstretch), _("Name")),
            # text entry label
            InputField(Id(:url), Opt(:hstretch), _("URL")),
            HBox(
              HSpacing(0.5),
              # text entry label
              CheckBox(Id(:ask_on_error), Opt(:hstretch), _("Ask On Error"))
            ),
            RadioButtonGroup(
              Id(:platform),
              Frame(
                _("Target Platform"),
                HBox(
                  HSpacing(),
                  VBox(
                    # radiobutton label
                    Left(
                      RadioButton(Id("suse-12.4"), @platform2label["suse-12.4"])
                    )
                  )
                )
              )
            ),
            RadioButtonGroup(
              Id(:arch),
              Frame(
                _("Architecture"),
                HBox(
                  HSpacing(),
                  VBox(
                    # radiobutton label
                    Left(
                      RadioButton(Id("x86_64"), "x86_64")
                    )
                  )
                )
              )
            ),
            VSpacing(0.5),
            ButtonBox(
              PushButton(Id(:ok), Label.OKButton),
              PushButton(Id(:cancel), Label.CancelButton)
            ),
            VSpacing(0.5)
          ),
          HSpacing(1)
        )
      )

      ret = :not_next

      while true
        ret = UI.UserInput
        break if ret == :cancel
        if ret == :ok
          name = UI.QueryWidget(Id(:name), :Value)
          platform = UI.QueryWidget(Id(:platform), :Value) || "suse-12.4"
          arch = UI.QueryWidget(Id(:arch), :Value) || "x86_64"
          if name.empty?
            ret = :cancel
            break
          end

          if @repos[platform][arch].key? name
            # error popup
            Popup.Error(
              Builtins.sformat(
                _("Repository '%1' already exists.\nChoose a different name."),
                name
              )
            )
            UI.SetFocus(Id(:name))
            ret = :not_next
          end
          break if ret == :ok
        end
      end

      if ret == :ok
        @current_repo = name
        @current_arch = arch
        @current_repo_platform = platform
        @repos[@current_repo_platform] ||= {}
        @repos[@current_repo_platform][@current_arch] ||= {}
        @repos[@current_repo_platform][@current_arch][@current_repo] = {
          "url"          => UI.QueryWidget(Id(:url), :Value),
          "ask_on_error" => UI.QueryWidget(Id(:ask_on_error), :Value)
        }
      end
      UI.CloseDialog
      if ret == :ok
        InitReposTable("repos_table")
        InitRepoURL("repo_url")
        InitAskOnError("ask_on_error")
      end
      nil
    end

    def StoreRepoURL(key, event)
      @repos[@current_repo_platform][@current_arch][@current_repo]["url"] = UI.QueryWidget(Id(key), :Value)
      nil
    end

    def HandleRepoURL(key, event)
      # store the value on exiting
      if event["ID"] == :next || event["EventReason"] == "ValueChanged"
        StoreRepoURL(key, event)
        InitReposTable("repos_table")
      end
      nil
    end

    def InitLocationURL(id)
      UI.ChangeWidget(Id(id), :Value, @remote_server_url) unless @repos_location == "local"
      nil
    end

    def StoreLocationURL(key, event)
      @remote_server_url = UI.QueryWidget(Id(key), :Value)
      nil
    end

    def HandleLocationURL(key, event)

      StoreLocationURL(key, event)

      return nil if @remote_server_url.empty? || @repos_location == "custom"

      @repos.each do |platform, arches|
        arches.each do |arch, repos|
          distro = case platform
          when "suse-12.4"
            "sles12-sp4-#{arch}"
          end
          repos.each do |repo_name, r|
            # some repos are not at SM/SMT server
            url = ""
            if @repos_location == "smt"
              smt_path = @repos[platform][arch][repo_name]["smt_path"] || ""
              url = "#{@remote_server_url}/repo/#{smt_path}" unless smt_path.empty?
            elsif @repos_location == "sm"
              unless ["Cloud", "PTF"].include? repo_name
                url = "#{@remote_server_url}/ks/dist/child/#{repo_name.downcase}-#{arch}/#{distro}"
              end
            end
            @repos[platform][arch][repo_name] ||= {}
            @repos[platform][arch][repo_name]["url"] = url
          end
        end
      end

      # for SUSE Manager,
      # see http://docserv.nue.suse.com/documents/Cloud5/suse-openstack-cloud-deployment/single-html/#sec.depl.adm_conf.repos.scc.remote_susemgr
      # not ready for cloud6?
      # http://manager.example.com/ks/dist/child/sle-12-cloud-compute5-pool-x86_64/sles12-x86_64/
      # http://manager.example.com/ks/dist/child/sle-12-cloud-compute5-updates-x86_64/sles12-x86_64/
      nil
    end

    # in the repository tab, show only the location with remote URL
    def show_remote_server_widget
        UI.ReplaceWidget(
          Id("repos_rp"),
          VBox(
            VSpacing(0.4),
            InputField(
              Id("repos_location_url"),
              Opt(:hstretch, :notify),
              # text entry label
              _("Server &URL")
            ),
            VStretch()
          )
        )
    end

    # in the repository tab, show the full table with repo URL's
    def show_custom_repos_widget
        UI.ReplaceWidget(
          Id("repos_rp"),
          VBox(
            VSpacing(0.4),
            Table(
              Id("repos_table"),
              Opt(:notify, :immediate, :hstretch),
              Header(
                # table header
                _("Repository Name"),
                _("URL"),
                _("Ask On Error"),
                _("Target Platform")
              )
            ),
            # checkbox label
            Left(CheckBox(Id("ask_on_error"), Opt(:notify), _("&Ask On Error"))),
            VSpacing(),
            InputField(
              Id("repo_url"),
              Opt(:notify, :hstretch),
              # text entry label
              _("Repository &URL")
            ),
            # label (hint for user)
            Left(Label(_("Empty URL means that default value will be used."))),
            VSpacing(),
            # push button label
            Left(PushButton(Id("add_repository"), _("A&dd Repository")))
          )
        )
    end

    # initialize the replacepoint are for repository management:
    # selection of repository source and possibly the list of repositories
    def InitRPRepos(id)
      # find the initial location now
      if @repos_location.empty?
        @repos_location = "local"
        @repos.each do |product, arches|
          arches.each do |arch, repos|
            repos.each do |repo_name, r|
              url = r["url"] || ""
              if url.include? "/repo/SUSE/"
                @repos_location = "smt"
                @remote_server_url = url.gsub(/(^.*)\/repo\/SUSE\/.*/,"\\1")
              elsif url.include? "ks/dist/child"
                @repos_location = "sm"
                @remote_server_url = url.gsub(/(^.*)\/ks\/dist\/child\/.*/,"\\1")
              elsif !url.empty?
                @repos_location = "custom"
              end
              break unless @repos_location == "local"
            end
            break unless @repos_location == "local"
          end
        end
      end

      if @repos_location == "custom"
        show_custom_repos_widget
      elsif @repos_location == "local"
        UI.ReplaceWidget(Id("repos_rp"), VBox(VStretch()))
      else
        show_remote_server_widget
      end

      # initialization of ReplacePoint content
      if @repos_location == "custom"
        InitReposTable("repos_table")
        HandleReposTable("repos_table", { "force" => true })
      elsif @repos_location != ""
        InitLocationURL("repos_location_url")
      end
      nil
    end

    def HandleRPRepos(key, event)
      subkey = event["ID"]

      case subkey
      when "repos_table"
        HandleReposTable(subkey, event)
      when "repo_url"
        HandleRepoURL(subkey, event)
      when "ask_on_error"
        HandleAskOnError(subkey, event)
      when "repos_location_url"
        HandleLocationURL(subkey, event)
      when "add_repository"
        HandleAddRepositoryButton(subkey, event)
      end
      nil
    end

    def InitReposCombo(id)
      items = [
        # combobox item
        Item(Id("local"), _("Local SMT Server"), "local" == @repos_location),
        # combobox item
        Item(Id("smt"), _("Remote SMT Server"), "smt" == @repos_location),
        # combobox item
        Item(Id("sm"), _("SUSE Manager Server"), "sm" == @repos_location),
        # combobox item
        Item(Id("custom"), _("Custom"),
          "custom" == @repos_location || @repos_location.empty?
        )
      ]
      UI.ChangeWidget(Id(id), :Items, items)
      nil
    end

    def HandleReposCombo(key, event)
      old_repos_location = @repos_location
      @repos_location = UI.QueryWidget(Id(key), :Value)

      return if old_repos_location == @repos_location

      InitRPRepos("repos_rp")
      nil
    end


    def StoreAskOnError(key, event)
      @repos[@current_repo_platform][@current_arch][@current_repo]["ask_on_error"] =
        UI.QueryWidget(Id(key), :Value) == true
      nil
    end

    def HandleAskOnError(key, event)
      # store the value on exiting
      if event["ID"] == :next || event["EventReason"] == "ValueChanged"
        StoreAskOnError(key, event)
        InitReposTable("repos_table")
      end
      nil
    end

    def InitAdminUser(id)
      UI.ChangeWidget(Id(id), :Value, @admin_user)
      nil
    end

    def StoreAdminUser(key, event)
      @admin_user = UI.QueryWidget(Id(key), :Value)
      nil
    end

    def InitAdminPassword(id)
      UI.ChangeWidget(Id(id), :Value, @admin_password)
      nil
    end

    def ValidateAdminUser(key, event)
      UI.QueryWidget(Id(key), :Value) != ""
    end

    def StoreAdminPassword(key, event)
      @admin_password = UI.QueryWidget(Id(key), :Value)
      nil
    end

    # functions for handling network mode widget
    def InitMode(id)
      items = [
        Item(Id("single"), "single", "single" == @mode),
        Item(Id("dual"), "dual", "dual" == @mode),
        Item(Id("team"), "team", "team" == @mode)
      ]
      UI.ChangeWidget(Id(id), :Items, items)
      UI.ChangeWidget(Id(id), :Enabled, !Crowbar.installed)
      nil
    end

    def StoreMode(key, event)
      @mode = UI.QueryWidget(Id(key), :Value)
      nil
    end

    def HandleMode(key, event)
      StoreMode(key, event)
      UI.ChangeWidget(Id("teaming"), :Enabled, @mode == "team")
      nil
    end

    def InitConduitList(id)
      UI.ChangeWidget(Id(id), :Value, @conduit_if_list.join(" "))
      nil
    end

    def StoreConduitList(key, event)
      @conduit_if_list = (UI.QueryWidget(Id(key), :Value) || "").split(" ")
      nil
    end

    # Validate logical network values for conduit list
    def ValidateConduitList(key, event)
      # [Quantifier][Speed][Order]
      # Quantifier is optional; for speed there are only 4 options; order starts with 1
      reg = "^[-+?]*(10m|100m|1g|10g)[1-9]+[0-9]*$"

      invalid_if = Builtins.find(
        (UI.QueryWidget(Id(key), :Value) || "").split(" ")
      ) do |iface|
        if !Builtins.regexpmatch(iface, reg)
          Builtins.y2warning("iface %1 has incorrect format", iface)
          next true
        end
        false
      end


      if invalid_if != nil
        # error popup
        Popup.Error(
          Builtins.sformat(
            _("The interface format '%1' is not valid"),
            invalid_if
          )
        )
        return false
      end
      true
    end

    # functions for handling network teaming widget
    def InitTeaming(id)
      value = @teaming["mode"] || 0
      items = (0..6).map {|i| Item(Id(i), i.to_s, i == value) }
      UI.ChangeWidget(Id(id), :Items, items)
      UI.ChangeWidget(Id(id), :Enabled, !Crowbar.installed && @mode == "team")
      nil
    end

    def StoreTeaming(key, event)
      @teaming["mode"] = UI.QueryWidget(Id(key), :Value).to_i
      nil
    end

    def HandleTeaming(key, event)
      StoreTeaming(key, event) if event["ID"] == :next
      nil
    end

    def GetRouter
      UI.QueryWidget(Id("router"), :Value)
    end

    # Returns current subnet as filled in dialog
    def GetSubnet
      UI.QueryWidget(Id("subnet"), :Value)
    end

    # Returns current netmask as filled in dialog
    def GetNetmask
      UI.QueryWidget(Id("netmask"), :Value)
    end

    # Returns broadcast address. Based on current netmask and subnet
    def GetBroadcast
      subnet = GetSubnet()
      netmask = GetNetmask()
      return "" if subnet.empty? || netmask.empty?
      IP.ComputeBroadcast(subnet, netmask)
    end

    def CreateItem(name)
      Item(
        Id(name),
        name,
        @networks[name]["subnet"] || "",
        @networks[name]["netmask"] || "",
        (@networks[name]["use_vlan"] || false) ?
          Builtins.sformat("%1", @networks[name]["vlan"] || 0) : _("disabled")
      )
    end

    def CreateItemList
      items = []
      Builtins.foreach(@networks) do |name, n|
        items = Builtins.add(items, CreateItem(name)) if name != "bastion"
      end
      items
    end
    # universal widget: initialize the string value of widget @param
    def InitNetwork(id)
      UI.ChangeWidget(Id(id), :Enabled, !Crowbar.installed)
      if id == "broadcast"
        UI.ChangeWidget(Id(id), :Value, GetBroadcast())
        return
      end

      UI.ChangeWidget(Id(id), :Value, @networks[@current_network][id] || "")
      nil
    end

    # universal widget: initialize the integer value of widget @param
    def InitInteger(id)
      UI.ChangeWidget(Id(id), :Value, @networks[@current_network][id] || 0)
      if id == "vlan"
        UI.ChangeWidget(
          Id(id),
          :Enabled,
          !Crowbar.installed && (@networks[@current_network]["use_vlan"] || false)
        )
      end
      if id == "router_pref"
        UI.ChangeWidget(
          Id(id),
          :Enabled,
          !Crowbar.installed && !(@networks[@current_network]["router"] || "").empty?
        )
      end
      nil
    end

    # initialize the value of table
    def InitNetworkSelect(id)
      if CWMTab.CurrentTab == "networks"
        @current_network = "admin" if @current_network == "bastion"
        UI.ChangeWidget(Id(id), :Items, CreateItemList())
        UI.ChangeWidget(Id(id), :CurrentItem, @current_network)
      end
      nil
    end

    # store the string value of given widget
    def StoreNetwork(key, event)
      return if @networks.empty? || key == "mode" ||
        CWMTab.CurrentTab == "network_mode" && !@enable_bastion

      if (key == "router" || key == "router_pref") && GetRouter() == ""
        if @networks[@current_network].key? key
          # do not save empty router values to json
          # do not save router_pref if router is not defined
          @networks[@current_network].delete key
        end
        return
      end
      if key == "subnet"
        @networks[@current_network][key] = IP.ComputeNetwork(GetSubnet(), GetNetmask())
        return
      end
      @networks[@current_network][key] = UI.QueryWidget(Id(key), :Value)
      nil
    end

    # Validate entered network values
    def ValidateNetwork(key, event)
      ret = true

      if event["WidgetID"] == :back || @networks.empty?
        return true
      end
      return true if CWMTab.CurrentTab == "network_mode" && !@enable_bastion

      subnet = GetSubnet()
      netmask = GetNetmask()
      router = UI.QueryWidget(Id("router"), :Value)
      ip = ""
      if UI.WidgetExists(Id("ip"))
        ip = UI.QueryWidget(Id("ip"), :Value)
      end

      ret = key != "netmask" || Netmask.Check(netmask)
      unless ret
        # error popup
        Popup.Error(
          Builtins.sformat(
            _("The netmask '%1' is invalid.\n%2"), netmask, IP.Valid4
          )
        )
        return false
      end

      ret = key != "subnet" || IP.Check(subnet)
      unless ret
        # error popup
        Popup.Error(
          Builtins.sformat(
            _("The IP address '%1' is invalid.\n%2"), subnet, IP.Valid4
          )
        )
        return false
      end
      if key == "router" && router != ""
        if !IP.Check(router)
          # error popup
          Popup.Error(
            Builtins.sformat(
              _("The router address '%1' is invalid.\n%2"), router, IP.Valid4
            )
          )
          return false
        end
        if IP.ComputeNetwork(subnet, netmask) != IP.ComputeNetwork(router, netmask)
          # error popup
          Popup.Error(
            Builtins.sformat(
              _("The router address '%1' is not part of network '%2'."),
              router,
              @current_network
            )
          )
          return false
        end
      end
      if key == "ip" && ip != ""
        unless IP.Check(ip)
          # error popup
          Popup.Error(
            Builtins.sformat(
              _("The IP address '%1' is invalid.\n%2"), ip, IP.Valid4
            )
          )
          return false
        end
        if IP.ComputeNetwork(subnet, netmask) != IP.ComputeNetwork(ip, netmask)
          # error popup
          Popup.Error(
            Builtins.sformat(
              _("The IP address '%1' is not part of network '%2'."),
              ip,
              @current_network
            )
          )
          return false
        end
      end
      # check if ranges are still in network
      if key == "subnet"
        ranges_fine = true
        (@networks[@current_network]["ranges"] || {}).each { |name, range|
          ["start", "end"].each do |part|
            ip2 = range[part] || ""
            ranges_fine = false if IP.ComputeNetwork(ip2, netmask) != subnet
          end
        }
        unless ranges_fine
          # popup message
          Popup.Warning(
            Builtins.sformat(
              _("Some address ranges are not part of network '%1'.\nAdapt them using 'Edit ranges' button."),
              @current_network
            )
          )
          return false
        end
      end
      ret
    end

    # handler for general string-value widgets: store their value on exit/save
    def HandleNetwork(key, event)
      if key == "use_vlan" && event["ID"] == "use_vlan"
        UI.ChangeWidget(Id("vlan"), :Enabled, UI.QueryWidget(Id(key), :Value) == true)
      end
      if key == "router_pref" && event["ID"] == "router"
        UI.ChangeWidget(Id("router_pref"), :Enabled, GetRouter() != "")
      end
      # store the value on exiting
      if event["EventReason"] == "ValueChanged"
        if IP.Check(GetSubnet()) && IP.Check(GetNetmask())
          UI.ChangeWidget(Id("broadcast"), :Value, GetBroadcast())
          StoreNetwork(event["ID"], event)
          InitNetworkSelect("network_select")
        end
      end
      StoreNetwork(key, event) if event["ID"] == :next
      nil
    end


    # universal widget: initialize the string value of widget @param
    def InitCheckBox(id)
      UI.ChangeWidget(Id(id), :Value, @networks[@current_network][id] || false)
      UI.ChangeWidget(Id(id), :Enabled, !Crowbar.installed)
      if id == "use_vlan"
        UI.ChangeWidget(Id("vlan"), :Enabled, !Crowbar.installed && UI.QueryWidget(Id(id), :Value) == true)
      end
      nil
    end

    # handler network selection table
    def HandleNetworkSelect(key, event)
      selected = UI.QueryWidget(Id(key), :Value)
      if selected != @current_network
        validated = true
        ["netmask", "subnet", "router"].each do |key2|
          validated = validated && ValidateNetwork(key2, event)
        end
        unless validated
          UI.ChangeWidget(Id(key), :CurrentItem, @current_network)
          return nil
        end
        [
          "netmask",
          "subnet",
          "add_bridge",
          "use_vlan",
          "vlan",
          "broadcast",
          "router"
        ].each do |key2|
          StoreNetwork(key2, {})
        end
        @current_network = selected
        ["netmask", "subnet", "broadcast", "router"].each do |key2|
          InitNetwork(key2)
        end
        InitCheckBox("use_vlan")
        InitCheckBox("add_bridge")
        InitInteger("vlan")
      end
      nil
    end

    # handler for ranges button
    def HandleRangesButton(key, event)
      return nil unless event["ID"] == key

      subnet = @networks[@current_network]["subnet"] || ""
      netmask = @networks[@current_network]["netmask"] || ""
      ranges = deep_copy(@networks[@current_network]["ranges"] || {})
      ranges_term = VBox()

      ranges.each do |name, range|
        r = Frame(
          name,
          HBox(
            InputField(
              Id(name + "_start"),
              Opt(:hstretch),
              # inputfield label
              _("Min IP Address"),
              range["start"] || ""
            ),
            InputField(
              Id(name + "_end"),
              Opt(:hstretch),
              # inputfield label
              _("Max IP Address"),
              range["end"] || ""
            )
          )
        )
        ranges_term.params << r
      end

      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          HSpacing(1),
          VBox(
            VSpacing(0.5),
            HSpacing(65),
            ranges_term,
            VSpacing(0.5),
            ButtonBox(
              PushButton(Id(:ok), Label.OKButton),
              PushButton(Id(:cancel), Label.CancelButton)
            ),
            VSpacing(0.5)
          ),
          HSpacing(1)
        )
      )

      ranges.each do |name, range|
        UI.ChangeWidget(Id(name + "_start"), :ValidChars, IP.ValidChars4 + IP.ValidChars6)
        UI.ChangeWidget(Id(name + "_end"), :ValidChars, IP.ValidChars4 + IP.ValidChars6)
        UI.ChangeWidget(Id(name + "_start"), :Enabled, !Crowbar.installed)
        UI.ChangeWidget(Id(name + "_end"), :Enabled, !Crowbar.installed)
      end

      UI.ChangeWidget(Id(:ok), :Enabled, !Crowbar.installed)

      ret = :not_next
      while true
        ret = UI.UserInput
        break if ret == :cancel
        if ret == :ok
          widget = ""
          ranges_l = []
          ranges.each do |name, range|
            next if widget != ""
            ["start", "end"].each do |part|
              ip = UI.QueryWidget(Id(name + "_" + part), :Value)
              if !IP.Check(ip)
                Popup.Error(IP.Valid4)
                widget = name + "_" + part
              elsif IP.ComputeNetwork(ip, netmask) != subnet
                Popup.Error(
                  Builtins.sformat(
                    _("The address '%1' is not part of network '%2'."),
                    ip,
                    @current_network
                  )
                )
                widget = name + "_" + part
              end
              ranges[name][part] = ip
            end
            if widget == "" &&
              IP.ToInteger(ranges[name]["start"] || "") > IP.ToInteger(ranges[name]["end"] || "")
              # error message
              Popup.Error(_("The lowest address must be lower than the highest one."))
              widget = name + "_end"
            else
              ranges_l <<
                [
                  IP.ToInteger(ranges[name]["start"] || ""),
                  IP.ToInteger(ranges[name]["end"] || ""),
                  name
                ]
            end
          end
          # check if ranges do not overlap
          if widget == "" && ranges_l.size > 1
            ranges_l = Builtins.sort(ranges_l) do |a, b|
              a[0] || 0 <= b[0] || 0
            end
            i = 0
            while i < (ranges_l.size - 1)
              _this = ranges_l[i] || []
              _next = ranges_l[i+1] || []
              if (_this[1] || 0) >= (_next[0] || 0)
                # error message
                Popup.Error(
                  Builtins.sformat(
                    _("Ranges '%1' and '%2' are overlapping."), _this[2] || "", _next[2] || ""
                  )
                )
                widget = (_next[2] || "") + "_start"
              end
              i += 1
            end
          end
          # finally, save the ranges
          if widget == ""
            @networks[@current_network]["ranges"] = ranges
            break
          else
            ret = :not_next
            UI.SetFocus(Id(widget))
            next
          end
        end
      end

      UI.CloseDialog
      nil
    end

    def enable_disable_bastion
      [
        "ip",
        "router",
        "subnet",
        "netmask",
        "broadcast",
        "use_vlan",
        "conduit_if_list"
      ].each { |w| UI.ChangeWidget(Id(w), :Enabled, !Crowbar.installed && @enable_bastion) }
      UI.ChangeWidget(
        Id("vlan"),
        :Enabled,
        !Crowbar.installed && @enable_bastion && (@networks[@current_network]["use_vlan"] || false)
      )
      UI.ChangeWidget(
        Id("router_pref"),
        :Enabled,
        !Crowbar.installed && @enable_bastion && @networks[@current_network]["router"] != ""
      )
      nil
    end

    # initialize the value of Enable Bastion checkbox
    def InitBastionCheckbox(id)
      @current_network = "bastion"

      UI.ChangeWidget(Id(id), :Enabled, !Crowbar.installed)
      UI.ChangeWidget(Id(id), :Value, @enable_bastion)
      enable_disable_bastion
      nil
    end

    def HandleBastionCheckbox(key, event)
      @enable_bastion = UI.QueryWidget(Id(key), :Value) == true
      enable_disable_bastion
      nil
    end

    # description of tab layouts
    def get_tabs_descr
      {
        "users"        => {
          # tab header
          "header"       => _("&User Settings"),
          "contents"     => HBox(
            HSpacing(2),
            VBox(
              "users_help",
              VSpacing(),
              "admin_user",
              VSpacing(),
              "admin_password",
              VStretch()
            ),
            HSpacing(2)
          ),
          "widget_names" => [
            "users_help",
            "admin_user",
            "admin_password"
          ]
        },
        "network_mode" => {
          # tab header
          "header"       => _("N&etwork Mode"),
          "contents"     => HBox(
            HSpacing(2),
            VBox(
              VSpacing(),
              HBox("mode", "teaming"),
              VSpacing(),
              Frame(
                _("Bastion Network"),
                HBox(
                  HSpacing(0.5),
                  VBox(
                    VSpacing(0.4),
                    Left("enable_bastion"),
                    VSpacing(0.4),
                    "ip",
                    HBox(
                      VBox("use_vlan", Label("")),
                      HWeight(1, "vlan"),
                      HWeight(8, Empty())
                    ),
                    HBox("router", "router_pref"),
                    HBox("subnet", "netmask", "broadcast"),
                    VSpacing(0.4),
                    "conduit_if_list",
                    VSpacing(0.4)
                  ),
                  HSpacing(0.5)
                )
              ),
              VStretch()
            ),
            HSpacing(2)
          ),
          "widget_names" => [
            "mode",
            "teaming",
            "conduit_if_list",
            "enable_bastion",
            "ip",
            "vlan",
            "router",
            "subnet",
            "netmask",
            "broadcast",
            "use_vlan",
            "router_pref"
          ]
        },
        "networks"     => {
          # tab header
          "header"       => _("Net&works"),
          "contents"     => HBox(
            HSpacing(2),
            VBox(
              "network_help",
              @small_screen ? Empty() : VSpacing(),
              "network_select",
              Left("add_bridge"),
              VSpacing(0.4),
              HBox(
                VBox("use_vlan", Label("")),
                HSpacing(2),
                "vlan"
              ),
              "router",
              HBox("subnet", "netmask", "broadcast"),
              VSpacing(0.4),
              Right("ranges_button")
            ),
            HSpacing(2)
          ),
          "widget_names" => [
            "network_select",
            "vlan",
            "router",
            "subnet",
            "netmask",
            "broadcast",
            "add_bridge",
            "ranges_button",
            "use_vlan",
            "network_help"
          ]
        },
        "repositories" => {
          # tab header
          "header"       => _("Re&positories"),
          "contents"     => HBox(
            HSpacing(2),
            VBox(
              VSpacing(0.4),
              "repos_combo",
              "repos_rp"
            ),
            HSpacing(2)
          ),
          "widget_names" => [
            "repos_rp",
            "repos_combo",
            "repo_url",
            "ask_on_error",
          ]
        }
      }
    end

    # Adapts global conduit_map:
    #      - add new subsection for bastion network with conduit_if_list value (entered by user)
    #      - if conduit value for bastion is not defined, generate new (unique) one
    #      - find place for bastion in conduit list by checking mode pattern
    # @return new conduit name (
    def adapt_conduit_map(conduit)
      conduit_name = conduit
      name_found = false

      @conduit_map.each do |c_map|
        # ignore not matching patterns
        next c_map unless c_map["pattern"] =~ /#{@mode}/
        unless name_found
          # if non-empty conduit was provided && it exist for the right pattern, use it
          if c_map["conduit_list"].key? conduit
            name_found = true
          else
            if conduit == ""
              conduit = "bastion"
              conduit_name = "bastion"
            end
            i = 0
            while  c_map["conduit_list"].key? conduit_name
              conduit_name = "#{conduit}#{i}"
              i += 1
            end
            name_found = true
          end
        end
        c_map["conduit_list"][conduit_name] = { "if_list" => @conduit_if_list }
      end
      conduit_name
    end

    # Find if_list relevant for given bastion network
    def get_conduit_if_list(bastion)
      conduit_name = bastion["conduit"] || ""
      if_list   = []
      @conduit_map.each do |c_map|
        if (c_map["pattern"] =~ /#{@mode}/) && (c_map["conduit_list"].key? conduit_name)
          if_list = c_map["conduit_list"][conduit_name]["if_list"] rescue []
        end
      end
      if_list
    end

    def OverviewDialog
      @networks         = Crowbar.networks
      @mode             = Crowbar.mode
      @teaming          = Crowbar.teaming
      @admin_user       = Crowbar.admin_user
      @admin_password   = Crowbar.admin_password
      @repos            = Crowbar.repos
      @conduit_map      = Crowbar.conduit_map
      @enable_bastion   = @networks.key? "bastion"

      if @enable_bastion
        @networks["bastion"]["ip"] = @networks["bastion"]["ranges"]["admin"]["start"] rescue "0"
        @conduit_if_list = get_conduit_if_list(@networks["bastion"] || {})
      else
        @networks["bastion"]    = {}
      end

      # find out initial router_pref value for bastion network and set it lower than in admin network
      @initial_router_pref = @networks["admin"]["router_pref"] || @initial_router_pref
      if @initial_router_pref > 0
        @initial_router_pref -= 1
      end
      unless @networks["bastion"].key? "router_pref"
        @networks["bastion"]["router_pref"] = @initial_router_pref
      end

      @widget_description["tab"] = CWMTab.CreateWidget(
          {
            "tab_order"    => [
              "users",
              "networks",
              "network_mode",
              "repositories"
            ],
            "tabs"         => get_tabs_descr,
            "widget_descr" => @widget_description,
            "initial_tab"  => "users"
          }
      )

      Wizard.SetContentsButtons(
        "",
        VBox(),
        "",
        Label.BackButton,
        Label.FinishButton
      )

      if Crowbar.installed
        # popup message %1 is FQDN
        Popup.Message(
          Builtins.sformat(
            _(
              "The Crowbar Admin Server has been deployed. Changing the network is\n" +
                "currently not supported.\n" +
                "\n" +
                "You can visit the Crowbar web UI on http://%1:3000/"
            ),
            Hostname.CurrentFQ
          )
        )
      end


      ret = CWM.ShowAndRun(
        {
          "widget_names" => ["tab"],
          "widget_descr" => @widget_description,
          "contents"     => VBox("tab"),
          # default dialog caption
          "caption"      => _(
            "Crowbar Configuration Overview"
          ),
          "abort_button" => Stage.cont ? Label.AbortButton : nil,
          "next_button"  => Stage.cont ? Label.NextButton : Label.OKButton,
          "back_button"  => Stage.cont ? Label.BackButton : Label.CancelButton
        }
      )

      # not saving
      return :back if Crowbar.installed

      if ret == :next
        if @enable_bastion
          # remove internal "ip" key and transform it to ranges (ip-ip)
          bastion = @networks["bastion"] || {}
          bastion["ranges"] ||= {}
          bastion["ranges"]["admin"] = {
            "start" => bastion["ip"] || "0",
            "end"   => bastion["ip"] || "0"
          }
          bastion.delete "ip"
          # add conduit to bastion network submap
          bastion["conduit"] = adapt_conduit_map(bastion["conduit"] || "")
          bastion["add_bridge"] = false
          @networks["bastion"] = bastion
        elsif @networks.key? "bastion"
          @networks.delete "bastion"
        end
        Crowbar.networks = @networks
        Crowbar.conduit_map = @conduit_map # was adapted by adapt_conduit_map
        Crowbar.admin_user = @admin_user
        Crowbar.admin_password = @admin_password
        Crowbar.teaming = @teaming
        Crowbar.mode = @mode
        Crowbar.repos = @repos
      end
      ret
    end
  end
end
