# Manage Database Records via this singleton.
class DbManager
  include Singleton

  DUMP_PATH = Rails.root.join('tmp', 'dumped.db').freeze
  DUMPED_TABLES = [PublishingHouse.table_name, Book.table_name].freeze

  def initialize
    @data_mappers = Hash.new { |hash, table_name| hash[table_name] = '' }
  end

  def dump_to_file
    packed_arr = []
    DUMPED_TABLES.each { |key| packed_arr << @data_mappers[key].size }

    File.open(DUMP_PATH, 'wb+') do |file|
      file.write(packed_arr.pack('L*'))
      DUMPED_TABLES.each { |key| file.write(@data_mappers[key]) }
    end
  end

  def load_dump
    return unless File.exist? DUMP_PATH

    File.open(DUMP_PATH, 'rb') do |file|
      tables_length = file.read(DUMPED_TABLES.size * 4).unpack('L*')

      DUMPED_TABLES.each_with_index do |key, index|
        @data_mappers[key] = file.read(tables_length[index])
        key.classify.constantize.fully_refresh_index
      end
    end
  end

  delegate :[], :[]=, to: :@data_mappers
end
