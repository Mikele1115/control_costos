require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ControlCostos
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # --- Idioma ---------------------------------------------------
    config.i18n.default_locale = :es
    config.i18n.available_locales = [ :es, :en ]
    # Permite organizar las traducciones en subdirectorios
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]

    # --- Zona horaria ---------------------------------------------
    # Tu sistema esta en UTC-3. Ajusta la ciudad si no es la tuya:
    # "Buenos Aires", "Montevideo", "Santiago"...
    config.time_zone = "Buenos Aires"
  end
end
