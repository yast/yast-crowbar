require "yast/rake"

Yast::Tasks.submit_to :sle15sp1

Yast::Tasks.configuration do |conf|
  #lets ignore license check for now
  conf.skip_license_check << /.*/
  # do not submit anywhere, it's maintained only for the SUSE Cloud product
  conf.obs_sr_project = nil
end
