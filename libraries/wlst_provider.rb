require 'chef/provider'


class Chef
    class Provider
        class WlstScript < Chef::Provider
            include Chef::Mixin::ShellOut

            def load_current_resource
              Gem.clear_paths
              @current_resource = Chef::Resource::WlstScript.new(@new_resource.name)
              @current_resource
            end

            def action_run
            	Chef::Provider.send(:include, Windows::Helper) if node.platform_family?("windows")
                #include Windows::Helper
                paths = [
                  "#{node[:weblogic][:bea_home]}/patch_wls1036/profiles/default/sys_manifest_classpath/weblogic_patch.jar",
                  "#{node[:weblogic][:bea_home]}/patch_ocp371/profiles/default/sys_manifest_classpath/weblogic_patch.jar",
                  "#{node[:weblogic][:jrockit_home]}/lib/tools.jar",
                  "#{node[:weblogic][:weblogic_home]}/server/lib/weblogic_sp.jar",
                  "#{node[:weblogic][:weblogic_home]}/server/lib/weblogic.jar",
                  "#{node[:weblogic][:bea_home]}/modules/features/weblogic.server.modules_10.3.6.0.jar",
                  "#{node[:weblogic][:weblogic_home]}/server/lib/webservices.jar",
                  "#{node[:weblogic][:bea_home]}/modules/org.apache.ant_1.7.1/lib/ant-all.jar",
                  "#{node[:weblogic][:bea_home]}/modules/net.sf.antcontrib_1.1.0.0_1-0b2/lib/ant-contrib.jar"
                ]
                
                paths.map! { |x| win_friendly_path(x) } if node.platform_family?("windows")

                default_env = {
                        "CLASSPATH" => paths.join(":"),
                        "LD_LIBRARY_PATH" => "#{node[:weblogic][:weblogic_home]}/server/native/linux:#{node[:weblogic][:weblogic_home]}/server/native/linux/x86_64",
                }
                run_env = @new_resource.environment.merge(default_env)
                result = system(
                                run_env,
                                case node[:platform_family]
                                when "windows"
                                  "#{node[:weblogic][:weblogic_home]}/common/bin/wlst.cmd -i #{@new_resource.script} > #{@new_resource.log}"
                                when "rhel", "debian"
                                  "java -Dweblogic.security.allowCryptoJDefaultJCEVerification=false weblogic.WLST -i #{@new_resource.script} > #{@new_resource.log}"
                                end
                               )
                unless result
                    raise RuntimeError, "wlst_script[#{@new_resource.name}] failed to execute"  
                end
                Chef::Log.info("wlst_script[#{@new_resource.name}] ran successfully")
            end
        end
    end
end
