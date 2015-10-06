#
# Cookbook Name:: weblogic
# Recipe:: create_wl_domain
#
# Install and configure Oracle Weblogic 10.3
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

###
# Check requirements
###
unless node[:weblogic][:password] =~ /^(?=.*[A-Z]+.*)^(?=.*[0-9]+.*)(?=.*[a-zA-Z]+.*)[0-9a-zA-Z]{8,}$/
  error_msg = 'Password must be 8 symbols long and contain at least 1 digit and 1 capital letter!'
  raise ArgumentError, error_msg
end

###
# Create domain
###
case node.platform_family
when "rhel"
  bash "clean stale domain dir" do
    code <<-END
      rm -rf #{::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name])}
    END
    not_if { File.exists?(::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name], "domain.created")) }
  end
when "windows"
  powershell_script "clean stale domain dir" do
    flags "-ExecutionPolicy Unrestricted"
    code <<-END
      remove-item #{::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name])} -force -recurse 
    END
    not_if { File.exists?(::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name], "domain.created")) }
    only_if { File.exists?(::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name])) }
  end
end

file ::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name], "domain.created") do
  action :nothing
end

domain_template = node[:weblogic][:domain_template]
nodemanager_home = node[:weblogic][:nodemanager_home]

wlst "creating WebLogic domain" do
  creates ::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name], "domain.created")
  user "oracle" if node.platform_family?("rhel")
  code <<-END
createDomain('#{domain_template}',
             '#{::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name])}',
             '#{node[:weblogic][:username]}','#{node[:weblogic][:password]}')
exit()
  END
  notifies :create, "file[#{::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name], "domain.created")}]", :immediate
  weblogic_home node[:weblogic][:weblogic_home]
end

file ::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name], "startNodeManager.py") do
  user "oracle" if node.platform_family?("rhel")
  content <<-EEND
startNodeManager(verbose='true',
                 NodeManagerHome='#{nodemanager_home}',
                 ListenPort='5556',
                 ListenAddress='0.0.0.0',
                 StartScriptEnabled='true',
                 StopScriptEnabled='true',
                 CrashRecoveryEnabled='true',
                 QuitEnabled='true')
exit()
  EEND
end

file ::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name], "stopNodeManager.py") do
  user "oracle" if node.platform_family?("rhel")
  content <<-EEND
nmConnect('#{node[:weblogic][:username]}', '#{node[:weblogic][:password]}', domainName='#{node[:weblogic][:domain_name]}')
stopNodeManager()
exit()
  EEND
end

case node[:platform_family]
when "rhel"
  # For Linux wrap start/stop script into init.d service
  template "/etc/init.d/wlnodemanager" do
    mode "0755"
  end

  service "wlnodemanager" do
    action [ :enable, :start ]
  end
else
  # Recreate SSL key
  bash "recreate SSL key (NodeManager)" do
    cwd "/tmp"
    user "oracle"
    group "oinstall"
    code <<-END
      source #{::File.join(node[:weblogic][:weblogic_home], "server", "bin", "setWLSEnv.sh")}
      java utils.CertGen -keyfilepass DemoIdentityPassPhrase -certfile newcert -keyfile newkey
      java utils.ImportPrivateKey -keystore DemoIdentity.jks -storepass DemoIdentityKeyStorePassPhrase -keyfile newkey.pem -keyfilepass DemoIdentityPassPhrase -certfile newcert.pem -alias demoidentity
      mv -f DemoIdentity.jks #{::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name], "security")}
    END
  end
  # Universal method, does not survive reboot
  wlst "start NodeManager" do
    creates ::File.join(nodemanager_home, "nodemanager.log.lck")
    user "oracle" if node.platform_family?("rhel")
    code lazy { open(::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name], "startNodeManager.py")).read }
    weblogic_home node[:weblogic][:weblogic_home]
  end
end
