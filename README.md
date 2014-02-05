Puppet-DTrace4Linux
===================

This puppet module will install DTrace on a Linux system.

Installation
------------

In the **modules** directory of your Puppet project, type `git clone https://github.com/Elzair/dtrace4linux.git`.

Use
---

You can instantiate the class **dtrace4linux** in the following way:

    class { "dtrace4linux":
      user        => "example",
      group       => "example",
      dev_dir     => "/home/example",
      distro      => "ubuntu",      # It also supports fedora, redhat, debian, and arch
      module_file => "/etc/modules" # file telling kernel what modules to load at boot
    }
