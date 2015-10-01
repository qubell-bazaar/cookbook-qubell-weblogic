Array(node[:weblogic][:artifacts]).each do |artifact|
  remote_file ::File.join(node[:weblogic][:install_dir], ::File.basename(artifact["url"])) do
    source artifact["url"]
    retries 2
    use_conditional_get true
    use_etag true
    use_last_modified true
    action :create_if_missing
  end
  wlst "deploy #{::File.basename(artifact["url"])}" do
    weblogic_home node[:weblogic][:weblogic_home]
    user "oracle" if node.platform_family?("rhel")
    code <<-END
connect('#{node[:weblogic][:username]}', '#{node[:weblogic][:password]}', 't3://#{node[:weblogic][:admin_console]}')
app = getMBean('/AppDeployments/#{artifact["name"]}')
if app is not None:
  undeploy('#{artifact["name"]}')
deploy('#{artifact["name"]}', '#{::File.join(node[:weblogic][:install_dir], ::File.basename(artifact["url"]))}',
       targets='#{Array(artifact["targets"]).join(",")}',
       libraryModule='#{String(artifact["library"])}')
exit()
    END
  end
end
