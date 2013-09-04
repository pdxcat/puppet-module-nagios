#
# This fact prints a single ipv6 address from reverse dns lookup
#
# (c) 2013 Spencer Krum 
# Released under Apache2
Facter.add("dns_ip_6") do
  setcode do
    os = Facter.value('kernel')
    case os
    when /Linux/
      hostname = `hostname -f`
    else
      hostname = `hostname`
    end
    host_output = `host #{hostname}`
    v6_entries = []
    host_output.each_line do |line|
      v6_entries << line if line =~ /.*IPv6.*/
    end
    v6_addrs = []
    v6_entries.each do |entry|
      v6_addrs << entry.split(" ")[-1]
    end
    v6_addrs.join(',')
  end
end
