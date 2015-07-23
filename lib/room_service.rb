require 'active_support/inflector'
require 'room_service/version'

module RoomService
  def try_require_for_const(const_name, path)
    require path

    const_defined?(const_name)
  rescue Exception
    false
  end

  def try_to_install_gem(gem_name)
    gems_installed = Gem.install(gem_name)

    gem = gems_installed.first
    gem_version = gem.version

    gemfile_entry = "gem '#{gem_name}', '#{gem_version}'"
    File.open('Gemfile', 'a') { |file| file.write "\n#{gemfile_entry}" }

    gem.activate rescue nil

    system 'bundle > /dev/null 2>&1'
  rescue Exception
    false
  end

  def const_missing(const_name)
    catch(:found) do
      standard_require_path = ActiveSupport::Inflector.underscore(const_name.to_s)
      nonstandard_but_annoyingly_common_require_path = standard_require_path.gsub(/_/, '')

      throw :found if try_require_for_const(const_name, standard_require_path)
      throw :found if try_require_for_const(const_name, nonstandard_but_annoyingly_common_require_path)

      if try_to_install_gem(standard_require_path) || try_to_install_gem(nonstandard_but_annoyingly_common_require_path)
        throw :found if try_require_for_const(const_name, standard_require_path)
        throw :found if try_require_for_const(const_name, nonstandard_but_annoyingly_common_require_path)
      end

      super(const_name)
    end

    const_get(const_name)
  rescue Exception
    super(const_name)
  end
end

Module.prepend(RoomService)