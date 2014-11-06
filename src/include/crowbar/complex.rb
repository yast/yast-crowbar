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

# File:	include/crowbar/complex.ycp
# Package:	Configuration of crowbar
# Summary:	Dialogs definitions
# Authors:     Jiri Suchomel <jsuchome@suse.cz>,
#              Michal Filka <mfilka@suse.cz>
#
# $Id: complex.ycp 65771 2011-09-19 07:37:30Z visnov $
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


      # local copy of network settings
      @networks = {}

      # local copy of user settings
      @users = {}

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

      @current_repo = ""

      @widget_description = {
        # ---------------- widgets for Repositories tab
        "repos_table"     => {
          "widget"        => :custom,
          "custom_widget" => VBox(
            VWeight(
              2,
              Table(
                Id("repos_table"),
                Opt(:notify, :immediate, :hstretch),
                # table header
                Header(_("Repository Name"), _("URL"), _("Ask On Error"))
              )
            )
          ),
          "init"          => fun_ref(method(:InitReposTable), "void (string)"),
          "handle"        => fun_ref(
            method(:HandleReposTable),
            "symbol (string, map)"
          ),
          # help text
          "help"          => _(
            "<p>Here you can edit the location of your <b>Update Repositories</b>.</p>\n" +
              "<p>\n" +
              "Some examples of how the URL could look like:\n" +
              "</p><p>\n" +
              "<ul>\n" +
              "<li><i>http://smt.example.com/repo/$RCE/SLES11-SP3-Pool/sle-11-x86_64/</i> for SMT server\n" +
              "<li><i>http://manager.example.com/ks/dist/child/suse-cloud-3.0-pool-x86_64/sles11-sp3-x86_64/</i> for SUSE Manager Server.\n" +
              "</p><p>\n" +
              "For detailed description, check the Deployment Guide.\n" +
              "</p>"
          )
        },
        "repo_url"        => {
          "widget"  => :textentry,
          # textentry label
          "label"   => _("Repository &URL"),
          # FIXME
          # "validate_type" : `function,
          # "validate_function": ValidateURL,
          "no_help" => true,
          "init"    => fun_ref(method(:InitRepoURL), "void (string)"),
          "store"   => fun_ref(method(:StoreRepoURL), "symbol (string, map)"),
          "handle"  => fun_ref(method(:HandleRepoURL), "symbol (string, map)"),
          "opt"     => [:notify]
        },
        "ask_on_error"    => {
          "widget"  => :checkbox,
          # textentry label
          "label"   => _("&Ask On Error"),
          "no_help" => true,
          "init"    => fun_ref(method(:InitAskOnError), "void (string)"),
          "store"   => fun_ref(method(:StoreAskOnError), "symbol (string, map)"),
          "handle"  => fun_ref(
            method(:HandleAskOnError),
            "symbol (string, map)"
          ),
          "opt"     => [:notify]
        },
        # ---------------- widgets for Users tab
        "users_table"     => {
          "widget"        => :custom,
          "custom_widget" => VBox(
            VWeight(
              2,
              Table(
                Id("users_table"),
                Opt(:notify, :immediate, :hstretch),
                # table header
                Header(_("Administrator Name"))
              )
            )
          ),
          "init"          => fun_ref(method(:InitUsersTable), "void (string)"),
          "handle"        => fun_ref(
            method(:HandleUsersTable),
            "symbol (string, map)"
          ),
          # help text
          "help"          => _(
            "<p>Manage user names and passwords for Crowbar administrators.</p>"
          )
        },
        "add_user"        => {
          "widget"  => :push_button,
          "label"   => Label.AddButton,
          "no_help" => true,
          "handle"  => fun_ref(
            method(:HandleAddEditUserButton),
            "symbol (string, map)"
          )
        },
        "edit_user"       => {
          "widget"  => :push_button,
          "label"   => Label.EditButton,
          "no_help" => true,
          "handle"  => fun_ref(
            method(:HandleAddEditUserButton),
            "symbol (string, map)"
          )
        },
        "delete_user"     => {
          "widget"  => :push_button,
          "label"   => Label.DeleteButton,
          "no_help" => true,
          "handle"  => fun_ref(
            method(:HandleDeleteUserButton),
            "symbol (string, map)"
          )
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
          "help"   => Ops.get_string(
            @HELPS,
            "overview",
            ""
          )
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
          "valid_chars"       => Ops.add(IP.ValidChars4, IP.ValidChars6),
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
          "valid_chars"       => Ops.add(IP.ValidChars4, IP.ValidChars6),
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
          "valid_chars"       => Ops.add(IP.ValidChars4, IP.ValidChars6),
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
          "valid_chars" => Ops.add(IP.ValidChars4, IP.ValidChars6),
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
          "help"   => Ops.get_string(@HELPS, "bastion", ""),
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
          "valid_chars"       => Ops.add(IP.ValidChars4, IP.ValidChars6),
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
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "read", ""))
      return :abort if !Confirm.MustBeRoot
      ret = Crowbar.Read
      ret ? :next : :abort
    end

    # Write settings dialog
    # @return `abort if aborted and `next otherwise
    def WriteDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "write", ""))
      ret = Crowbar.Write
      ret ? :next : :abort
    end


    def InitAskOnError(id)
      UI.ChangeWidget(
        Id(id),
        :Value,
        Ops.get_boolean(@repos, [@current_repo, "ask_on_error"], false) == true
      )

      nil
    end

    def InitRepoURL(id)
      UI.ChangeWidget(
        Id(id),
        :Value,
        Ops.get_string(@repos, [@current_repo, "url"], "")
      )

      nil
    end

    # initialize the value of repo table
    def InitReposTable(id)
      UI.ChangeWidget(Id(id), :Items, Builtins.maplist(@repos) do |name, r|
        Item(
          Id(name),
          name,
          Ops.get_string(r, "url", ""),
          Ops.get_boolean(r, "ask_on_error", false) ? UI.Glyph(:CheckMark) : " "
        )
      end)
      if @current_repo != ""
        UI.ChangeWidget(Id(id), :CurrentItem, @current_repo)
      end

      nil
    end

    # handler for repo selection table
    def HandleReposTable(key, event)
      event = deep_copy(event)
      selected = Convert.to_string(UI.QueryWidget(Id(key), :Value))
      if selected != nil && selected != @current_repo
        @current_repo = selected
        InitRepoURL("repo_url")
        InitAskOnError("ask_on_error")
      end
      nil
    end

    def StoreRepoURL(key, event)
      event = deep_copy(event)
      Ops.set(@repos, [@current_repo, "url"], UI.QueryWidget(Id(key), :Value))
      nil
    end

    def HandleRepoURL(key, event)
      event = deep_copy(event)
      # store the value on exiting
      if Ops.get(event, "ID") == :next ||
          Ops.get_string(event, "EventReason", "") == "ValueChanged"
        StoreRepoURL(key, event)
        InitReposTable("repos_table")
      end
      nil
    end

    def StoreAskOnError(key, event)
      event = deep_copy(event)
      Ops.set(
        @repos,
        [@current_repo, "ask_on_error"],
        UI.QueryWidget(Id(key), :Value) == true
      )
      nil
    end

    def HandleAskOnError(key, event)
      event = deep_copy(event)
      # store the value on exiting
      if Ops.get(event, "ID") == :next ||
          Ops.get_string(event, "EventReason", "") == "ValueChanged"
        StoreAskOnError(key, event)
        InitReposTable("repos_table")
      end
      nil
    end



    # initialize the value of users table
    def InitUsersTable(id)
      UI.ChangeWidget(Id(id), :Items, Builtins.maplist(@users) do |name, u|
        Item(Id(name), name)
      end)
      if @current_user != "" && Builtins.haskey(@users, @current_user)
        UI.ChangeWidget(Id(id), :CurrentItem, @current_user)
      end

      nil
    end

    # handler for adding user button
    def HandleAddEditUserButton(key, event)
      event = deep_copy(event)
      _ID = Ops.get(event, "ID")
      return nil if _ID != key

      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          HSpacing(1),
          VBox(
            VSpacing(0.5),
            HSpacing(65),
            # text entry label
            InputField(Id(:username), Opt(:hstretch), _("User Name")),
            # text entry label
            Password(Id(:pw1), Opt(:hstretch), _("Password")),
            # text entry label
            Password(Id(:pw2), Opt(:hstretch), _("Repeat the Password")),
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

      if key == "edit_user"
        UI.ChangeWidget(Id(:username), :Value, @current_user)
        UI.ChangeWidget(
          Id(:pw1),
          :Value,
          Ops.get_string(@users, [@current_user, "password"], "")
        )
        UI.ChangeWidget(
          Id(:pw2),
          :Value,
          Ops.get_string(@users, [@current_user, "password"], "")
        )
      end

      ret = :not_next
      name = ""

      while true
        ret = Convert.to_symbol(UI.UserInput)
        break if ret == :cancel
        if ret == :ok
          name = Convert.to_string(UI.QueryWidget(Id(:username), :Value))
          pass = Convert.to_string(UI.QueryWidget(Id(:pw1), :Value))

          if pass != UI.QueryWidget(Id(:pw2), :Value)
            # error popup
            Popup.Error(_("The passwords do not match.\nTry again."))
            UI.SetFocus(Id(:pw1))
            next
          end
          if Builtins.haskey(@users, name) &&
              (key == "add_user" || name != @current_user)
            # error popup
            Popup.Error(
              Builtins.sformat(
                _("User '%1' already exists.\nChoose a different name."),
                name
              )
            )
            UI.SetFocus(Id(:username))
            next
          end
          @users = Builtins.remove(@users, @current_user) if key == "edit_user"
          Ops.set(@users, name, { "password" => pass })
          break
        end
      end
      UI.CloseDialog

      if ret == :ok
        @current_user = name
        InitUsersTable("users_table")
        UI.ChangeWidget(
          Id("delete_user"),
          :Enabled,
          Ops.greater_than(Builtins.size(@users), 0)
        )
        UI.ChangeWidget(
          Id("edit_user"),
          :Enabled,
          Ops.greater_than(Builtins.size(@users), 0)
        )
      end
      nil
    end

    # handler for user selection table
    def HandleUsersTable(key, event)
      event = deep_copy(event)
      selected = Convert.to_string(UI.QueryWidget(Id(key), :Value))
      if selected != nil && selected != @current_user
        @current_user = selected == nil ? "" : selected
      end
      if key == Ops.get(event, "ID") &&
          Ops.get_string(event, "EventReason", "") == "Activated"
        HandleAddEditUserButton("edit_user", { "ID" => "edit_user" })
      end
      nil
    end


    # handler for user button
    def HandleDeleteUserButton(key, event)
      event = deep_copy(event)
      _ID = Ops.get(event, "ID")
      return nil if _ID != key
      # yes/no popup question
      if true # Popup::YesNo (sformat (_("Really delete user '%1'?"), current_user)))
        @users = Builtins.remove(@users, @current_user)
        InitUsersTable("users_table")
        @current_user = Builtins.size(@users) == 0 ?
          "" :
          Convert.to_string(UI.QueryWidget(Id("users_table"), :Value))
        UI.ChangeWidget(
          Id(key),
          :Enabled,
          Ops.greater_than(Builtins.size(@users), 0)
        )
        UI.ChangeWidget(
          Id("edit_user"),
          :Enabled,
          Ops.greater_than(Builtins.size(@users), 0)
        )
      end
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
      event = deep_copy(event)
      @mode = Convert.to_string(UI.QueryWidget(Id(key), :Value))

      nil
    end

    def HandleMode(key, event)
      event = deep_copy(event)
      StoreMode(key, event)
      UI.ChangeWidget(Id("teaming"), :Enabled, @mode == "team")
      nil
    end

    def InitConduitList(id)
      UI.ChangeWidget(
        Id(id),
        :Value,
        Builtins.mergestring(@conduit_if_list, " ")
      )

      nil
    end

    def StoreConduitList(key, event)
      event = deep_copy(event)
      @conduit_if_list = Builtins.splitstring(
        Convert.to_string(UI.QueryWidget(Id(key), :Value)),
        " "
      )

      nil
    end

    # Validate logical network values for conduit list
    def ValidateConduitList(key, event)
      event = deep_copy(event)
      # [Quantifier][Speed][Order]
      # Quantifier is optional; for speed there are only 4 options; order starts with 1
      reg = "^[-+?]*(10m|100m|1g|10g)[1-9]+[0-9]*$"

      invalid_if = Builtins.find(
        Builtins.splitstring(
          Convert.to_string(UI.QueryWidget(Id(key), :Value)),
          " "
        )
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
      value = Ops.get(@teaming, "mode", 0)
      items = []
      i = 0
      while Ops.less_than(i, 7)
        items = Builtins.add(
          items,
          Item(Id(i), Builtins.tostring(i), i == value)
        )
        i = Ops.add(i, 1)
      end
      UI.ChangeWidget(Id(id), :Items, items)
      UI.ChangeWidget(Id(id), :Enabled, @mode == "team")
      UI.ChangeWidget(Id(id), :Enabled, !Crowbar.installed)

      nil
    end

    def StoreTeaming(key, event)
      event = deep_copy(event)
      Ops.set(
        @teaming,
        "mode",
        Convert.to_integer(UI.QueryWidget(Id(key), :Value))
      )

      nil
    end

    def HandleTeaming(key, event)
      event = deep_copy(event)
      StoreTeaming(key, event) if Ops.get(event, "ID") == :next
      nil
    end

    def GetRouter
      Convert.to_string(UI.QueryWidget(Id("router"), :Value))
    end

    # Returns current subnet as filled in dialog
    def GetSubnet
      Convert.to_string(UI.QueryWidget(Id("subnet"), :Value))
    end

    # Returns current netmask as filled in dialog
    def GetNetmask
      Convert.to_string(UI.QueryWidget(Id("netmask"), :Value))
    end

    # Returns broadcast address. Based on current netmask and subnet
    def GetBroadcast
      subnet = GetSubnet()
      netmask = GetNetmask()
      return "" if subnet == "" || netmask == ""
      IP.ComputeBroadcast(subnet, netmask)
    end

    def CreateItem(name)
      Item(
        Id(name),
        name,
        Ops.get_string(@networks, [name, "subnet"], ""),
        Ops.get_string(@networks, [name, "netmask"], ""),
        Ops.get_boolean(
          # table entry (VLAN status)
          @networks,
          [name, "use_vlan"],
          false
        ) ?
          Builtins.sformat("%1", Ops.get_integer(@networks, [name, "vlan"], 0)) :
          _("disabled")
      )
    end

    def CreateItemList
      items = []
      Builtins.foreach(@networks) do |name, n|
        items = Builtins.add(items, CreateItem(name)) if name != "bastion"
      end
      deep_copy(items)
    end
    # universal widget: initialize the string value of widget @param
    def InitNetwork(id)
      UI.ChangeWidget(Id(id), :Enabled, !Crowbar.installed)
      if id == "broadcast"
        UI.ChangeWidget(Id(id), :Value, GetBroadcast())
        return
      end

      UI.ChangeWidget(
        Id(id),
        :Value,
        Ops.get_string(@networks, [@current_network, id], "")
      )

      nil
    end

    # universal widget: initialize the integer value of widget @param
    def InitInteger(id)
      UI.ChangeWidget(
        Id(id),
        :Value,
        Ops.get_integer(@networks, [@current_network, id], 0)
      )
      if id == "vlan"
        UI.ChangeWidget(
          Id(id),
          :Enabled,
          Ops.get_boolean(@networks, [@current_network, "use_vlan"], false) == true
        )
      end
      if id == "router_pref"
        UI.ChangeWidget(
          Id(id),
          :Enabled,
          Ops.get_string(@networks, [@current_network, "router"], "") != ""
        )
      end
      UI.ChangeWidget(Id(id), :Enabled, !Crowbar.installed)

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
      event = deep_copy(event)
      if Builtins.size(@networks) == 0 || key == "mode" ||
          CWMTab.CurrentTab == "network_mode" && !@enable_bastion
        return
      end
      if (key == "router" || key == "router_pref") && GetRouter() == ""
        if Builtins.haskey(Ops.get(@networks, @current_network, {}), key)
          # do not save empty router values to json
          # do not save router_pref if router is not defined
          Ops.set(
            @networks,
            @current_network,
            Builtins.remove(Ops.get(@networks, @current_network, {}), key)
          )
        end
        return
      end
      if key == "subnet"
        Ops.set(
          @networks,
          [@current_network, key],
          IP.ComputeNetwork(GetSubnet(), GetNetmask())
        )
        return
      end
      Ops.set(
        @networks,
        [@current_network, key],
        UI.QueryWidget(Id(key), :Value)
      )

      nil
    end

    # Validate entered network values
    def ValidateNetwork(key, event)
      event = deep_copy(event)
      ret = true

      if Ops.get(event, "WidgetID") == :back || Builtins.size(@networks) == 0
        return true
      end
      return true if CWMTab.CurrentTab == "network_mode" && !@enable_bastion

      subnet = GetSubnet()
      netmask = GetNetmask()
      router = Convert.to_string(UI.QueryWidget(Id("router"), :Value))
      ip = ""
      if UI.WidgetExists(Id("ip"))
        ip = Convert.to_string(UI.QueryWidget(Id("ip"), :Value))
      end

      ret = key != "netmask" || Netmask.Check(netmask)
      if !ret
        # error popup
        Popup.Error(
          Builtins.sformat(
            _("The netmask '%1' is invalid.\n%2"),
            netmask,
            IP.Valid4
          )
        )
        return false
      end

      ret = key != "subnet" || IP.Check(subnet)
      if !ret
        # error popup
        Popup.Error(
          Builtins.sformat(
            _("The IP address '%1' is invalid.\n%2"),
            subnet,
            IP.Valid4
          )
        )
        return false
      end
      if key == "router" && router != ""
        if !IP.Check(router)
          # error popup
          Popup.Error(
            Builtins.sformat(
              _("The router address '%1' is invalid.\n%2"),
              router,
              IP.Valid4
            )
          )
          return false
        end
        if IP.ComputeNetwork(subnet, netmask) !=
            IP.ComputeNetwork(router, netmask)
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
        if !IP.Check(ip)
          # error popup
          Popup.Error(
            Builtins.sformat(
              _("The IP address '%1' is invalid.\n%2"),
              ip,
              IP.Valid4
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
        Builtins.foreach(
          Ops.get_map(@networks, [@current_network, "ranges"], {})
        ) { |name, range| Builtins.foreach(["start", "end"]) do |part|
          ip2 = Ops.get_string(range, part, "")
          ranges_fine = false if IP.ComputeNetwork(ip2, netmask) != subnet
        end }
        if !ranges_fine
          # popup message
          Popup.Warning(
            Builtins.sformat(
              _(
                "Some address ranges are not part of network '%1'.\nAdapt them using 'Edit ranges' button."
              ),
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
      event = deep_copy(event)
      if key == "use_vlan" && Ops.get(event, "ID") == "use_vlan"
        UI.ChangeWidget(
          Id("vlan"),
          :Enabled,
          UI.QueryWidget(Id(key), :Value) == true
        )
      end
      if key == "router_pref" && Ops.get(event, "ID") == "router"
        UI.ChangeWidget(Id("router_pref"), :Enabled, GetRouter() != "")
      end
      # store the value on exiting
      if Ops.get_string(event, "EventReason", "") == "ValueChanged"
        if IP.Check(GetSubnet()) && IP.Check(GetNetmask())
          UI.ChangeWidget(Id("broadcast"), :Value, GetBroadcast())
          StoreNetwork(Ops.get_string(event, "ID", ""), event)

          InitNetworkSelect("network_select")
        end
      end
      StoreNetwork(key, event) if Ops.get(event, "ID") == :next
      nil
    end


    # universal widget: initialize the string value of widget @param
    def InitCheckBox(id)
      UI.ChangeWidget(
        Id(id),
        :Value,
        Ops.get_boolean(@networks, [@current_network, id], false)
      )
      UI.ChangeWidget(Id(id), :Enabled, !Crowbar.installed)

      nil
    end

    # handler network selection table
    def HandleNetworkSelect(key, event)
      event = deep_copy(event)
      selected = Convert.to_string(UI.QueryWidget(Id(key), :Value))
      if selected != @current_network
        validated = true
        Builtins.foreach(["netmask", "subnet", "router"]) do |key2|
          validated = validated && ValidateNetwork(key2, event)
        end
        if !validated
          UI.ChangeWidget(Id(key), :CurrentItem, @current_network)
          return nil
        end
        Builtins.foreach(
          [
            "netmask",
            "subnet",
            "add_bridge",
            "use_vlan",
            "vlan",
            "broadcast",
            "router"
          ]
        ) { |key2| StoreNetwork(key2, {}) }
        @current_network = selected
        Builtins.foreach(["netmask", "subnet", "broadcast", "router"]) do |key2|
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
      event = deep_copy(event)
      _ID = Ops.get(event, "ID")
      return nil if _ID != key

      subnet = Ops.get_string(@networks, [@current_network, "subnet"], "")
      netmask = Ops.get_string(@networks, [@current_network, "netmask"], "")
      ranges = Ops.get_map(@networks, [@current_network, "ranges"], {})
      ranges_term = VBox()

      Builtins.foreach(ranges) do |name, range|
        r = Frame(
          name,
          HBox(
            InputField(
              Id(Ops.add(name, "_start")),
              Opt(:hstretch),
              # inputfield label
              _("Min IP Address"),
              Ops.get_string(range, "start", "")
            ),
            InputField(
              Id(Ops.add(name, "_end")),
              Opt(:hstretch),
              # inputfield label
              _("Max IP Address"),
              Ops.get_string(range, "end", "")
            )
          )
        )
        ranges_term = Builtins.add(ranges_term, r)
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

      Builtins.foreach(ranges) do |name, range|
        UI.ChangeWidget(
          Id(Ops.add(name, "_start")),
          :ValidChars,
          Ops.add(IP.ValidChars4, IP.ValidChars6)
        )
        UI.ChangeWidget(
          Id(Ops.add(name, "_end")),
          :ValidChars,
          Ops.add(IP.ValidChars4, IP.ValidChars6)
        )
        UI.ChangeWidget(
          Id(Ops.add(name, "_start")),
          :Enabled,
          !Crowbar.installed
        )
        UI.ChangeWidget(Id(Ops.add(name, "_end")), :Enabled, !Crowbar.installed)
      end

      UI.ChangeWidget(Id(:ok), :Enabled, !Crowbar.installed)

      ret = :not_next
      while true
        ret = Convert.to_symbol(UI.UserInput)
        break if ret == :cancel
        if ret == :ok
          widget = ""
          ranges_l = []
          Builtins.foreach(ranges) do |name, range|
            next if widget != ""
            Builtins.foreach(["start", "end"]) do |part|
              ip = Convert.to_string(
                UI.QueryWidget(Id(Ops.add(Ops.add(name, "_"), part)), :Value)
              )
              if !IP.Check(ip)
                Popup.Error(IP.Valid4)
                widget = Ops.add(Ops.add(name, "_"), part)
              elsif IP.ComputeNetwork(ip, netmask) != subnet
                Popup.Error(
                  Builtins.sformat(
                    _("The address '%1' is not part of network '%2'."),
                    ip,
                    @current_network
                  )
                )
                widget = Ops.add(Ops.add(name, "_"), part)
              end
              Ops.set(ranges, [name, part], ip)
            end
            if widget == "" &&
                Ops.greater_than(
                  IP.ToInteger(Ops.get_string(ranges, [name, "start"], "")),
                  IP.ToInteger(Ops.get_string(ranges, [name, "end"], ""))
                )
              # error message
              Popup.Error(
                _("The lowest address must be lower than the highest one.")
              )
              widget = Ops.add(name, "_end")
            else
              ranges_l = Builtins.add(
                ranges_l,
                [
                  IP.ToInteger(Ops.get_string(ranges, [name, "start"], "")),
                  IP.ToInteger(Ops.get_string(ranges, [name, "end"], "")),
                  name
                ]
              )
            end
          end
          # check if ranges do not overlap
          if widget == "" && Ops.greater_than(Builtins.size(ranges_l), 1)
            ranges_l = Builtins.sort(ranges_l) do |a, b|
              Ops.less_or_equal(
                Ops.get_integer(a, 0, 0),
                Ops.get_integer(b, 0, 0)
              )
            end
            i = 0
            while Ops.less_than(i, Ops.subtract(Builtins.size(ranges_l), 1))
              this = Ops.get(ranges_l, i, [])
              _next = Ops.get(ranges_l, Ops.add(i, 1), [])
              if Ops.greater_or_equal(
                  Ops.get_integer(this, 1, 0),
                  Ops.get_integer(_next, 0, 0)
                )
                # error message
                Popup.Error(
                  Builtins.sformat(
                    _("Ranges '%1' and '%2' are overlapping."),
                    Ops.get_string(this, 2, ""),
                    Ops.get_string(_next, 2, "")
                  )
                )
                widget = Ops.add(Ops.get_string(_next, 2, ""), "_start")
              end
              i = Ops.add(i, 1)
            end
          end
          # finally, save the ranges
          if widget == ""
            Ops.set(@networks, [@current_network, "ranges"], ranges)
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
      Builtins.foreach(
        [
          "ip",
          "router",
          "subnet",
          "netmask",
          "broadcast",
          "use_vlan",
          "conduit_if_list"
        ]
      ) { |w| UI.ChangeWidget(Id(w), :Enabled, @enable_bastion) }
      UI.ChangeWidget(
        Id("vlan"),
        :Enabled,
        @enable_bastion &&
          Ops.get_boolean(@networks, [@current_network, "use_vlan"], false) == true
      )
      UI.ChangeWidget(
        Id("router_pref"),
        :Enabled,
        @enable_bastion &&
          Ops.get_string(@networks, [@current_network, "router"], "") != ""
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
      event = deep_copy(event)
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
              VSpacing(),
              "users_table",
              VSpacing(0.4),
              HBox("add_user", "edit_user", "delete_user", HStretch()),
              VSpacing(2),
              # label (hint for user)
              Left(
                Label(
                  _(
                    "If no user is present, user 'crowbar' with default password will be used."
                  )
                )
              ),
              VStretch()
            ),
            HSpacing(2)
          ),
          "widget_names" => [
            "add_user",
            "delete_user",
            "edit_user",
            "users_table"
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
              VSpacing(),
              "network_select",
              Left("add_bridge"),
              VSpacing(0.4),
              HBox(
                VBox("use_vlan", Label("")),
                HWeight(1, "vlan"),
                HWeight(8, Empty())
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
              VSpacing(),
              "repos_table",
              VSpacing(0.4),
              Left("ask_on_error"),
              VSpacing(),
              "repo_url",
              # label (hint for user)
              Left(Label(_("Empty URL means that default value will be used."))),
              VStretch()
            ),
            HSpacing(2)
          ),
          "widget_names" => ["repos_table", "repo_url", "ask_on_error"]
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

      @conduit_map = Builtins.maplist(@conduit_map) do |c_map|
        # ignore not matching patterns
        if Builtins.substring(
            Ops.get_string(c_map, "pattern", ""),
            0,
            Builtins.size(@mode)
          ) != @mode
          next deep_copy(c_map)
        end
        if !name_found
          # if non-empty conduit was provided && it exist for the right pattern, use it
          if Builtins.haskey(Ops.get_map(c_map, "conduit_list", {}), conduit)
            name_found = true
          else
            if conduit == ""
              conduit = "bastion"
              conduit_name = "bastion"
            end
            i = 0
            while Builtins.haskey(
                Ops.get_map(c_map, "conduit_list", {}),
                conduit_name
              )
              conduit_name = Builtins.sformat("%1%2", conduit, i)
              i = Ops.add(i, 1)
            end
            name_found = true
          end
        end
        Ops.set(
          c_map,
          ["conduit_list", conduit_name],
          { "if_list" => @conduit_if_list }
        )
        deep_copy(c_map)
      end
      conduit_name
    end

    # Find if_list relevant for given bastion network
    def get_conduit_if_list(bastion)
      bastion = deep_copy(bastion)
      conduit_name = Ops.get_string(bastion, "conduit", "")
      Builtins.foreach(@conduit_map) do |c_map|
        if Builtins.substring(
            Ops.get_string(c_map, "pattern", ""),
            0,
            Builtins.size(@mode)
          ) == @mode
          if Builtins.haskey(
              Ops.get_map(c_map, "conduit_list", {}),
              conduit_name
            )
            @conduit_if_list = Ops.get_list(
              c_map,
              ["conduit_list", conduit_name, "if_list"],
              []
            )
          end
        end
      end

      deep_copy(@conduit_if_list)
    end

    def OverviewDialog
      @networks = deep_copy(Crowbar.networks)
      @mode = Crowbar.mode
      @teaming = deep_copy(Crowbar.teaming)
      @users = deep_copy(Crowbar.users)
      @repos = deep_copy(Crowbar.repos)
      @conduit_map = deep_copy(Crowbar.conduit_map)
      @enable_bastion = Builtins.haskey(@networks, "bastion")
      if !@enable_bastion
        Ops.set(@networks, "bastion", {})
      else
        Ops.set(
          @networks,
          ["bastion", "ip"],
          Ops.get_string(
            @networks,
            ["bastion", "ranges", "admin", "start"],
            "0"
          )
        )
        @conduit_if_list = get_conduit_if_list(
          Ops.get(@networks, "bastion", {})
        )
      end
      # find out initial router_pref value for bastion network and set it lower than in admin network
      @initial_router_pref = Ops.get_integer(
        @networks,
        ["admin", "router_pref"],
        @initial_router_pref
      )
      if Ops.greater_than(@initial_router_pref, 0)
        @initial_router_pref = Ops.subtract(@initial_router_pref, 1)
      end

      if !Builtins.haskey(Ops.get(@networks, "bastion", {}), "router_pref")
        Ops.set(@networks, ["bastion", "router_pref"], @initial_router_pref)
      end

      Ops.set(
        @widget_description,
        "tab",
        CWMTab.CreateWidget(
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
              "The SUSE Cloud Admin Server has been deployed. Changing the network is\n" +
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
      if Crowbar.installed
        # not saving
        return :back
      end
      if ret == :next
        if @enable_bastion
          # remove internal "ip" key and transform it to ranges (ip-ip)
          bastion = Ops.get(@networks, "bastion", {})
          Ops.set(bastion, "ranges", {}) if !Builtins.haskey(bastion, "ranges")
          Ops.set(
            bastion,
            ["ranges", "admin"],
            {
              "start" => Ops.get_string(bastion, "ip", "0"),
              "end"   => Ops.get_string(bastion, "ip", "0")
            }
          )
          bastion = Builtins.remove(bastion, "ip")
          # add conduit to bastion network submap
          Ops.set(
            bastion,
            "conduit",
            adapt_conduit_map(Ops.get_string(bastion, "conduit", ""))
          )
          Ops.set(bastion, "add_bridge", false)
          Ops.set(@networks, "bastion", bastion)
        elsif Builtins.haskey(@networks, "bastion")
          @networks = Builtins.remove(@networks, "bastion")
        end
        Crowbar.networks = deep_copy(@networks)
        Crowbar.conduit_map = deep_copy(@conduit_map) # was adapted by adapt_conduit_map
        Crowbar.users = deep_copy(@users)
        Crowbar.teaming = deep_copy(@teaming)
        Crowbar.mode = @mode
        Crowbar.repos = deep_copy(@repos)
      end
      ret
    end
  end
end
