#
# spec file for package yast2-crowbar
#
# Copyright (c) 2016 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-crowbar
Version:        3.4.1
Release:        0
Summary:        Configuration of crowbar
License:        GPL-2.0
Group:          System/YaST
Source0:        %{name}-%{version}.tar.bz2
BuildRequires:  update-desktop-files
BuildRequires:  yast2
BuildRequires:  yast2-devtools >= 3.1.10
BuildRequires:  yast2-testsuite
Requires:       rubygem(inifile) >= 3.0.0
Requires:       yast2
Requires:       yast2-ruby-bindings >= 1.0.0
BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-build

%description
-

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install


%files
%defattr(-,root,root)
%doc COPYING
%dir %{yast_yncludedir}/crowbar
%{yast_yncludedir}/crowbar/*
%{yast_clientdir}/crowbar.rb
%{yast_clientdir}/inst_crowbar.rb
%{yast_clientdir}/inst_crowbar_patterns.rb
%{yast_moduledir}/Crowbar.rb
%{yast_desktopdir}/crowbar.desktop
%doc %{yast_docdir}

%changelog
