log "################################"
log " Base images"
log "################################"
log
log "Installing base images."
log

for image in CC-CentOS7; do
  file="$image.qcow2"

  if [[ ! -e "$file" ]]; then
    log "Downloading image '$image'..."
    openstack image save --file "$file" "$image" \
      --os-auth-url="https://chi.uc.chameleoncloud.org:5000/v3" \
      --os-identity-api-version="3" \
      --os-token=""
    log "Uploading to Glance..."
    openstack image create --file "$file" --disk-format "qcow2" --public "$image"
  fi
done
