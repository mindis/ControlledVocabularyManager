namespace :admin_user do
  task :create do
    unless Rails.env == "production"
      User.create(:email => "admin@opaquenamespace.org", :name => "admin", :password => "admin123", :institution => "University of Oregon", :role => "admin")
    end
  end
end
