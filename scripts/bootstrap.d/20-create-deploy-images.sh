file_base="http://tarballs.openstack.org/ironic-python-agent/coreos/files"

echo "################################"
echo " Deployment image setup"
echo "################################"
echo
echo "Pulling kernel and ramdisk images from $file_base."
echo

wget "$file_base/coreos_production_pxe-stable-$OPENSTACK_RELEASE.vmlinuz"
wget "$file_base/coreos_production_pxe_image-oem-stable-$OPENSTACK_RELEASE.cpio.gz"

os_image_create() {
  local name="$1"
  local file="$2"

  openstack image create \
    --public \
    --disk-format aki \
    --container-format aki \
    --file "$file"
    "$name"
}

# Publish for future steps
DEPLOY_KERNEL="$(os_image_create deploy_kernel ./coreos_production_pxe-stable-ocata.vmlinuz)"
DEPLOY_RAMDISK="$(os_image_create deploy_ramdisk ./coreos_production_pxe_image-oem-stable-ocata.cpio.gz)"

rm -f ./coreos_production_pxe-stable-ocata.vmlinuz
rm -f ./coreos_production_pxe_image-oem-stable-ocata.cpio.gz
