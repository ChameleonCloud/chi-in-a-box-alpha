# CHI-in-a-box

---
:warning: **Disclaimer**: CHI-in-a-box is currently in **Early Provider Alpha** for both the **Chameleon Associate** and **Independent Testbed** use-cases. This alpha version supports only a partial set of functionality that we expect to make available eventually. If you would like to explore becoming an alpha Chameleon Associate site, please contact us at contact@chameleoncloud.org. :warning:

---

## What is this?

CHI-in-a-box is a packaging of the implementation of the core services that together constitute the [Chameleon](https://www.chameleoncloud.org/) testbed for experimental Computer Science research. These services allow Chameleon users to discover information about Chameleon resources, allocate those resources for present and future use, configure them in various ways, and monitor various types of metrics.

While a large part of CHI (CHameleon Infrastructure) is based on an open source project (OpenStack), and all the extensions we made are likewise open source, without proper packaging there was no clear recipe on how to combine them and configure a testbed of this type. CHI-in-a-box is composed of the following three components:

  (a) open source dependencies supported by external projects (e.g., OpenStack and Grid’5000)
  (b) open source extensions made by the Chameleon team, both ones that are scheduled to be integrated into the original project (but have not been yet) and ones that are specific to the testbed
  (c) new code written by the team released under the Apache License 2.0.
  
### Who is it for?

We have identified demand for three types of scenarios in which users would like to use a packaging of Chameleon infrastructure:

  - **Chameleon Associate**: In this scenario a provider wants to add resources to the Chameleon testbed such that they are discoverable and available to all Chameleon users while retaining their own project identity (via branding, usage reports, some of the policies, etc.). This type of provider will provide system administration of their resources (hardware configuration and operation as well as CHI administration with the support of the Chameleon team) and use the Chameleon user services (user/project management, etc.), user portal, resource discovery, and appliance catalog. All user support will be provided by the Chameleon team.

  - **Chameleon Part-time Associate**: This scenario is similar to the Chameleon Associate but while the resources are available to the testbed users most of the time, the provider anticipates that they may want to take them offline for extended periods of time for other uses. In this scenario Chameleon support extends only to the time resources are available to the testbed.

  - **Independent Testbed**: In this scenario a provider wants to create a testbed that is in every way separate from Chameleon. This type of provider will use CHI for the core testbed services only and operate their user services (i.e., manage their own user accounts and/or projects, help desk, mailing lists and other communication channels, etc.), user portal, resource discovery, and appliance catalog (some of those services can in principle be left out at the cost of providing a less friendly interface to users). This scenario will be supported on a best effort basis only.

## Installation

The following steps assume an installation on a clean CentOS 7 machine, preferably with a private IP network address assigned (i.e. the way OpenStack is often set up.)

Install puppet and r10k:

    yum install epel-release -y
    yum install centos-release-openstack-ocata.noarch -y
    yum install crudini git puppet puppet-server -y
    yum update selinux-* nss curl libcurl -y
    systemctl enable puppetmaster
    systemctl start puppetmaster
    gem install --no-rdoc --no-ri r10k -v 2.6.4

Determine your private ip address and fqdn:

    > facter ipaddress
    10.0.1.11
    > facter fqdn
    host01.novalocal

Add your hosts private ip to `/etc/hosts` with the aliases 'puppet' and 'controller'. One way to do this is:

    echo "$(facter ipaddress) controller puppet" >> /etc/hosts

Add some variables to `manifests/settings.pp`. At minimum you'll need to specify the internalip:

    internalip: '10.0.1.11'

Run `gensettings` script to populate `manifests/settings.pp` with randomized secrets.

Update `manifests/site.pp` 'node' line to reflect your fqdn:

    node host01.novalocal { }

Use r10k to download puppet modules:

    r10k puppetfile install --puppetfile Puppetfile -v info

Run the `pub` script to put all the puppet manifest files in the right place:

    ./pub

Run puppet agent to actually do everything:

    puppet agent -t


## Site Prerequisites

### Assumptions

  - Compute nodes have IPMI-capable out of band (OOB) baseboard management controller (BMC). E.g. Dell iDRAC
  - Controller node has been provisioned with CentOS 7
  - SELinux is disabled
  - `facter fqdn` resolves to the Public/API address
  - This will be a single-controller installation. All services and endpoints will reside on one server.
  - Switches have been configured with appropriate VLAN settings
  - The operator will be responsible for adding nodes to Ironic and Blazar
  - The controller node must have SSH access to the switch or switches connecting the compute nodes, for multi-tenant networking

## Controller Node

Control Node Interfaces (the following is the TACC interface reference)

The operator must provide valid interface configurations

* em1 (10 GbE):  Management + Deployment
		  Rabbitmq
		  MariaDB
		  Openstack Internals
* em2: (10 GbE)  Public/API
		  HTTPS Proxy
		  Openstack Endpoints
		  Horizon
* em3: (1 GbE) Out of Band
		  IPMI

* p5p2 (10 GbE) Trunk Mode (Traffic In):   physnet (Neutron Contruct connecting SDN to physical network)
* p5p1 (10 GbE) Switch Mode (Traffic out):
external bridge
br-p5p2.400 Ironic TFTP interface. VLAN 400 is assigned to the Ironic Provisioning Network ($ironic_provisioning_vlan in settings.pp)

The FQDN of the server is expected to be the same name that is resolved by the Public/API interface, and will be used for SSL certs.

The operator must have an SSH key associated with their github account which must, in turn, have access to the puppet Chameleon repository at https://github.com/ChameleonCloud/puppet-chameleoncloud/tree/ciab

To Set Up a Baremetal Flavor:

    Admin -> System -> Flavors
	click create flavor
	fill in VCPU’s, RAM in MBs, and Disk size in GB


## To Setup CoreOS:

Download CoreOSramdisk and kernel (cpio.gz and vmlinuz)

CoreOS deploy kernel
```
wget http://tarballs.openstack.org/ironic-python-agent/coreos/files/coreos_production_pxe-stable-ocata.vmlinuz
```
CoreOS deploy ramdisk
```
wget http://tarballs.openstack.org/ironic-python-agent/coreos/files/coreos_production_pxe_image-oem-stable-ocata.cpio.gz
```

## Create images in Glance

```
openstack image create --public --disk-format aki --container-format aki --file ./coreos_production_pxe-stable-ocata.vmlinuz deploy_kernel
DEPLOY_KERNEL=<UUID generated>
openstack image create --public --disk-format ari --container-format ari --file ./coreos_production_pxe_image-oem-stable-ocata.cpio.gz deploy_ramdisk
DEPLOY_RAMDISK=<UUID generated>
```
## To Enroll Nodes into Ironic:

Create a node in Ironic

```
ironic --ironic-api-version latest node-create -d pxe_ipmitool_socat -n <NODE_NAME> \
-i ipmi_username=<IPMI_USERNAME> -i ipmi_password=<IPMI_PASSWORD> -i ipmi_address=<IPMI_ADDRESS> \
-p cpus=48 -p memory_mb=128000 -p local_gb=200 -p cpu_arch=x86_64 -p capabilities="boot_option:local" \
--network-interface neutron -i ipmi_terminal_port=<CONSOLE_PORT> \
-i deploy_kernel=$DEPLOY_KERNEL -i deploy_ramdisk=$DEPLOY_RAMDISK
NODEUUID=<generated UUID>
```

## To Set up Provisioning

Create a port for the node

```
ironic port-create -n $NODEUUID  -a <MAC of Node>
PORTUUID=<UUID generated>
```
Get provisioning network UUID

```
openstack network list
```

Make sure ironic network is set for multi-tenant

```
cat /etc/ironic/ironic.conf | grep enabled_network_interfaces
enabled_network_interfaces=flat,neutron #You want to see this
```

Configure node to use neutron
```
export IRONIC_API_VERSION=1.20
ironic node-set-maintenance $NODEUUID on
ironic node-update $NODEUUID replace network_interface=neutron
ironic port-update $PORTUUID add local_link_connection/switch_id=00:00:00:00:00:00 \ local_link_connection/switch_info=<Switch Hostname> \ local_link_connection/port_id=“$PORTUUID“
ironic node-set-maintenance $NODEUUID off
ironic node-update $NODEUUID add driver_info/ipmi_terminal_port=<Some Number> (Avoid collisions with other node ports)
ironic node-set-console-mode $NODEUUID on (Turn on Console)
```

Enable node to be used
```
ironic node-set-provision-state $NODEUUID provide
```
Validate Node Settings after launching instance
```
ironic node-validate $NODEUUID
```

## Known Issues

Blazar does not properly setup it’s database via puppet run. Manually do this after running puppet:

```
blazar-db-manage --config-file /etc/blazar/blazar.conf upgrade head
```
