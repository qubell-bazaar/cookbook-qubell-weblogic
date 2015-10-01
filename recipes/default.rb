case node["platform_family"]
 when "rhel"
  include_recipe "weblogic::rhel"
 when "windows"
  include_recipe "weblogic::windows"
end
