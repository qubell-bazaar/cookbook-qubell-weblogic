actions :create

attribute :name, :kind_of => String, :name_attribute => true
attribute :jndi_name, :kind_of => String
attribute :jdbc_url, :kind_of => String
attribute :driver_name, :kind_of => String
attribute :driver_props, :kind_of => Hash # at least { "user" => "username" }
attribute :password, :kind_of => String
attribute :pool_props, :kind_of => Hash, :default => {} # { "TestTableName" => "SQL SELECT 1 FROM DUAL"
attribute :target, :kind_of => Array, :default => []

