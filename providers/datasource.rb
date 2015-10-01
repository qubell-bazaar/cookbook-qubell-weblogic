use_inline_resources

action :create do
  wlst "Create JDBC datasource #{new_resource.name}" do
    user "oracle" if node.platform_family?("rhel")
    weblogic_home node[:weblogic][:weblogic_home]
    code <<-END
connect('#{node[:weblogic][:username]}', '#{node[:weblogic][:password]}', 't3://#{node[:weblogic][:admin_console]}')
edit()
startEdit()

ds_name = "#{new_resource.name}"
jndi_name = "#{new_resource.jndi_name}"
jdbc_url = "#{new_resource.jdbc_url}"
ds_password = "#{new_resource.password}"

###
# Create JDBC source
###
try:
  jdbcObject = create(ds_name,'JDBCSystemResource')
except:
  jdbcObject = getMBean('/JDBCSystemResources/' + ds_name)
jdbcBean = jdbcObject.getJDBCResource()
jdbcBean.setName(ds_name)

# set JDBC params
jdbcParams = jdbcBean.getJDBCDataSourceParams()
jdbcParams.setJNDINames(['jdbc/'+jndi_name, jndi_name])

# set Driver params 
jdbcDriverParams = jdbcBean.getJDBCDriverParams()
jdbcDriverParams.setUrl(jdbc_url)
jdbcDriverParams.setDriverName('#{new_resource.driver_name}')
jdbcDriverParams.setPassword(ds_password)

# set Driver properties
p = jdbcDriverParams.getProperties()
drvProps = #{new_resource.driver_props.to_json}
for k in drvProps:
  v = drvProps[k]
  try:
    p1 = p.createProperty(k)
  except:
    p1 = p.lookupProperty(k)
  p1.setValue(v)

# set Connection pool params
cd('/JDBCSystemResources/' + ds_name+ '/JDBCResource/' + ds_name + '/JDBCConnectionPoolParams/' + ds_name)
poolParams= #{new_resource.pool_props.to_json}
for k in poolParams:
  v = poolParams[k]
  p = set(k,v)

# set target
cd('/SystemResources/' + ds_name )
set('Targets',jarray.array([#{new_resource.target.map {|x| "ObjectName('com.bea:Name=#{x},Type=Server')"}.join(',')}], ObjectName))

save()
activate()
exit()
  END
  end
end
