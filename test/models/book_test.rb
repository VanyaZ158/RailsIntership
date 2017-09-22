require 'test_helper'

class BookTest < ActiveSupport::TestCase
  setup do
    DbManager.instance[Book.table_name] = {}
    IndexManager.instance[Book.table_name] = {}
  end

  test 'create book' do
    book = new_book
    book.save

    assert_equal book.object_id, book.id
    assert_equal 1, Book.all.size
  end

  test 'create few books' do
    create_books

    assert_equal 10, Book.all.size
  end

  test 'find book_by id' do
    create_books
    existed_id = Book.managed_data.keys[0]
    not_existed_id = 'not_existed'

    existed_book = Book.find existed_id
    not_existed_book = Book.find not_existed_id

    assert_not_nil existed_book
    assert_not_nil Book.managed_data[existed_book.id]

    assert_nil not_existed_book
  end

  test 'find books_by ids' do
    create_books
    ids = Book.managed_data.keys[1..3]

    books = Book.find(ids)
    assert_equal ids.length, books.length
  end

  test 'update book' do
    book = new_book
    book.save

    title = 'New book'
    book.update(title: title)

    assert_not_nil book.description
    assert_not_nil book.author

    assert_equal book.object_id, book.id
    assert_equal title, book.title

    assert_equal title, Book.managed_data[book.object_id][:title]
  end

  test 'update book through attrs' do
    book = new_book
    book.save

    title = 'New title'

    book.title = title
    book.update

    assert_not_nil book.description
    assert_not_nil book.author

    assert_equal book.object_id, book.id
    assert_equal title, book.title

    assert_equal title, Book.managed_data[book.object_id][:title]
  end

  test 'delete book' do
    create_books
    id = Book.managed_data.keys[0]

    book = Book.find(id)
    book.delete

    assert_nil book.id
    assert_equal false, book.delete
    assert_nil Book.managed_data[id]
  end

  test 'select one book with title' do
    create_books
    id = Book.managed_data.keys[0]

    book = Book.find(id)
    where_book, = Book.select_where(title: book.title)

    assert_equal book.id, where_book.id
  end

  test 'select one book with author, description' do
    create_books
    id = Book.managed_data.keys[0]

    book = Book.find(id)
    select_params = { description: book.description, author: book.author }
    where_book, = Book.select_where(select_params)

    assert_equal book.id, where_book.id
  end

  test 'create book with empty data' do
    bad_book = Book.new

    assert_not bad_book.save
  end

  test 'play with pagination' do
    create_books 1000

    paginated_books = Book.all.page
    nil_paginated = Book.all.page 1000

    assert_equal 20, paginated_books.length
    assert_nil nil_paginated
  end

  test 'insert book, check fields indexed' do
    book = new_book
    book.save

    assert_equal book.id, Book.managed_index[:title][book.title][0]
    assert_equal book.id, Book.managed_index[:author][book.author][0]
  end

  test 'update book, check fields indexed' do
    create_books
    book = Book.all[1]
    new_title = 'My title'

    book.update(title: new_title)

    assert Book.managed_index[:title][book.title].include? book.id
    assert Book.managed_index[:author][book.author].include? book.id
  end

  test 'delete book, check indexes deleted' do
    create_books
    book = Book.all[1]
    id = book.id

    book.delete

    assert_not Book.managed_index[:title][book.title].include? id
    assert_not Book.managed_index[:author][book.author].include? id
  end

  test 'delete book with changed data, check indexed' do
    create_books
    book = Book.all[1]
    id = book.id
    author = book.author

    book.author = 'Another Author'
    book.delete

    assert_not Book.managed_index[:title][book.title].include? id
    assert_not Book.managed_index[:author][author].include? id
  end

  test 'get ids from indexed fields' do
    create_books { |item| item[:title] = 'MyTitle' }
    create_books

    with_index_books = Book.index_where(title: 'MyTitle')

    assert_equal 10, with_index_books.length
  end

  test 'get not existed field in index' do
    create_books
    title = 'MyNotExistedTitle'

    with_index_books = Book.index_where(title: title)

    assert_empty with_index_books
  end

  private

  def book_params
    {
        title: Faker::Book.title,
        description: Faker::Book.genre,
        author: Faker::Book.author
    }
  end

  def new_book
    Book.new(book_params)
  end

  def create_books(number = 10)
    params_array = []
    number.times do
      params = book_params

      yield params if block_given?
      params_array << params
    end

    Book.create(params_array)
  end
end
