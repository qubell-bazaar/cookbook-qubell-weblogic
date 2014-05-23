
case node['platform_family']
  when "debian"
    execute "update packages cache" do
      command "apt-get update"
    end
  when "rhel"
    package "yum" do
      action :upgrade
    end
  end

package "unzip"
package "bc"
package "python-setuptools"
package "libaio"
package "dejavu-fonts-common"
package "dejavu-serif-fonts"
package "dejavu-sans-mono-fonts"
package "dejavu-lgc-sans-fonts"
package "dejavu-sans-fonts"
package "dejavu-lgc-serif-fonts"
package "dejavu-lgc-sans-mono-fonts"

case node["platform_family"]
  when "rhel"
    service "iptables" do
      action :stop
    end
  when "debian"
    service "ufw" do
      action :stop
    end
  end

include_recipe "jrockit::default"
include_recipe "java::openjdk"

directory "#{node[:weblogic][:tmp_path]}" do
	owner "root"
	group "root"
	mode 00755
	action :create
	recursive true
end

template "#{node[:weblogic][:tmp_path]}/weblogic_silent.xml" do
	source "silent.xml.erb"
	owner "root"
	group "root"
	mode 00644
	variables(:options => node[:weblogic][:silent_conf])
end

if /.jar$/.match("#{node[:weblogic][:binary_url]}")
	remote_file "#{node[:weblogic][:tmp_path]}/weblogic_x86_64.jar" do
		action :create_if_missing
		owner "root"
		group "root"
		mode 00755
		source "#{node[:weblogic][:binary_url]}"
		checksum "sha256checksum"
	end

	execute "Installing Weblogic" do
		command "java -d64 -jar #{node[:weblogic][:tmp_path]}/weblogic_x86_64.jar -mode=silent -silent_xml=#{node[:weblogic][:tmp_path]}/weblogic_silent.xml"
		action :run
		not_if { File.directory?("#{node[:weblogic][:weblogic_home]}") }
	end
else
	raize ArgumentError "You should use Generic Weblogic binary, supported x86_64!"
end

file "#{node[:weblogic][:tmp_path]}/weblogic_x86_64.jar" do
	action :delete
	owner "root"
	group "root"
	mode "0644"
end

include_recipe "weblogic::create_domain"
