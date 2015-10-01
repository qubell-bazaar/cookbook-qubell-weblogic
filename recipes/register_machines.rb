#
# Cookbook Name:: weblogic
# Recipe:: register_machines
#
# Install and configure Oracle Weblogic 10.3
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

require 'resolv'

Array(node[:weblogic][:machine_addresses]).each do |dns|
  wlst "registering #{dns} in t3://#{node[:weblogic][:admin_console]}" do
    user "oracle" if node.platform_family?("rhel")
    code <<-END
connect('#{node[:weblogic][:username]}', '#{node[:weblogic][:password]}', 't3://#{node[:weblogic][:admin_console]}')
edit()
startEdit()
try:
  create('#{dns}','Machine')
except:
  pass
cd('/Machines/#{dns}/NodeManager/#{dns}')
set('ListenAddress', '#{Resolv.getaddress(dns)}')
set('ListenPort', 5556)
activate()
disconnect()
exit()
    END
    weblogic_home node[:weblogic][:weblogic_home]
  end
end
