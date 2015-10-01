#
# Cookbook Name:: weblogic
# Recipe:: enroll_wl_domain
#
# Install and configure Oracle Weblogic 10.3
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

wlst "enroll NodeManager to domain" do
  user "oracle" if node.platform_family?("rhel")
  code <<-END
connect('#{node[:weblogic][:username]}', '#{node[:weblogic][:password]}', 't3://#{node[:weblogic][:admin_console]}')
nmEnroll('#{::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name])}', '#{::File.join(node[:weblogic][:weblogic_home], "common", "nodemanager")}')
disconnect()
exit()
  END
  weblogic_home node[:weblogic][:weblogic_home]
end
