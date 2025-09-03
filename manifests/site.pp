define puppetfile($mode = "0644", $owner = "root", $group = "root") {
  file {
    $title:
      source => "/var/lib/puppet/files/$title",
      mode => $mode,
      owner => $owner,
      group => $group;
  }
}

define gitrepo($url) {
  exec {
    "/usr/bin/git clone $url $title":
      creates => $title,
      require => Package["git"];
  }
}

class android_ndk_install($ndk_version) {
  exec {
    "download-android-ndk":
      command => "/usr/bin/wget https://dl.google.com/android/repository/android-ndk-$ndk_version-linux.zip",
      cwd => "/home/admin/droid",
      creates => "/home/admin/droid/android-ndk-$ndk_version-linux.zip";
    "extract-android-ndk":
      command => "/bin/unzip android-ndk-$ndk_version-linux.zip",
      cwd => "/home/admin/droid",
      creates => "/home/admin/droid/android-ndk-$ndk_version",
      require => Exec["download-android-ndk"];
  }
  file {
    "/home/admin/droid/android-ndk":
      ensure => "/home/admin/droid/android-ndk-$ndk_version",
      require => Exec["extract-android-ndk"];
  }
}

class android_ndk_symlinks($gcc_version) {
  file {
    "/home/admin/droid/android-ndk/default-arm-toolchain":
      ensure => "toolchains/arm-linux-androideabi-$gcc_version/prebuilt/linux-x86_64/",
      require => File["/home/admin/droid/android-ndk"];
    "/home/admin/droid/lib-arm/libgcc.a":
      ensure => "../android-ndk/default-arm-toolchain/lib/gcc/arm-linux-androideabi/$gcc_version/libgcc.a",
      require => File["/home/admin/droid/android-ndk/default-arm-toolchain"];
    "/home/admin/droid/lib-arm/libstdc++":
      ensure => "../android-ndk/sources/cxx-stl/gnu-libstdc++/$gcc_version/",
      require => File["/home/admin/droid/android-ndk/default-arm-toolchain"];

    "/home/admin/droid/android-ndk/default-x86-toolchain":
      ensure => "toolchains/x86-$gcc_version/prebuilt/linux-x86_64/",
      require => File["/home/admin/droid/android-ndk"];
    "/home/admin/droid/lib-x86/libgcc.a":
      ensure => "../android-ndk/default-x86-toolchain/lib/gcc/i686-linux-android/$gcc_version/libgcc.a",
      require => File["/home/admin/droid/android-ndk/default-x86-toolchain"];
    "/home/admin/droid/lib-x86/libstdc++":
      ensure => "../android-ndk/sources/cxx-stl/gnu-libstdc++/$gcc_version/",
      require => File["/home/admin/droid/android-ndk/default-x86-toolchain"];


    "/home/admin/droid/android-ndk/default-mips-toolchain":
      ensure => "toolchains/mipsel-linux-android-$gcc_version/prebuilt/linux-x86_64/",
      require => File["/home/admin/droid/android-ndk"];
    "/home/admin/droid/lib-mips/libgcc.a":
      ensure => "../android-ndk/default-mips-toolchain/lib/gcc/mipsel-linux-android/$gcc_version/libgcc.a",
      require => File["/home/admin/droid/android-ndk/default-mips-toolchain"];
    "/home/admin/droid/lib-mips/libstdc++":
      ensure => "../android-ndk/sources/cxx-stl/gnu-libstdc++/$gcc_version/",
      require => File["/home/admin/droid/android-ndk/default-mips-toolchain"];
  }
}

class android_ndk {
  # settings - NDK version and gcc version
  $ndk_version = "r27d"
  $gcc_version = "4.6"

  class {
    "android_ndk_install": 
      ndk_version => $ndk_version,
      require => Class["admin_user"];
    "android_ndk_symlinks": 
      gcc_version => $gcc_version,
      require => Class["android_ndk_install"];
  }

}

class admin_user {
  user {
    "admin": ensure => present;
  }
  file {
    "/home/admin": ensure => directory, require => User["admin"], owner => "admin";
    "/home/admin/droid": ensure => directory, require => File["/home/admin"];
    "/home/admin/droid/lib-arm": ensure => directory, require => File["/home/admin/droid"];
    "/home/admin/droid/lib-x86": ensure => directory, require => File["/home/admin/droid"];
    "/home/admin/droid/lib-mips": ensure => directory, require => File["/home/admin/droid"];
    "/home/admin/tmp": ensure => directory, require => File["/home/admin"];
  }
  puppetfile {
    "/home/admin/shell":
      mode => 0755;
  }
}

node default {
  package {
    "vim-enhanced": ensure => present;
    "vim-minimal": ensure => present;
    "gcc": ensure => present;
    "patch": ensure => present;
    "lftp": ensure => present;
    "git": ensure => present;
    "git-svn": ensure => present;
    "man": ensure => present;
    "autoconf": ensure => present;
    "automake": ensure => present;
    "mercurial": ensure => present;
    "file": ensure => present;
  }

  include admin_user
  include android_ndk

  gitrepo {
    "/home/admin/droid/bin":
      url => "https://github.com/ddrown/android-ports-tools.git",
      require => Class["admin_user"];
    "/home/admin/droid/include":
      url => "https://github.com/ddrown/android-include.git",
      require => Class["admin_user"];
  }
}
