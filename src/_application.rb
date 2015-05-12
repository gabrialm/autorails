	# Make lib/assets (custom scss) available to Rails pipeline
	config.assets.paths << Rails.root.join("lib", "assets", "javascripts")
	config.assets.paths << Rails.root.join("lib", "assets", "stylesheets")

	# Prevent auto creation of supporting assets when new controllers are generated
	config.generators do |g|
		g.assets false
	end

	
