case node["platform_family"]
  when "rhel", "debian"
    include_recipe "weblogic::install_linux"
  when "windows"
    include_recipe "weblogic::install_windows"
end
