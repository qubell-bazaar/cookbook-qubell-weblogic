#
# Cookbook Name:: weblogic
# Recipe:: start_wl_domain
#
# Install and configure Oracle Weblogic 10.3
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

file ::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name], "startAdminServer.py") do
  owner "oracle" if node.platform_family?("rhel")
  content <<-EEND
from urllib2 import urlopen
from time import sleep

startServer('AdminServer',
            '#{node[:weblogic][:domain_name]}', 't3://#{node[:weblogic][:admin_console]}',
            '#{node[:weblogic][:username]}', '#{node[:weblogic][:password]}',
            '#{::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name])}',
            'false', 60000,
            jvmArgs='#{Array(node[:weblogic][:admin_server][:arguments]).join(" ")}', spaceAsJvmArgsDelimiter='true')

started = False
url = 'http://localhost:7001/console'
for n in range(60):
  try:
    f = urlopen(url)
    res = f.geturl()
  except:
    res = 'null'
  print "."
  if res != 'null':
    started = True
    break
  sleep(10)

if not started:
  print "WebLogic AdminServer failed to start in 10 minutes!"
  exit(1)

exit()
  EEND
end

file ::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name], "stopAdminServer.py") do
  owner "oracle" if node.platform_family?("rhel")
  content <<-EEND
connect('#{node[:weblogic][:username]}', '#{node[:weblogic][:password]}', 't3://#{node[:weblogic][:admin_console]}')
shutdown()
exit()
  EEND
end

case node[:platform_family]
when "rhel"
  # For Linux wrap start/stop script into init.d service
  template "/etc/init.d/wladminserver" do
    mode "0755"
  end

  service "wladminserver" do
    action [ :enable, :start ]
  end
else
  # Universal method, does not survive reboot
  wlst "start AdminServer" do
    user "oracle" if node.platform_family?("rhel")
    code lazy { open(::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name], "startAdminServer.py")).read }
    weblogic_home node[:weblogic][:weblogic_home]
  end

  remote_file "wait AdminServer startup" do
    path ::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name], "dummy")
    source "http://#{node[:weblogic][:admin_console]}/console"
    retries 60
    retry_delay 10
    backup false
  end
end
