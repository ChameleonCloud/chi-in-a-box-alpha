require 'ipaddr'

Puppet::Functions.create_function(:cidr_to_ipv4_netmask) do
  dispatch :cidr_to_ipv4_netmask do
    param 'Stdlib::IP::Address::V4', :cidr
  end

  def cidr_to_ipv4_netmask(cidr)
    prefix = cidr.split('/').last.to_i
    IPAddr.new('255.255.255.255').mask(prefix).to_s
  end
end
