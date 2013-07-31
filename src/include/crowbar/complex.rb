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

      # local copy of mode
      @mode = "single"

      @current_network = "admin"

      @widget_description = {
        "password"        => {
          "widget"            => :password,
          "opt"               => [:hstretch],
          # textentry label
          "label"             => _(
            "Password for Crowbar Administrator"
          ),
          # help text
          "help"              => _(
            "<p>Enter the password for Crowbar administrator.</p>"
          ),
          "init"              => fun_ref(method(:InitPassword), "void (string)"),
          "store"             => fun_ref(
            method(:StorePassword),
            "void (string, map)"
          ),
          "handle"            => fun_ref(
            method(:HandlePassword),
            "symbol (string, map)"
          ),
          "validate_type"     => :function,
          "validate_function" => fun_ref(
            method(:ValidatePassword),
            "boolean (string, map)"
          )
        },
        "repeat_password" => {
          "widget" => :password,
          "opt"    => [:hstretch],
          # textentry label
          "label"  => _("Repeat the Password"),
          "init"   => fun_ref(method(:InitPassword), "void (string)")
        },
        "mode"            => {
          "widget"  => :combobox,
          "opt"     => [:hstretch, :notify],
          # textentry label
          "label"   => _("Mode"),
          "no_help" => true,
          "init"    => fun_ref(method(:InitMode), "void (string)"),
          "store"   => fun_ref(method(:StoreMode), "void (string, map)"),
          "handle"  => fun_ref(method(:HandleMode), "symbol (string, map)")
        },
        "teaming"         => {
          "widget"  => :combobox,
          # textentry label
          "label"   => _("Bonding Policy"),
          "no_help" => true,
          "init"    => fun_ref(method(:InitTeaming), "void (string)"),
          "store"   => fun_ref(method(:StoreTeaming), "void (string, map)"),
          "handle"  => fun_ref(method(:HandleTeaming), "symbol (string, map)")
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
          )
        },
        "use_vlan"        => {
          "widget"  => :checkbox,
          # checkbox label
          "label"   => _("Use VLAN"),
          "no_help" => true,
          "init"    => fun_ref(method(:InitCheckBox), "void (string)"),
          "store"   => fun_ref(method(:StoreNetwork), "void (string, map)"),
          "handle"  => fun_ref(method(:HandleNetwork), "symbol (string, map)"),
          "opt"     => [:notify]
        },
        "vlan"            => {
          "widget"  => :intfield,
          # textentry label
          "label"   => _("VLAN ID"),
          "no_help" => true,
          "init"    => fun_ref(method(:InitInteger), "void (string)"),
          "store"   => fun_ref(method(:StoreNetwork), "void (string, map)"),
          "handle"  => fun_ref(method(:HandleNetwork), "symbol (string, map)"),
          "opt"     => [:notify, :hstretch]
        },
        "router"          => {
          "widget"            => :textentry,
          # textentry label
          "label"             => _("Router"),
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
        "subnet"          => {
          "widget"            => :textentry,
          # textentry label
          "label"             => _("Subnet"),
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
          "label"             => _("Netmask"),
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
          "label"       => _("Broadcast"),
          "valid_chars" => Ops.add(IP.ValidChars4, IP.ValidChars6),
          "no_help"     => true,
          "init"        => fun_ref(method(:InitNetwork), "void (string)"),
          "store"       => fun_ref(method(:StoreNetwork), "void (string, map)"),
          "opt"         => [:disabled]
        },
        "add_bridge"      => {
          "widget"  => :checkbox,
          # checkbox label
          "label"   => _("Add Bridge"),
          "no_help" => true,
          "init"    => fun_ref(method(:InitCheckBox), "void (string)"),
          "store"   => fun_ref(method(:StoreNetwork), "void (string, map)"),
          "handle"  => fun_ref(method(:HandleNetwork), "symbol (string, map)")
        },
        "ranges_button"   => {
          "widget"  => :push_button,
          # push button label
          "label"   => _("&Edit Ranges..."),
          "no_help" => true,
          "handle"  => fun_ref(
            method(:HandleRangesButton),
            "symbol (string, map)"
          )
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

    # functions for handling password widget
    def InitPassword(id)
      UI.ChangeWidget(
        Id(id),
        :Value,
        Ops.get_string(@users, ["crowbar", "password"], "")
      )
      UI.ChangeWidget(Id(id), :Enabled, !Crowbar.installed)

      nil
    end

    def StorePassword(key, event)
      event = deep_copy(event)
      Ops.set(@users, ["crowbar", "password"], UI.QueryWidget(Id(key), :Value))

      nil
    end

    def HandlePassword(key, event)
      event = deep_copy(event)
      StorePassword(key, event) if Ops.get(event, "ID") == :next
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


    # Validation function for widgets with time values
    def ValidatePassword(key, event)
      event = deep_copy(event)
      if UI.QueryWidget(Id("password"), :Value) !=
          UI.QueryWidget(Id("repeat_password"), :Value)
        # error popup
        Popup.Error(_("The passwords do not match.\nTry again."))
        UI.SetFocus(Id(key))
        return false
      end
      true
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
      IP.ComputeBroadcast(GetSubnet(), GetNetmask())
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
      Builtins.maplist(@networks) { |name, n| CreateItem(name) }
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
      UI.ChangeWidget(Id(id), :Enabled, !Crowbar.installed)

      nil
    end

    # initialize the value of table
    def InitNetworkSelect(id)
      UI.ChangeWidget(Id(id), :Items, CreateItemList())
      UI.ChangeWidget(Id(id), :CurrentItem, @current_network)

      nil
    end

    # store the string value of given widget
    def StoreNetwork(key, event)
      event = deep_copy(event)
      return if Builtins.size(@networks) == 0
      if key == "router" && UI.QueryWidget(Id(key), :Value) == ""
        if Builtins.haskey(Ops.get(@networks, @current_network, {}), key)
          # do not save empty router values to json
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

      if Ops.get_symbol(event, "WidgetID", :none) == :back ||
          Builtins.size(@networks) == 0
        return true
      end
      subnet = GetSubnet()
      netmask = GetNetmask()
      router = Convert.to_string(UI.QueryWidget(Id("router"), :Value))

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
      # check if ranges are still in network
      if key == "subnet"
        ranges_fine = true
        Builtins.foreach(
          Ops.get_map(@networks, [@current_network, "ranges"], {})
        ) { |name, range| Builtins.foreach(["start", "end"]) do |part|
          ip = Ops.get_string(range, part, "")
          ranges_fine = false if IP.ComputeNetwork(ip, netmask) != subnet
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

    # description of tab layouts
    def get_tabs_descr
      {
        "admin"        => {
          # tab header
          "header"       => _("Administration Settings"),
          "contents"     => HBox(
            HSpacing(2),
            VBox(VSpacing(), "password", "repeat_password", VStretch()),
            HSpacing(2)
          ),
          "widget_names" => ["password", "repeat_password"]
        },
        "network_mode" => {
          # tab header
          "header"       => _("Network Mode"),
          "contents"     => HBox(
            HSpacing(2),
            VBox(VSpacing(), HBox("mode", "teaming"), VStretch()),
            HSpacing(2)
          ),
          "widget_names" => ["mode", "teaming"]
        },
        "networks"     => {
          # tab header
          "header"       => _("Networks"),
          "contents"     => HBox(
            HSpacing(2),
            VBox(
              "network_help",
              VSpacing(),
              "network_select",
              Left("add_bridge"),
              VSpacing(0.4),
              HBox(VBox("use_vlan", Label("")), HSpacing(2), "vlan"),
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
        }
      }
    end

    def OverviewDialog
      @networks = deep_copy(Crowbar.networks)
      @mode = Crowbar.mode
      @teaming = deep_copy(Crowbar.teaming)
      @users = deep_copy(Crowbar.users)

      Ops.set(
        @widget_description,
        "tab",
        CWMTab.CreateWidget(
          {
            "tab_order"    => ["admin", "networks", "network_mode"],
            "tabs"         => get_tabs_descr,
            "widget_descr" => @widget_description,
            "initial_tab"  => "admin"
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
        Crowbar.networks = deep_copy(@networks)
        Crowbar.users = deep_copy(@users)
        Crowbar.teaming = deep_copy(@teaming)
        Crowbar.mode = @mode
      end
      ret
    end
  end
end
