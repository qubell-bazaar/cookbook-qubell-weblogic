default[:weblogic][:install][:jar] = ""
case node.platform_family
when "rhel"
  default[:weblogic][:root_dir] = "/opt"
  default[:weblogic][:classpath_sep] = ":"
when "windows"
  default[:weblogic][:root_dir] = "Z:/"
  default[:weblogic][:classpath_sep] = ";"
end

default[:weblogic][:install_dir] = ::File.join(node[:weblogic][:root_dir], "install_files")
default[:weblogic][:middleware_home] = ::File.join(node[:weblogic][:root_dir], "middleware")
default[:weblogic][:weblogic_home] = ::File.join(node[:weblogic][:middleware_home], "wlserver")
default[:weblogic][:domain_home] = ::File.join(node[:weblogic][:middleware_home], "domains")

default[:weblogic][:datasource] = {}

default[:weblogic][:version] = "10"

case node[:weblogic][:install][:jar]
when /1036/
  node.set[:weblogic][:version] = "10"
when /1212/
  node.set[:weblogic][:version] = "12"
end

