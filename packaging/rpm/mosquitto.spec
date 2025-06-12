%define major     2
%define minor     1
%define libname   %mklibname %{name} %{major}
%define libnamepp %mklibname %{name}pp %{major}
%define develname %mklibname %{name} -d

Name:           mosquitto
Version:        2.0.20
Release:        1
Summary:        An Open Source MQTT v3.1/v3.1.1 Broker
Group:          System/Libraries
License:        BSD
URL:            http://mosquitto.org/
Source0:        http://mosquitto.org/files/source/%{name}-%{version}.tar.gz
Source1:        %{name}-sysusers.conf
BuildRequires:  cmake
BuildRequires:  tcp_wrappers-devel
BuildRequires:  uthash-devel >= 2.1.0
BuildRequires:  cmake(cJSON)
BuildRequires:  pkgconfig(libcares)
BuildRequires:  pkgconfig(libwebsockets)
BuildRequires:  pkgconfig(openssl)
BuildRequires:  pkgconfig(systemd)
BuildRequires:  pkgconfig(uuid)
BuildRequires:  xsltproc
Requires:		%{libname} = %{version}-%{release}
Requires(pre):  shadow-utils
Requires(post): systemd
Requires(preun): systemd
Requires(postun): systemd

%description
Mosquitto is an open source message broker that implements the MQ Telemetry
Transport protocol version 3.1 and 3.1.1 MQTT provides a lightweight method
of carrying out messaging using a publish/subscribe model. This makes it
suitable for "machine to machine" messaging such as with low power sensors
or mobile devices such as phones, embedded computers or micro-controllers
like the Arduino.

%files
%doc ChangeLog.txt CONTRIBUTING.md README*
%license LICENSE.txt
%{_bindir}/%{name}*
%{_sbindir}/%{name}
%dir %{_sysconfdir}/%{name}
%config(noreplace) %{_sysconfdir}/%{name}/%{name}.conf
%config %{_sysconfdir}/%{name}/*.example
%{_sysusersdir}/%{name}.conf
%{_unitdir}/%{name}.service
%{_mandir}/man1/*.1.*
%{_mandir}/man5/*.5.*
%{_mandir}/man7/*.7.*
%{_mandir}/man8/*.8.*

%pre
%sysusers_create_package %{name} %{S:1}

%post
%systemd_post %{name}

%preun
%systemd_preun %{name}

%postun
%systemd_postun %{name}

#------------------------------------------------

%package -n     %{libname}
Summary:        An Open Source MQTT v3.1/v3.1.1 Broker
Group:          System/Libraries

%description -n %{libname}
Mosquitto is an open source message broker that implements the MQ Telemetry
Transport protocol version 3.1 and 3.1.1 MQTT provides a lightweight method
of carrying out messaging using a publish/subscribe model. This makes it
suitable for "machine to machine" messaging such as with low power sensors
or mobile devices such as phones, embedded computers or micro-controllers
like the Arduino.

%files -n %{libname}
%{_libdir}/lib%{name}.so.%{major}*
%{_libdir}/lib%{name}.so.%{minor}*

#------------------------------------------------

%package -n     %{libnamepp}
Summary:        An Open Source MQTT v3.1/v3.1.1 Broker
Group:          System/Libraries
Requires:		%{libname} = %{version}-%{release}

%description -n %{libnamepp}
Mosquitto is an open source message broker that implements the MQ Telemetry
Transport protocol version 3.1 and 3.1.1 MQTT provides a lightweight method
of carrying out messaging using a publish/subscribe model. This makes it
suitable for "machine to machine" messaging such as with low power sensors
or mobile devices such as phones, embedded computers or micro-controllers
like the Arduino.

%files -n %{libnamepp}
%{_libdir}/lib%{name}pp.so.%{major}*
%{_libdir}/lib%{name}pp.so.%{minor}*

#------------------------------------------------

%package -n     %{develname}
Summary:        Development package for %{name}
Group:          Development/C++
Requires:       %{libname} = %{version}-%{release}
Requires:       %{libnamepp} = %{version}-%{release}
Provides:       %{name}-devel = %{version}-%{release}

%description -n %{develname}
Header files for development with %{name}.

%files -n %{develname}
%{_includedir}/*.h
%{_libdir}/*.so
%{_libdir}/pkgconfig/*.pc
%{_mandir}/man3/*.3.*

#------------------------------------------------

%prep
%setup -q

# Don't strip binaries on install: rpmbuild will take care of it
sed -i "s|(INSTALL) -s|(INSTALL)|g" lib/Makefile src/Makefile client/Makefile

# fix link with libwebsockets
sed -i "s|websockets_shared|websockets|g" src/CMakeLists.txt

%build
%cmake \
     -DCMAKE_INSTALL_SYSCONFDIR=%{_sysconfdir} \
     -DWITH_BUNDLED_DEPS=OFF \
     -DWITH_SYSTEMD=ON \
     -DWITH_WEBSOCKETS=ON
%make

%install
%makeinstall_std -C build

mkdir -p %{buildroot}%{_unitdir}
install -p -m 0644 service/systemd/%{name}.service.notify %{buildroot}%{_unitdir}/%{name}.service

install -D %{S:1} %{buildroot}%{_sysusersdir}/%{name}.conf

%check
#make test

