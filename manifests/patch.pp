define patch($cwd = '.', $patch, $fuzz = 2) {

  package { "patch":
    ensure => installed,
  }

  $patch_file = "/tmp/patch_${name}.patch"
  file { $patch_file:
    content => $patch,
  } ->
  exec { "patch_${name}":
    path => "/bin:/usr/bin",
    command => "patch -F ${fuzz} -b -p0 < ${patch_file} && touch ${patch_file}.applied",
    cwd => $cwd,
    logoutput => true,
    creates => "${patch_file}.applied",
  }
}
