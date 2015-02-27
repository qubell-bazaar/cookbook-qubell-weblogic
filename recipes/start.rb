include_recipe "weblogic::create_domain"

wlst_script "Starting Weblogic NodeManager" do
  script "#{node[:weblogic][:manage_scripts_path]}/start_node_manager.py"
  log "/tmp/start_node_manager.log"
end

wlst_script "Starting Weblogic AdminServer" do
  script "#{node[:weblogic][:manage_scripts_path]}/start_admin_server.py"
  log "/tmp/start_admin_server.log"
end

bash "Waiting for #{node[:weblogic][:domain_name]} domain deployment" do
  user 'root'
  code <<-EOH
  while [ "`curl -s -w "%{http_code}" "http://localhost:7001/console" -o /dev/null`" == "000" ];
  do
    sleep 10
  done
  if [ "`curl -s -w "%{http_code}" "http://localhost:7001/console" -o /dev/null`" == "200" ];
  then
    exit 0
  else
    exit 1
  fi
  EOH
end

