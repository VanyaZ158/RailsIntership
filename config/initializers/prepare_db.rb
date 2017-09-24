# Create hashes for all tables

DbManager.instance[Book.table_name] = {}
IndexManager.instance[Book.table_name] = {}

DbManager.instance[PublishingHouse.table_name] = {}
IndexManager.instance[PublishingHouse.table_name] = {}

# If environment is development, seed database.
if Rails.env.development?
  100.times do
    params_array = []
    ph = PublishingHouse.create(name: Faker::Book.publisher)

    100.times do
      params = {
        title: Faker::Book.title,
        description: Faker::Lorem.sentence,
        author: Faker::Book.author,
        publishing_house_id: ph.id
      }

      params_array << params
    end

    Book.create(params_array)
  end
end
