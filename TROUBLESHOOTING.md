## Known Issues

1. **Blazar does not properly setup it’s database via puppet run.**
   Manually do this after running puppet:

  ```
  blazar-db-manage --config-file /etc/blazar/blazar.conf upgrade head
  ```

2. **Puppet script may not stop when an error is encountered** (e.g. Apache restart fail). You can find most recent error by using tmux/screen or `tee` to a build log.

3. **Horizon returns errors.** This is likely due to the Nova endpoint not being versioned properly.

    - Run `openstack endpoint list` to find the the UUIDs of Novas's endpoints.
    - Append the version identifier **v2.1** (latest): `openstack endpoint set --url "$old_url/v2.1" "$uuid"`
    - Logout and login to Horizon web UI and check if it works.

4. **No tables in ironic database.**

    - Sync DB again: `ironic-dbsync --config-file /etc/ironic/ironic.conf create_schema`
    - Re-run Puppet: `./puppet agent --test`

5. **No internet (or disconnect) when executing the Puppet script.** During the course of provisioning the IP addresses on the interfaces will move to the OVS bridges created by Neutron; this causes remote connections to terminate. Try running the initial Puppet run in a `tmux` or `screen` session (or via an IPMI console.) If there are still issues:

    - Ensure the physical interface is added as a port on `br-ex` using `ovs-vsctl show`. If not, `ovs-vsctl add-port br-ex <public_interface>`
    - Modify `/etc/sysconfig/network-script/ifcfg-<public_interface>` to make this persist on boot.

6. **Serial console doesn't work.**. Check if those serial console bitrate match with each other: Serial-Over-LAN (BMC), OS setting, and Ironic's configuration.

7. **Horizon displays “No valid host was found” error**. This can happen for _many_ reasons. Check a few things:

    - Are there errors in the `/var/log/ironic/ironic-conductor.log`?
    - Is the node in maintenance mode? (It must be set to the "available" status for Nova to consider it.)
    - Does the node have enough space on the file system? It must have more than the space defined in the `baremetal` Nova flavor (we set this to a low value on purpose; 20Gb).

8. **Drucut refuse to continue because PXE sets both static IP and DHCP(BOOTIF) when booting deploy ramdisk**. Looks like this

    ```
    dracut: FATAL: For argument 'ip=10.20.30.9:10.20.30.254:10.20.30.254:255.255.255.0'
    Sorry, setting client-ip does not make sense for 'dhcp'           
    dracut: Refusing to continue
    ```

    - Modify `/usr/lib/python2.7/site-packages/ironic/drivers/modules/pxe_config.template`; modify line 6 (`ipappend 3`) to `ipappend 2` ([reference](https://www.syslinux.org/wiki/index.php?title=SYSLINUX#SYSAPPEND_bitmask)).
