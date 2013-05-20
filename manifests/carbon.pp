## reasonable settings for a reasonable OS.  Debian users: you're on your own.
class graphite::carbon(
    $cache_port       = 2003,
    $cache_enable_udp = false,
    $cache_udp_port   = $cache_port,
    
    $package             = 'carbon',
    $conf_dir            = '/etc/carbon',
    $storage_dir         = '/var/lib/carbon/',
    $log_dir             = '/var/log/carbon/',
    $provide_init_script = false,
) {
    require graphite

    $whisper_data_dir = $graphite::whisper_data_dir

    package {$package : }
    
    File {
        owner => 'carbon',
        group => 'carbon',
    }
    
    if $provide_init_script {
        # file {'/etc/init.d/carbon-cache':
        #     source  => 'puppet:///modules/graphite/ubuntu-init-script',
        #     mode    => '0755',
        #     require => Package[$package],
        #     before  => Service['carbon-cache'],
        # }
        file {'/etc/init/carbon-cache.conf':
            content => template('graphite/upstart-carbon.conf.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            require => Package[$package],
            before  => Service['carbon-cache'],
            notify  => Service['carbon-cache'],
        }
    }
    
    user {'carbon':
        ensure => present,
        system => true,
    }
    
    file {[
        $conf_dir,
        $storage_dir,
        $log_dir,
        $whisper_data_dir,
    ]:
        ensure  => directory,
        recurse => true,
    }

    file {"${conf_dir}/carbon.conf":
        content => template('graphite/carbon.conf.erb'),
        require => Package[$package],
        notify  => Service['carbon-cache'],
    }

    file {"${conf_dir}/storage-schemas.conf":
        source  => 'puppet:///modules/graphite/storage-schemas.conf',
        require => Package[$package],
        notify  => Service['carbon-cache'],
    }
    
    service {'carbon-cache':
        ensure  => running,
        enable  => true,

        require => [
            Package[$package],
            User['carbon'],
        ],
    }
}