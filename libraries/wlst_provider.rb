require 'chef/provider/script'

class Chef
  class Provider
    class Wlst < Chef::Provider::Script
      
      def interpreter
        if node.platform_family?("windows")
          ::File.join(@new_resource.weblogic_home, "common", "bin", "wlst.cmd")
        else
          ::File.join(@new_resource.weblogic_home, "common", "bin", "wlst.sh")
        end
      end

      def weblogic_home
        @new_resource.weblogic_home
      end

      def action_run
        if sentinel_file = sentinel_file_if_exists
          Chef::Log.debug("#{@new_resource} sentinel file #{sentinel_file} exists - nothing to do")
          return false
        end

        script_file.puts(@code)
        script_file.close

        set_owner_and_group        

        command = @new_resource.command("\"#{interpreter}\" #{flags} \"#{script_file.path}\"")
        if !node.platform_family?("windows")
          command = "runuser -l #{@new_resource.user} -c '#{command}'" if @new_resource.user
        end
        converge_by("execute #{command}") do
          Chef::Log.debug("#{@new_resource} executing: #{command}")
          if @new_resource.environment
            result = system(@new_resource.environment,command)
          else
            result = system(command)
          end
          raise RuntimeError, "wlst_script[#{@new_resource.name}] failed to execute" unless result
          Chef::Log.info("#{@new_resource} ran successfully")
        end
        converge_by(nil) do
          # ensure script is unlinked at end of converge!
          unlink_script_file
        end
      end

      private

      def sentinel_file_if_exists
        if sentinel_file = @new_resource.creates
          relative = Pathname(sentinel_file).relative?
          cwd = @new_resource.cwd
          if relative && !cwd
            Chef::Log.warn "You have provided relative path for execute#creates (#{sentinel_file}) without execute#cwd (see CHEF-3819)"
          end

          if ::File.exists?(sentinel_file)
            sentinel_file
          elsif cwd && relative
            sentinel_file = ::File.join(cwd, sentinel_file)
            sentinel_file if ::File.exists?(sentinel_file)
          end
        end
      end

    end
  end
end
