
powershell_script "disable_firewall" do
  flags "-ExecutionPolicy Unrestricted"
  code <<-EOH
    netsh advfirewall set allprofiles state off
  EOH
end

directory "#{Chef::Config[:node_path]}" do
  mode "0775"
  action :create
  recursive true
  owner node['current_user']
end

include_recipe "java::windows"

execute 'set java_home' do
  command "setx -m JAVA_HOME \"#{node[:weblogic][:java_home]}\""
  only_if { ENV['JAVA_HOME'] != "#{node[:weblogic][:java_home]}" }
end

execute 'set java_path' do
  command "setx -m PATH \"%PATH%;#{node[:weblogic][:java_home]}\\bin\""
end

directory "#{node[:weblogic][:tmp_path]}" do
	owner "Administrator"
	mode 00755
	action :create
	recursive true
end

template "#{node[:weblogic][:tmp_path]}/weblogic_silent.xml" do
	source "silent.xml.erb"
	owner "Administrator"
	mode 00644
	variables(:options => node[:weblogic][:silent_conf])
end

if /.jar$/.match("#{node[:weblogic][:binary_url]}")
	remote_file "#{node[:weblogic][:tmp_path]}/weblogic_x86_64.jar" do
		action :create_if_missing
		owner "Administrator"
		mode 00755
		source "#{node[:weblogic][:binary_url]}"
		checksum "sha256checksum"
	end

	execute "Installing Weblogic" do
		command "\"#{node[:weblogic][:java_home]}\\bin\\java\" -d64 -jar #{node[:weblogic][:tmp_path]}\\weblogic_x86_64.jar -mode=silent -silent_xml=#{node[:weblogic][:tmp_path]}\\weblogic_silent.xml"
		action :run
		not_if { File.directory?("#{node[:weblogic][:weblogic_home]}") }
	end
else
	raize ArgumentError "You should use Generic Weblogic binary, supported x86_64!"
end

file "#{node[:weblogic][:tmp_path]}\\weblogic_x86_64.jar" do
	action :delete
	owner "Administrator"
	mode "0644"
end

include_recipe "weblogic::create_domain"
