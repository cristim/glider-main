class utcluj_grid_common{
    import "glider-common"
    include glider_common
    import "glider-glite"
    package{["screen", "mc"]: ensure => installed}
    repos{["lcg-CA", "rpmforge", "scl", "gridmosi", "HellasGrid"]:}
    package{["lcg-CA", "seegrid", "GridAUTH-vomscert", "IRB-vomscert", "GridMOSI-vomscert", "ca_GridMOSI"]:
        ensure => latest,
        require => [Repos["rpmforge", "scl", "gridmosi", "HellasGrid", "lcg-CA"], Yumrepo["epel"]],
    }
    
    yumrepo{"epel":
        enabled => "0",
    }
    
    config_site{"RO-09-UTCN":
        site_name => "RO-09-UTCN",
        site_email => "admin@grid.utcluj.ro",
        site_domain => "mosigrid.utcluj.ro",
        vos=> ["seegrid", "ops", "gridmosi.ici.ro", "ops.vo.egee-see.org", "env.see-grid-sci.eu", "dteam", "see"],
        apel_passwd => "hackme",
        mysql_passwd => "hackme",
        lfc_passwd => "hackme",
        dpm_passwd => "hackme",
        cream_passwd => "hackme",
        dpm_info_passwd => "hackme",
        wn_count => "2",
    }
}

node "glider.utcluj.ro"{
import "glider-netinstall"

# extra packages you may want
package{["vim-enhanced", "bash-completion", "ruby-rdoc"]:
	ensure => installed
}

glider_netinstall{netinstaller:
	ip => "192.168.56.102",
	subnet => "192.168.56.0",
	netmask => "255.255.255.0",	
	gw => "192.168.56.102",
	dns => "193.226.5.151",
	static_nodes_file => "/etc/puppet/manifests/nodes.list", 
	os_mirror_base_url => "rsync://ftp.roedu.net/mirrors/centos.org",
	root_password_hash =>'$1$7xtoAlN.$6ijtkhzu4JbGRBPIiB7zc0'
	}
}

node /^ce\d+/ {
    include utcluj_grid_common
    glite_node{"ce":
        node_type => ["creamCE", "BDII_site", "TORQUE_utils", "TORQUE_server", "MPI_CE"],
        yum_repos => ["glite-CREAM", "glite-BDII", "glite-TORQUE_utils", 
                     "glite-TORQUE_server", "glite-MPI_utils"],
        inst_cert => "true"
    }
    package{["openmpi-libs", "mpich", "glite-yaim-mpi", "mpiexec", 
            "openmpi", "glite-MPI_utils", "glite-TORQUE_server", 
            "glite-TORQUE_utils", "glite-CREAM", "glite-BDII"]:
        require => [Repos["glite-CREAM", "glite-TORQUE_server", 
           "glite-TORQUE_utils", "glite-MPI_utils", "glite-BDII"], Yumrepo["epel"]],
        ensure => installed,
    }
}

node /^se\d+/ {
    include utcluj_grid_common
    glite_node{se:
        node_type => ["SE_dpm_mysql"],
        yum_repos => ["glite-SE_dpm_mysql"],
        inst_cert => "true",
    }
    package{"glite-SE_dpm_mysql":
        require => [Repos["glite-SE_dpm_mysql"], Yumrepo["epel"]],

        ensure => installed,
    }
}

node /^lfc\d+/ {
    include utcluj_grid_common
    glite_node{lfc:
        node_type => "LFC_mysql",
        yum_repos => ["glite-LFC_mysql"],
        inst_cert => "true",
    }
    package{"glite-MON":
        require => [Repos["glite-MON"], Yumrepo["epel"]],
        ensure => installed,
    }
}


node /^mon\d+/ {
    include utcluj_grid_common
    glite_node{mon:
        node_type => ["MON"],
        yum_repos => ["glite-MON"],
        inst_cert => "true",
    }
    package{"glite-MON":
        require => [Repos["glite-MON"], Yumrepo["epel"]],

        ensure => installed,
    }
}

node /^ui\d+/ {
    include utcluj_grid_common
    glite_node{ui:
        node_type => "UI",
        yum_repos => ["glite-UI"]
    }
    package{"glite-UI":
        require => [Repos["glite-UI"], Yumrepo["epel"]],

        ensure => installed,
    }
}

node /^wn\d+/ {
    include utcluj_grid_common
    glite_node{wn:
        node_type => ["WN","TORQUE_client", "MPI_WN"],
        yum_repos => ["glite-WN", "glite-TORQUE_client", "glite-MPI_utils"],
        install_yum_groups => ["glite-WN"], 
    }
    package{["openmpi-libs", "mpich", "glite-yaim-mpi", "mpiexec", "openmpi", 
            "glite-MPI_utils", "glite-TORQUE_client"]:
        require => [Repos["glite-WN", "glite-TORQUE_client", "glite-MPI_utils"], 
		Yumrepo["epel"], Install_yum_groups["glite-WN"]],    # gLite groups must be installed before
                                                # gLite packages, otherwise conflicts may occur
        ensure => installed,
    }
}

node default{}

