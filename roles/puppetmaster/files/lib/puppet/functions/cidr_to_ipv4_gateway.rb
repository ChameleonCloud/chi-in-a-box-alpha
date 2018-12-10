require 'ipaddr'

Puppet::Functions.create_function(:cidr_to_ipv4_gateway) do
  dispatch :cidr_to_ipv4_gateway do
    param 'Stdlib::IP::Address::V4', :cidr
  end

  def cidr_to_ipv4_gateway(cidr)
    # Chooses the 1st address
    IPAddr.new(cidr).succ.to_s
  end
end
