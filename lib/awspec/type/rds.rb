module Awspec::Type
  class Rds < Base
    def initialize(id)
      super
      @resource = find_rds(id)
      @id = @resource[:db_instance_identifier] if @resource
    end

    STATES = %w(
      available backing-up creating deleting
      failed inaccessible-encryption-credentials
      incompatible-credentials incompatible-network
      incompatible-option-group incompatible-parameters
      incompatible-restore maintenance
      modifying rebooting renaming resetting-master-credentials
      restore-error storage-full upgrading
    )

    STATES.each do |state|
      define_method state.tr('-', '_') + '?' do
        @resource[:db_instance_status] == state
      end
    end

    def vpc_id
      @resource[:db_subnet_group][:vpc_id]
    end

    def has_security_group?(sg_id)
      return true if has_vpc_security_group_id?(sg_id)
      return true if has_vpc_security_group_name?(sg_id)
      return true if has_vpc_security_group_tag_name?(sg_id)
      return true if has_db_security_group_name?(sg_id)
    end

    def has_db_parameter_group?(name)
      pgs = @resource[:db_parameter_groups]
      pgs.find do |pg|
        pg[:db_parameter_group_name] == name
      end
    end

    def has_option_group?(name)
      ogs = @resource[:option_group_memberships]
      ogs.find do |og|
        og[:option_group_name] == name
      end
    end

    private

    def has_vpc_security_group_id?(sg_id)
      sgs = @resource[:vpc_security_groups]
      sgs.find do |sg|
        sg[:vpc_security_group_id] == sg_id
      end
    end

    def has_vpc_security_group_name?(sg_id)
      sgs = @resource[:vpc_security_groups]
      res = @ec2_client.describe_security_groups({
                                                   filters: [{ name: 'group-name', values: [sg_id] }]
                                                 })
      return false unless res[:security_groups].count == 1
      sgs.find do |sg|
        sg[:vpc_security_group_id] == res[:security_groups][0][:group_id]
      end
    end

    def has_vpc_security_group_tag_name?(sg_id)
      sgs = @resource[:vpc_security_groups]
      res = @ec2_client.describe_security_groups({
                                                   filters: [{ name: 'tag:Name', values: [sg_id] }]
                                                 })
      return false unless res[:security_groups].count == 1
      sgs.find do |sg|
        sg[:vpc_security_group_id] == res[:security_groups][0][:group_id]
      end
    end

    def has_db_security_group_name?(sg_id)
      sgs = @resource[:db_security_groups]
      sgs.find do |sg|
        sg[:db_security_group_name] == sg_id
      end
    end
  end
end
