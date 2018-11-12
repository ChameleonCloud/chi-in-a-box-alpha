require 'ipaddr'

Puppet::Functions.create_function(:cidr_to_ipv4_range) do
  dispatch :cidr_to_ipv4_range do
    param 'Stdlib::IP::Address::V4', :cidr
  end

  def cidr_to_ipv4_range(cidr)
    IPAddr.new(cidr).to_range.map(&:to_s).to_a
  end
end
