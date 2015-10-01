# Cookbook Name:: weblogic 
# Recipe:: create_datasource
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

wlst "Create JDBC datasource" do
  user "oracle" if node.platform_family?("rhel")
  weblogic_home node[:weblogic][:weblogic_home]
  code <<-END
connect('#{node[:weblogic][:username]}', '#{node[:weblogic][:password]}', 't3://#{node[:weblogic][:admin_console]}')
edit()
startEdit()

ds_name = "#{node[:weblogic][:datasource][:name]}"
jndi_name = "#{node[:weblogic][:datasource][:jndi_name]}"
jdbc_url = "#{node[:weblogic][:datasource][:jdbc_url]}"
datasource_target = #{node[:weblogic][:target].to_json} 
ds_password = "#{node[:weblogic][:datasource][:password]}"

###
# Create JDBC source
###
jdbcObject = create(ds_name,'JDBCSystemResource')
jdbcBean = jdbcObject.getJDBCResource()
jdbcBean.setName(ds_name)

# set JDBC params
jdbcParams = jdbcBean.getJDBCDataSourceParams()
jdbcParams.setJNDINames(['jdbc/'+jndi_name])

# set Driver params 
jdbcDriverParams = jdbcBean.getJDBCDriverParams()
jdbcDriverParams.setUrl(jdbc_url)
jdbcDriverParams.setDriverName('#{node[:weblogic][:datasource][:driver_name]}')
jdbcDriverParams.setPassword(ds_password)

# set Driver properties
p = jdbcDriverParams.getProperties()
drvProps = #{node[:weblogic][:datasource][:driver_props].to_json}
for k in drvProps:
  v = drvProps[k]
  p1 = p.createProperty(k)
  p1.setValue(v)

# set Connection pool params
cd('/JDBCSystemResources/' + ds_name+ '/JDBCResource/' + ds_name + '/JDBCConnectionPoolParams/' + ds_name)
poolParams= #{node[:weblogic][:datasource][:pool_props].to_json}
for k in poolParams:
  v = poolParams[k]
  p = set(k,v)

# set target
cd('/SystemResources/' + ds_name )
for i in datasource_target:
  set('Targets',jarray.array([ObjectName('com.bea:Name=' + i + ',Type=Server')], ObjectName))

save()
activate()
exit()
END
end
