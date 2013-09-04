#
# This fact prints a single ipv4 address from reverse dns lookup
#
# (c) 2013 Spencer Krum 
# Released under Apache2
Facter.add("dns_ip_4") do
  setcode do
    os = Facter.value('kernel')
    case os
    when /Linux/
      hostname = `hostname -f`
    else
      hostname = `hostname`
    end
    host_output = `host #{hostname}`
    v4_entries = host_output.scan(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/)
    v4_entries.join(',')
  end
end
