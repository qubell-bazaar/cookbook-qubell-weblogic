#
# Cookbook Name:: weblogic
# Recipe:: rhel
#
# Install and configure Oracle Weblogic 10.3
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

###
# Check requirements
###
raise "Installation Jar must be provided! Please set 'weblogic.install.jar' attribute" if node[:weblogic][:install][:jar].empty?

bash "check #{node[:weblogic][:root_dir]} > 20G" do
  code "df -P #{node[:weblogic][:root_dir]} | awk '/\\//{if ($2/1024/1024 < 20) exit 1}'"
end

group "oinstall"
user "oracle" do
  group "oinstall"
end

node.set[:java][:jdk_version] = "7"
node.set[:java][:install_flavor] = "oracle"
node.set[:java][:oracle][:accept_oracle_download_terms] = true
include_recipe "java"

###
# Download installer
###
directory node[:weblogic][:install_dir]

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
weblogic_response_file = ::File.join(node[:weblogic][:install_dir], "silent.xml")
weblogic_response_params = "-mode=silent -silent_xml=#{weblogic_response_file}"
case node[:weblogic][:version]
when "12"
  weblogic_response_file = ::File.join(node[:weblogic][:install_dir], "wl.rsp")
  weblogic_response_params = "-silent -responseFile #{weblogic_response_file}"
end

template weblogic_response_file do
  variables({
    :weblogic_home => node[:weblogic][:weblogic_home],
    :middleware_home => node[:weblogic][:middleware_home]
  })
end

file "/etc/oraInst.loc" do
  content <<EEND
inventory_loc=#{node[:weblogic][:root_dir]}/oraInventory
inst_group=oinstall
EEND
end

directory ::File.join(node[:weblogic][:root_dir], "oraInventory") do
  owner "oracle"
  group "oinstall"
end

bash "clean #{node[:weblogic][:middleware_home]}" do
  code "rm -rf #{node[:weblogic][:middleware_home]}"
  not_if { File.exists?(::File.join(node[:weblogic][:install_dir], ".install.done")) }
end

directory node[:weblogic][:middleware_home] do
  owner "oracle"
  group "oinstall"
end

bash "install weblogic" do
  creates ::File.join(node[:weblogic][:install_dir], ".install.done")
  code <<-END
    runuser -l oracle -c "\
    java -d64 \
    -jar #{::File.join(node[:weblogic][:install_dir], ::File.basename(node[:weblogic][:install][:jar]))}\
    #{weblogic_response_params}" && \
    touch #{::File.join(node[:weblogic][:install_dir], ".install.done")}
  END
end

directory node[:weblogic][:domain_home] do
  owner "oracle"
  group "oinstall"
end

# Recreate SSL key
bash "recreate SSL key" do
  cwd "/tmp"
  user "oracle"
  group "oinstall"
  code <<-END
    source #{::File.join(node[:weblogic][:weblogic_home], "server", "bin", "setWLSEnv.sh")}
    java utils.CertGen -keyfilepass DemoIdentityPassPhrase -certfile newcert -keyfile newkey
    java utils.ImportPrivateKey -keystore DemoIdentity.jks -storepass DemoIdentityKeyStorePassPhrase -keyfile newkey.pem -keyfilepass DemoIdentityPassPhrase -certfile newcert.pem -alias demoidentity
    mv -f DemoIdentity.jks #{::File.join(node[:weblogic][:weblogic_home], "server", "lib")}
  END
end
