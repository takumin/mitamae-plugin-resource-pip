module ::MItamae
  module Plugin
    module ResourceExecutor
      class Pip < ::MItamae::ResourceExecutor::Base
        def apply
          if desired.installed && current.installed
            # nothing...
          elsif desired.installed && !current.installed
            MItamae.logger.debug "#{@resource.resource_type}[#{@resource.resource_name}] desired: #{desired}"
            install(attributes)
          elsif !desired.installed && current.installed
            MItamae.logger.debug "#{@resource.resource_type}[#{@resource.resource_name}] current: #{desired}"
            uninstall(attributes)
          elsif !desired.installed && !current.installed
            # nothing...
          end
        end

        private

        def set_desired_attributes(desired, action)
          case action
          when :present
            desired.installed = true
          when :absent
            desired.installed = false
          end
          desired.user = get_user(attributes.user) if attributes.user
        end

        def set_current_attributes(current, action)
          pip = desired.cmd
          user = desired.user
          base = desired.userbase
          opts = desired.options

          cmd = []
          cmd.concat(get_base(user, base)) if base
          cmd << pip
          cmd << 'freeze'
          cmd << '--user' if user
          cmd.concat(opts) if opts

          pips = {}
          run_command(cmd, user: user).stdout.each_line do |line|
            name, version = line.chomp.split(/==/)
            pips[name] = version
          end

          current.installed = pips.key?(attributes.name)

          if attributes.version
            current.version = pips[attributes.name]
          end
        end

        def install(attributes)
          pip = desired.cmd
          user = desired.user
          base = desired.userbase
          opts = desired.options

          cmd = []
          cmd.concat(get_base(user, base)) if base
          cmd << pip
          cmd << 'install'
          cmd << '--user' if user
          cmd.concat(opts) if opts
          cmd << desired.name

          result = run_command(cmd, user: user)
          unless result.success?
            raise ArgumentError, "stdout: #{result.stdout.inspect} stderr: #{result.stderr.inspect}"
          end
        end

        def uninstall(attributes)
          pip = desired.cmd
          user = desired.user
          base = desired.userbase
          opts = desired.options

          cmd = []
          cmd.concat(get_base(user, base)) if base
          cmd << pip
          cmd << 'uninstall'
          cmd << '-y'
          cmd.concat(opts) if opts
          cmd << desired.name

          result = run_command(cmd, user: user)
          unless result.success?
            raise ArgumentError, "stdout: #{result.stdout.inspect} stderr: #{result.stderr.inspect}"
          end
        end

        def get_base(username, userbase)
          cmd = []

          if userbase.is_a?(String) and !userbase.empty?
            if userbase.match(/^\//)
              base = userbase
            else
              if username.is_a?(String) and !username.empty?
                base = "#{run_specinfra(:get_user_home_directory, username).stdout}/#{userbase}"
              else
                base = nil
              end
            end

            if base
              cmd << 'env'
              cmd << "PYTHONUSERBASE=#{base}"
            end
          end

          cmd
        end

        def get_user(username)
          user = nil

          case username
          when TrueClass, FalseClass
            result = run_command(['printenv', 'SUDO_USER'], user: 'root')
            unless result.success?
              raise ArgumentError, "stdout: #{result.stdout.inspect} stderr: #{result.stderr.inspect}"
            end
            user = result.stdout.chomp
          when String, NilClass
            user = username
          else
            raise ArgumentError, "unknown class: #{username.class}"
          end

          unless run_specinfra(:check_user_exists, user)
            raise ArgumentError, "unknown user: #{result.stdout.chomp}"
          end

          user
        end
      end
    end
  end
end
