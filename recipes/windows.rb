#
# Cookbook Name:: weblogic
# Recipe:: windows
#
# Install and configure Oracle Weblogic 10.3
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

###
# Check requirements
###
raise "Installation Jar must be provided! Please set 'weblogic.install.jar' attribute" if node[:weblogic][:install][:jar].empty?
raise "Installation binary for Oracle JDK must be provided! Please set 'weblogic.install.windows_jdk' attribute" if node[:weblogic][:install][:windows_jdk].empty?

###
# Prerequsites
###

# Disable firewall
powershell_script "disable_firewall" do
  flags "-ExecutionPolicy Unrestricted"
  code <<-EOH
    netsh advfirewall set allprofiles state off
  EOH
end

# Install Java
node.set[:java][:windows][:url] = node[:weblogic][:install][:windows_jdk]
node.set[:java][:install_flavor] = "windows"
node.set[:java][:jdk_version] = "6"
node.set[:java][:windows][:package_name] = "Java(TM) SE Development Kit 6 Update 45 (64-bit)"
node.set[:java][:java_home] = "C:\\Program\ Files\\Java\\jdk"
include_recipe "java::windows"

execute 'set java_home' do
  command "setx -m JAVA_HOME \"#{node[:java][:java_home]}\""
  only_if { ENV['JAVA_HOME'] != "#{node[:java][:java_home]}" }
end

execute 'set java_path' do
  command "setx -m PATH \"%PATH%;#{node[:java][:java_home]}\\bin\""
end

###
# Download installer
###
directory node[:weblogic][:install_dir] do
  owner node[:current_user]
end

remote_file ::File.join(node[:weblogic][:install_dir], ::File.basename(node[:weblogic][:install][:jar])) do
  source node[:weblogic][:install][:jar]
  retries 2
  use_conditional_get true
  use_etag true
  use_last_modified true
  action :create_if_missing
end

###
# Run installer
###
template ::File.join(node[:weblogic][:install_dir], "silent.xml") do
  variables({
    :weblogic_home => node[:weblogic][:weblogic_home],
    :middleware_home => node[:weblogic][:middleware_home]
  })
end

directory node[:weblogic][:middleware_home] do
  owner node[:current_user]
end

file ::File.join(node[:weblogic][:install_dir], ".install.done") do
  owner node[:current_user]
  action :nothing
end

execute "install weblogic" do
  creates ::File.join(node[:weblogic][:install_dir], ".install.done")
  command <<-END
    \"#{node[:java][:java_home]}\\bin\\java\" -jar \
    -jar #{::File.join(node[:weblogic][:install_dir], ::File.basename(node[:weblogic][:install][:jar]))}\
    -mode=silent \
    -silent_xml=#{::File.join(node[:weblogic][:install_dir], "silent.xml")}
  END
  notifies :create, "file[#{::File.join(node[:weblogic][:install_dir], ".install.done")}]", :immediate
end

directory node[:weblogic][:domain_home] do
  owner node[:current_user]
end

# Recreate SSL key
if node[:cloud].nil?
  cn = node[:hostname]
elsif node[:cloud][:public_hostname].nil?
  cn = node[:cloud][:local_hostname]
else
  cn = node[:cloud][:public_hostname]
end
batch "recreate SSL key" do
  code <<-END
    call #{::File.join(node[:weblogic][:weblogic_home], "server", "bin", "setWLSEnv.cmd")}
    java utils.CertGen -keyfilepass DemoIdentityPassPhrase -certfile newcert -keyfile newkey -cn #{cn}
    java utils.ImportPrivateKey -keystore DemoIdentity.jks -storepass DemoIdentityKeyStorePassPhrase -keyfile newkey.pem -keyfilepass DemoIdentityPassPhrase -certfile newcert.pem -alias demoidentity
    move /Y DemoIdentity.jks #{::File.join(node[:weblogic][:weblogic_home], "server", "lib")}
  END
end
