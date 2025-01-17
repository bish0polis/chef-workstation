## Rubygems Customization ##
# Customize rubygems install behavior and locations to keep user gems isolated
# from the stuff we bundle with omnibus and any other ruby installations on the
# system.

# Always install and update new gems in "user install mode"
Gem::ConfigFile::OPERATING_SYSTEM_DEFAULTS["install"] = "--user"
Gem::ConfigFile::OPERATING_SYSTEM_DEFAULTS["update"] = "--user"

# We will inject our hacks in if the user will allow it.
begin
  if ENV["CHEFDK_ENV_FIX"] != "0" && ENV["CHEFWS_ENV_FIX"] != "0"
    # TODO remove support for CHEFDK_ENV_FIX as part of 1.0 bump
    require "env_customization"
  end
rescue
  nil
end

module Gem

  ##
  # Override user_dir to live inside of ~/.chefdk

  def self.user_dir
    chefdk_home_set = !([nil, ""].include? ENV["CHEFDK_HOME"])
    # We call expand_path here because it converts \ -> /
    # Rubygems seems to require that we not use \
    default_home = File.join(File.expand_path(ENV["LOCALAPPDATA"]), "chefdk")

    chefdk_home = if chefdk_home_set
                    ENV["CHEFDK_HOME"]
                  else
                    old_home = File.join(Gem.user_home, ".chefdk")
                    if File.exist?(old_home)
                      Gem.ui.alert_warning <<-EOF

        Chef Workstation now defaults to using #{default_home} instead of #{old_home}.
        Since #{old_home} exists on your machine, Chef Workstation will continue
        to make use of it. Please set the environment variable CHEFDK_HOME (yea, sorry about that)
        to #{old_home} to remove this warning. This warning will be removed
        in the next major version bump of Chef Workstation.
                      EOF
                      old_home
                    else
                      default_home
                    end
                  end

    # Prevents multiple warnings
    ENV["CHEFDK_HOME"] = chefdk_home

    parts = [chefdk_home, "gem", ruby_engine]
    parts << RbConfig::CONFIG["ruby_version"] unless RbConfig::CONFIG["ruby_version"].empty?
    File.join parts
  end

end

# :DK-BEG: override 'gem install' to enable RubyInstaller DevKit usage
Gem.pre_install do |gem_installer|
  win_install_dir = "C:\\opscode\\chef-workstation"
  unless gem_installer.spec.extensions.empty?
    unless ENV["PATH"].include?("#{win_install_dir}\\embedded\\mingw\\bin")
      Gem.ui.say "Temporarily enhancing PATH to include DevKit..." if Gem.configuration.verbose
      ENV["PATH"] = "#{win_install_dir}\\embedded\\bin;#{win_install_dir}\\embedded\\mingw\\bin;#{ENV["PATH"]}"
    end
    ENV["RI_DEVKIT"] = "#{win_install_dir}\\embedded"
    ENV["CC"] = "gcc"
    ENV["CXX"] = "g++"
    ENV["CPP"] = "cpp"
  end
end
# :DK-END:
