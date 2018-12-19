file_base="http://tarballs.openstack.org/ironic-python-agent/coreos/files"

log "################################"
log " Deployment image setup"
log "################################"
log

os_image_create() {
  local name="$1"
  local file="$2"

  if [[ ! -e "$file" ]]; then
    log "Pulling $name image from $file_base."
    wget -q "$file_base/$file"
  fi

  openstack image show "$name" -f value -c id \
   || openstack image create -f value -c id \
      --public \
      --disk-format aki \
      --container-format aki \
      --file "$file" \
      "$name"
}

export DEPLOY_KERNEL="$(os_image_create deploy_kernel coreos_production_pxe-stable-$OPENSTACK_RELEASE.vmlinuz)"
export DEPLOY_RAMDISK="$(os_image_create deploy_ramdisk coreos_production_pxe_image-oem-stable-$OPENSTACK_RELEASE.cpio.gz)"

log "Done."
log
