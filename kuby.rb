require "active_support/core_ext"
require "active_support/encrypted_configuration"
require 'kuby/digitalocean'
require 'kuby/sidekiq'

# Define a production Kuby deploy environment
Kuby.define("App") do
  environment(:production) do
    # Because the Rails environment isn't always loaded when
    # your Kuby config is loaded, provide access to Rails
    # credentials manually.
    app_creds = ActiveSupport::EncryptedConfiguration.new(
      config_path: File.join("config", "credentials.yml.enc"),
      key_path: File.join("config", "master.key"),
      env_key: "RAILS_MASTER_KEY",
      raise_if_missing_key: true
    )

    docker do
      # Configure your Docker registry credentials here. Add them to your
      # Rails credentials file by running `bundle exec rake credentials:edit`.
      credentials do
        username app_creds[:DIGITALOCEAN_API_TOKEN]
        password app_creds[:DIGITALOCEAN_API_TOKEN]
      end

      # distro :alpine

      # Configure the URL to your Docker image here, eg:
      image_url "registry.digitalocean.com/fedicom/sample-app"
    end

    kubernetes do
      # Add a plugin that facilitates deploying a Rails app.
      add_plugin :rails_app do
        hostname "bysite.me"

        manage_database false

        env do
          data do
            add "DATABASE_URL", app_creds[:DATABASE_URL]
          end
        end
      end

      add_plugin(:sidekiq) do
        replicas 2
      end

      provider :digitalocean do
        access_token app_creds[:DIGITALOCEAN_API_TOKEN]
        cluster_id "001a0275-6469-44d8-9d0c-208b0455e3e5"
      end
    end
  end
end
