# Attributes specific to default WebLogic domain
default[:weblogic][:username] = "weblogic" # Just for reference, cannot be changed in Domain template
default[:weblogic][:password] = ""
default[:weblogic][:domain_name] = "Default"
default[:weblogic][:admin_console] = "localhost:7001"
default[:weblogic][:admin_server][:arguments] = [
  "-DAdminServer=true",
  "-Xms256m",
  "-Xmx512m",
  "-XX:MaxPermSize=256m",
  "-Djava.net.preferIPv4Stack=true"
]

case node[:weblogic][:version]
when "12"
  default[:weblogic][:domain_template] = ::File.join(node[:weblogic][:weblogic_home], "common", "templates", "wls", "wls.jar")
  default[:weblogic][:nodemanager_home] = ::File.join(node[:weblogic][:domain_home], node[:weblogic][:domain_name], "nodemanager")
else
  default[:weblogic][:domain_template] = ::File.join(node[:weblogic][:weblogic_home], "common", "templates", "domains", "wls.jar")
  default[:weblogic][:nodemanager_home] = ::File.join(node[:weblogic][:domain_home], "common", "nodemanager")
end

# Not used yet
default[:weblogic][:port] = 7001
