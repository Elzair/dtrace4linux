class dtrace4linux (
  $user = $dtrace4linux::params::user,
  $group = $dtrace4linux::params::group,
  $dev_dir = $dtrace4linux::params::dev_dir,
  $distro = $dtrace4linux::params::distro,
  $module_file = $dtrace4linux::params::module_file
) inherits dtrace4linux::params 
{
  $path = [
    "/opt/local/bin",
    "/usr/local/sbin",
    "/usr/local/bin",
    "/usr/sbin",
    "/usr/bin",
    "/sbin",
    "/bin",
  ]

  file { "dev_dir":
    ensure => directory,
    path   => $dev_dir,
    owner  => $user,
    group  => $group,
    mode   => "0755",
  }

  exec { "clone-dtrace4linux":
    command   => "git clone https://github.com/dtrace4linux/linux.git $dev_dir/dtrace",
    path      => $path,
    logoutput => true,
    require   => [ Class["config_build"], File["dev_dir"] ],
  }

  $getdeps = $distro ? {
    /(?i-mx:ubuntu|debian|mint)/   => "get-deps.pl",
    /(?i-mx:centos|redhat|fedora)/ => "get-deps-fedora.sh",
    arch                           => "get-deps-arch.pl",
    default                        => undef,
  }

  if ($getdeps) {
    exec { "make get-deps.pl executable":
      command => "chmod 0755 $dev_dir/dtrace/tools/$getdeps",
      path    => $path,
      logoutput => true,
      require => Exec["clone-dtrace4linux"],
    }

    exec { "get-dtrace-deps":
      command => "yes Y | $dev_dir/dtrace/tools/$getdeps",
      path    => $path,
      logoutput => true,
      require => Exec["make get-deps.pl executable"],
    }

    exec { "install-dtrace4linux":
      command => "/bin/sh -c 'cd $dev_dir/dtrace && make all && make install && make load'",
      path    => $path,
      logoutput => true,
      require => [ Class["config_build"], Exec["get-dtrace-deps"] ],
    }

    exec { "place dtrace in module dir":
      command => "cp $dev_dir/dtrace/build-$(uname -r)/driver/dtracedrv.ko /lib/modules/$(uname -r)/kernel/drivers/",
      path      => $path,
      logoutput => true,
      require   => Exec["install-dtrace4linux"],
    }

    exec { "load dtrace module at boot":
      command   => "/bin/sh -c 'echo dtrace4linux >> $module_file'",
      path      => $path,
      logoutput => true,
      require   => Exec["place dtrace in module dir"],
    }
  }
  else {
    notify { "Unable to install dtrace4linux dependencies!": }
  }
}
