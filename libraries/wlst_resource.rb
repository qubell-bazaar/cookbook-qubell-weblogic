require 'chef/resource/script'

class Chef
  class Resource
    class Wlst < Chef::Resource::Script

      def initialize(name, run_context=nil)
        super
        @resource_name = :wlst
        #@flags = "-i"
        @provider = Chef::Provider::Wlst
      end

      def weblogic_home(arg=nil)
        set_or_return(
          :weblogic_home,
          arg,
          :kind_of => String,
          :required => true
        )
      end

    end
  end
end
