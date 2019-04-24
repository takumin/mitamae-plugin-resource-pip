module ::MItamae
  module Plugin
    module Resource
      class Pip < ::MItamae::Resource::Base
        define_attribute :action, default: :present
        define_attribute :cmd, type: [String, Array], default: 'pip'
        define_attribute :name, type: String, default_name: true
        define_attribute :user, type: [String, TrueClass, FalseClass], default: nil
        define_attribute :userbase, type: String, default: nil
        define_attribute :options, type: [String, Array], default: nil
        define_attribute :version, type: String, default: nil

        self.available_actions = [:present, :absent]
      end
    end
  end
end
