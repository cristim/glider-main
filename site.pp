#main config file

# all our servers are running in OpenVZ virtual machines, so only the WNs are physical
# if your machines are physical you can move all the hardware-related stuff we perform 
# for the WNs (cpuspeed, ntp, etc) to this common section

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
    
    yumrepo{"epel":  # this is good to have for various packages, but must be disabled or it will break gLite
        enabled => "0",
    }

    etc_hosts{"my_host":}		

    config_site{"RO-09-UTCN":				# change here
        site_name => "RO-09-UTCN",
        site_email => "admin@example.com",
        site_domain => "mosigrid.utcluj.ro",
        vos=> ["seegrid", "ops", "gridmosi.ici.ro", "ops.vo.egee-see.org", "env.see-grid-sci.eu", "dteam", "see"],
        apel_passwd => "hackme",
        mysql_passwd => "hackme",
        lfc_passwd => "hackme",
        dpm_passwd => "hackme",
        cream_passwd => "hackme",
        dpm_info_passwd => "hackme",
        wn_count => "1",
    }
}

node "mgmt"{
import "glider-netinstall"

# extra packages you may want
package{["vim-enhanced", "bash-completion", "ruby-rdoc", "htop"]:
	ensure => installed
}

glider_netinstall{"netinstaller":
	ip => "192.168.1.105",
	subnet => "192.168.1.0",
	netmask => "255.255.255.0",	
	gw => "192.168.1.105",
	dns => "192.168.1.106",
	static_nodes_file => "/etc/puppet/manifests/nodes.list", 
	os_mirror_base_url => "rsync://ftp.roedu.net/mirrors/centos.org",
	root_password_hash =>'hackme',
	}
}

node "ce01" {
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
			"glite-TORQUE_utils", "glite-MPI_utils", "glite-BDII"], Yumrepo["epel"]], # the Yumrepo["epel"] needs to be used to disable EPEL before installing gLite stuff
		ensure => installed,
    	}
	nfs_server{"nfs_home":
		shares	=> "/home",
		hosts	=> "192.168.1.0/255.255.255.0",
	}
}

node "se01" {
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
    nfs_server{"exp_soft":
	shares	=> "/opt/exp_soft",
	hosts	=> "192.168.1.0/255.255.255.0"
	}
}

node "lfc01" {
    include utcluj_grid_common
    glite_node{"lfc":
        node_type => "LFC_mysql",
        yum_repos => ["glite-LFC_mysql"],
        inst_cert => "true",
    }
    package{"glite-LFC_mysql":
        require => [Repos["glite-LFC_mysql"], Yumrepo["epel"]],
        ensure => installed,
    }
    ifcfg{"eth0":
	ip => "217.73.173.24",
	netmask => "255.255.255.240",
	gateway => "217.73.173.17",
    }
	
    ifcfg{"eth1":
	bootproto => "dhcp",
    }
}


node "ui01" {
    include utcluj_grid_common
    package{"gcc":
	ensure => installed,
    }
    glite_node{ui:
        node_type => "UI",
        yum_repos => ["glite-UI"],
        install_yum_groups => ["glite-UI"], 
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
            "glite-MPI_utils", "glite-TORQUE_client", "cpuspeed","gcc"]:
        require => [Repos["glite-WN", "glite-TORQUE_client", "glite-MPI_utils"], 
		Yumrepo["epel"], Install_yum_groups["glite-WN"]],    # gLite groups must be installed before
                                                # gLite packages, otherwise conflicts may occur
        ensure => installed,
    }


#   exec { "yum -y update kernel" :
#     path => ["/bin", "/usr/bin", "/usr/sbin"],
#   }


    mount {"/home":
        ensure => mounted,
        device => "ce01.mosigrid.utcluj.ro:/home",
        atboot => true,
        fstype => "nfs",
        options => "hard,rw"
    }
    file{"/opt/exp_soft": 
	ensure => directory}
    mount {"/opt/exp_soft":
        require => File["/opt/exp_soft"],
	ensure => mounted,
        device => "se01.mosigrid.utcluj.ro:/opt/exp_soft",
        atboot => true,
        fstype => "nfs",
        options => "hard,rw"
    }

    service{"cpuspeed":
        ensure => running,
        enable => true,
	require => Package["cpuspeed"],
    }

    ntp_conf{"my_ntp":}

    service{"ntpd":
	ensure => running,
	enable => true,
	require => Package["ntp"],
    }
}

node "apel01" {
    include utcluj_grid_common
    package{["glite-APEL", "mysql-server"]:
	ensure => installed,
    }
	
    service{"mysqld":
        ensure => running,
        enable => true,
    }
    package{"fetch-crl":
	ensure => installed,
    	provider => "rpm",
	source => "http://glitesoft.cern.ch/EGEE/gLite/R3.2/glite-GENERIC/sl5/x86_64/RPMS.externals/fetch-crl-2.7.0-2.noarch.rpm",
    }
 
    glite_node{apel:
        node_type => "APEL",
        yum_repos => ["glite-APEL"],
    }
}


node default{}

