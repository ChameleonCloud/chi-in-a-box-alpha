export OPENSTACK_RELEASE=ocata
export OS_BAREMETAL_API_VERSION=1.29

log() {
  echo "$@" >&2
}
export -f log
