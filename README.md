# CHI-in-a-box

---
:warning: **Disclaimer**: CHI-in-a-box is currently in **Early Provider Alpha** for both the **Chameleon Associate** and **Independent Testbed** use-cases. This alpha version supports only a partial set of functionality that we expect to make available eventually. If you would like to explore becoming an alpha Chameleon Associate site, please contact us at contact@chameleoncloud.org. :warning:

---

## What is this?

CHI-in-a-box is a packaging of the implementation of the core services that together constitute the [Chameleon](https://www.chameleoncloud.org/) testbed for experimental Computer Science research. These services allow Chameleon users to discover information about Chameleon resources, allocate those resources for present and future use, configure them in various ways, and monitor various types of metrics.

While a large part of CHI (**CH**\ ameleon **I**\ nfrastructure) is based on an open source project (OpenStack), and all the extensions we made are likewise open source, without proper packaging there was no clear recipe on how to combine them and configure a testbed of this type. CHI-in-a-box is composed of the following three components:

  1. open source dependencies supported by external projects (e.g., OpenStack and Grid’5000)
  2. open source extensions made by the Chameleon team, both ones that are scheduled to be integrated into the original project (but have not been yet) and ones that are specific to the testbed
  3. new code written by the team released under the Apache License 2.0.

### Who is it for?

We have identified demand for three types of scenarios in which users would like to use a packaging of Chameleon infrastructure:

  - **Chameleon Associate**: In this scenario a provider wants to add resources to the Chameleon testbed such that they are discoverable and available to all Chameleon users while retaining their own project identity (via branding, usage reports, some of the policies, etc.). This type of provider will provide system administration of their resources (hardware configuration and operation as well as CHI administration with the support of the Chameleon team) and use the Chameleon user services (user/project management, etc.), user portal, resource discovery, and appliance catalog. All user support will be provided by the Chameleon team.

  - **Chameleon Part-time Associate**: This scenario is similar to the Chameleon Associate but while the resources are available to the testbed users most of the time, the provider anticipates that they may want to take them offline for extended periods of time for other uses. In this scenario Chameleon support extends only to the time resources are available to the testbed.

  - **Independent Testbed**: In this scenario a provider wants to create a testbed that is in every way separate from Chameleon. This type of provider will use CHI for the core testbed services only and operate their user services (i.e., manage their own user accounts and/or projects, help desk, mailing lists and other communication channels, etc.), user portal, resource discovery, and appliance catalog (some of those services can in principle be left out at the cost of providing a less friendly interface to users). This scenario will be supported on a best effort basis only.

## Installation

### Assumptions

  - Compute nodes have IPMI-capable out of band (OOB) baseboard management controller (BMC). E.g. Dell iDRAC
  - Controller node has been provisioned with CentOS 7
  - SELinux is disabled
  - `facter fqdn` resolves to the Public/API address. The FQDN of the server is expected to be the same name that is resolved by the Public/API interface, and will be used for SSL certs.
  - This will be a single-controller installation. All services and endpoints will reside on one server.
  - Switches have been configured with appropriate VLAN settings (trunking of provisioning VLAN ranges)
  - The controller node must have SSH access to the switch or switches connecting the compute nodes, for multi-tenant networking
  - The operator must have an SSH key associated with their github account which must, in turn, have access to the [puppet-chameleoncloud](https://github.com/ChameleonCloud/puppet-chameleoncloud) repository.
  - The operator must provide at least two network interfaces. 10GbE is recommended.
    - **em1**: Private (Rabbitmq, MariaDB, OpenStack internals, Neutron, IPMI)
    - **em2**: Public (OpenStack APIs via HTTPS proxy, Horizon, Neutron external bridge)

### Step-by-step

The following steps assume an installation on a clean CentOS 7 machine, preferably with a private IP network address assigned (i.e. the way OpenStack is often set up.)

1. Install puppet and r10k:

  ```shell
  yum install epel-release -y
  yum install centos-release-openstack-ocata.noarch -y
  yum install crudini git puppet puppet-server -y
  yum update selinux-* nss curl libcurl -y
  systemctl enable puppetmaster
  systemctl start puppetmaster
  gem install --no-rdoc --no-ri r10k -v 2.6.4
  ```

2. Determine your private ip address and fqdn:

  ```shell
  PRIVATE_IP=$(facter ipaddress)
  FQDN=$(facter fqdn)
  ```

3. Add your private ip to `/etc/hosts` with the alias 'puppet'. One way to do this is:

  ```shell
  echo "$(facter ipaddress) puppet" >> /etc/hosts
  ```

4. Copy `manifest/settings.pp.example` to `manifests/settings.pp`. At minimum you'll need to specify the public and private network subnets for your controller node.

5. Run `gensettings` script to (re-)populate `manifests/settings.pp` with randomized secrets.

6. Use r10k to download puppet modules:

  ```shell
  r10k puppetfile install --puppetfile Puppetfile -v info
  ```

7. Run puppet agent via the `./puppet` wrapper script to install and configure the infrastructure pieces:

  ```shell
  ./puppet agent --test
  ```

### Node enrollment

To enroll your nodes, we have provided a bootstrap script you can run against a configuration of nodes. To use this, first prepare some information about your nodes. You will need to pick a name for the node, know its (existing) IPMI address on the network (and be able to connect to this from the controller node already), its (existing) IPMI password, the MAC address for its NIC, the name of the switch it is connected to (which you have defined in `$neutron_ngs_switches` in your `settings.pp` file), and which switch port it is connected to. An example is:

```
[node01]
ipmi_username = root
ipmi_password = hopefully_not_default
ipmi_address = 10.10.10.1
ipmi_port = 623 # Optional, defaults to this value.
# Arbitrary terminal port; this is used to plumb a socat process to allow
# reading and writing to a virtual console. It is just important that it does
# not conflict with another node or host process.
ipmi_terminal_port = 30133
switch_name = LeafSwitch01
switch_port_id = Te 1/10/1
mac_address = 00:00:de:ad:be:ef

# .. repeat for more nodes.
```

Once you have this file (let's call it `nodes.conf`), you can kick off the bootstrap script:

```shell
./scripts/bootstrap.sh nodes.conf
```

This script will do many things, namely:

  * Perform sanity checks that your environment is set up properly
  * Download kernel and ramdisk images and add them to Glance (used for Ironic provisioning)
  * Create a `baremetal` Nova flavor used for baremetal provisioning with Ironic
  * Create a `freepool` Nova aggregate for use by the Blazar reservation system
  * Enroll each node into Ironic and register its network port (so Neutron can hook it up to networks later)
  * Add the node to Blazar to make it reservable
  * Download Chameleon base images and add to your local Glance registry.

Once all of this has completed successfully, you should have a working setup capable of performing baremetal provisioning.

This bootstrap script is designed to be run multiple times in case you encounter failures; it should be safe to re-run.

### Troubleshooting

Please see the [troubleshooting guide](./TROUBLESHOOTING.md) for remedies to problems that have been seen in practice. It is also helpful to read about [Ironic provisioning](https://docs.openstack.org/ironic/pike/user/) so you can diagnose which step may be failing for your setup.
