class dtrace4linux inherit dtrace4linux::params (
  $dev_dir = $dtrace4linux::params::dev_dir,
  $user = $dtrace4linux::params::user,
  $group = $dtrace4linux::params::group,
  $distro = $dtrace4linux::params::distro,
)
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

  package { "build-essential":
    ensure => present,
  }

  package { "git":
    ensure  => present,
    require => Package["build-essential"],
  }

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
    require   => [ Package["git"], File["$dev_dir"] ],
  }

  $getdeps = $distro ? {
    /(?i)(ubuntu|debian|mint)   => "get-deps.pl",
    /(?i)(centos|redhat|fedora) => "get-deps-fedora.sh",
    arch                        => "get-deps-arch.pl",
    default                     => undef,
  }

  if ($getdeps) {
    exec { "make get-deps.pl executable":
      command => "chmod 0755 $dev_dir/dtrace/tools/$getdeps",
      path    => $path,
      logoutput => true,
      require => Exec["chown devel"],
    }

    exec { "get-dtrace-deps":
      command => "yes Y | $dev_dir/dtrace/tools/$getdeps.pl",
      path    => $path,
      logoutput => true,
      require => Exec["make get-deps.pl executable"],
    }

    exec { "install-dtrace4linux":
      command => "/bin/sh -c 'cd $dev_dir/dtrace && make all && make install && make load'",
      path    => $path,
      logoutput => true,
      require => [ Package["build-essential"], Exec["get-dtrace-deps"] ],
    }
  }
  else {
    notify { "Unable to install dtrace4linux dependencies!": }
  }
}
