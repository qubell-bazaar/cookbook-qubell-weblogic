# include_recipe 'weblogic::_decrypt_params'

directory node[:weblogic][:manage_scripts_path] do
  case node[:platform_family]
    when "rhel", "debian"
      owner "root"
      group "root"
    when "windows"
      owner "Administrator"
    mode "0755"
  end
  action :create
  recursive true
end

template "#{node[:weblogic][:manage_scripts_path]}/start_node_manager.py" do
  source "wlst/start_node_manager.py.erb"
  case node[:platform_family]
    when "rhel", "debian"
      owner "root"
      group "root"
    when "windows"
      owner "Administrator"
  end
  mode "0755"
end

template "#{node[:weblogic][:manage_scripts_path]}/start_admin_server.py" do
  source "wlst/manage_admin_server.py.erb"
  case node[:platform_family]
    when "rhel", "debian"
      owner "root"
      group "root"
    when "windows"
      owner "Administrator"
  end
  mode "0755"
  variables( :action => :start )
end

template "#{node[:weblogic][:manage_scripts_path]}/stop_admin_server.py" do
  source "wlst/manage_admin_server.py.erb"
  case node[:platform_family]
    when "rhel", "debian"
      owner "root"
      group "root"
    when "windows"
      owner "Administrator"
  end
  mode "0755"
  variables( :action => :stop )
end
