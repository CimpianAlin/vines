# encoding: UTF-8

require 'test_helper'
require 'storage/sql_schema'

module Diaspora
  class Application < Rails::Application
    def config.database_configuration
      {
        "development" => {
          "adapter" => "sqlite3",
          "database" => "test.db"
        }
      }
    end
  end
end

describe Vines::Storage::Sql do
  include SqlSchema

  before do
    storage && create_schema(:force => true)
    
    Vines::Storage::Sql::User.new(
      username: "test",
      email: "test@test.de",
      encrypted_password: "$2a$10$c2G6rHjGeamQIOFI0c1/b.4mvFBw4AfOtgVrAkO1QPMuAyporj5e6", # pppppp
      authentication_token: "1234"
    ).save
  end

  after do
    db = Rails.application.config.database_configuration["development"]["database"]
    File.delete(db) if File.exist?(db)
  end
  
  def test_save_user
    fibered do
      db = storage
      user = Vines::User.new(
        jid: 'test@test.de',
        name: 'test@test.de',
        password: 'secret')
      user.roster << Vines::Contact.new(
        jid: 'contact1@domain.tld/resource2',
        name: 'Contact 1')
      db.save_user(user)
      user = db.find_user('test@test.de')
      
      assert (user != nil), "no user found"
      assert_equal "test@test.de", user.jid.to_s
      
      assert_equal 1, user.roster.length
      assert_equal "contact1@domain.tld", user.roster[0].jid.to_s
      assert_equal "Contact 1", user.roster[0].name
    end
  end

  def test_find_user
    fibered do
      db = storage
      user = db.find_user(nil)
      assert_nil user

      user = db.find_user("test@local.host")
      assert (user != nil), "no user found"
      assert_equal "test", user.name

      user = db.find_user(Vines::JID.new("test@local.host"))
      assert (user != nil), "no user found"
      assert_equal "test", user.name

      user = db.find_user(Vines::JID.new("test@local.host/resource"))
      assert (user != nil), "no user found"
      assert_equal "test", user.name
    end
  end

  def test_authenticate
    fibered do
      db = storage

      assert_nil db.authenticate(nil, nil)
      assert_nil db.authenticate(nil, "secret")
      assert_nil db.authenticate("bogus", nil)

      # user credential auth
      pepper = "065eb8798b181ff0ea2c5c16aee0ff8b70e04e2ee6bd6e08b49da46924223e39127d5335e466207d42bf2a045c12be5f90e92012a4f05f7fc6d9f3c875f4c95b"
      user = db.authenticate("test@test.de", "pppppp#{pepper}")
      assert (user != nil), "no user found"
      assert_equal "test", user.name

      # user token auth
      user = db.authenticate("test@test.de", "1234")
      assert (user != nil), "no user found"
      assert_equal "test", user.name
    end
  end

  def test_find_fragment
    skip("not working probably")

    fibered do
      db = storage
      root = Nokogiri::XML(%q{<characters xmlns="urn:wonderland"/>}).root
      bad_name = Nokogiri::XML(%q{<not_characters xmlns="urn:wonderland"/>}).root
      bad_ns = Nokogiri::XML(%q{<characters xmlns="not:wonderland"/>}).root
      
      node = db.find_fragment(nil, nil)
      assert_nil node
      
      node = db.find_fragment('full@wonderland.lit', bad_name)
      assert_nil node
      
      node = db.find_fragment('full@wonderland.lit', bad_ns)
      assert_nil node
      
      node = db.find_fragment('full@wonderland.lit', root)
      assert (node != nil), "node should include fragment"
      assert_equal fragment.to_s, node.to_s
      
      node = db.find_fragment(Vines::JID.new('full@wonderland.lit'), root)
      assert (node != nil), "node should include fragment"
      assert_equal fragment.to_s, node.to_s
      
      node = db.find_fragment(Vines::JID.new('full@wonderland.lit/resource'), root)
      assert (node != nil), "node should include fragment"
      assert_equal fragment.to_s, node.to_s
    end
  end
  
  def test_save_fragment
    skip("not working probably")

    fibered do
      db = storage
      root = Nokogiri::XML(%q{<characters xmlns="urn:wonderland"/>}).root
      db.save_fragment('test@test.de/resource1', fragment)
      node = db.find_fragment('test@test.de', root)
      assert (node != nil), "node should include fragment"
      assert_equal fragment.to_s, node.to_s
    end
  end
end
