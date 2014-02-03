require 'test_helper'

puts "ActiveRecord #{ActiveRecord::VERSION::STRING}", '-'*80

module Elasticsearch
  module Model
    class ActiveRecordDelegateIntegrationTest < Elasticsearch::Test::IntegrationTestCase

      class Delegated
        def self.name
          "delegated name"
        end
      end

      class ::Article < ActiveRecord::Base
        include Elasticsearch::Model
        include Elasticsearch::Model::Callbacks

        settings index: { number_of_shards: 1, number_of_replicas: 0 } do
          mapping do
            indexes :title,      type: 'string', analyzer: 'snowball'
            indexes :created_at, type: 'date'
          end
        end
      end

      class ::Page < ActiveRecord::Base

        delegate :name, :to => Delegated

      end

      context "Delegation" do
        setup do
          ActiveRecord::Schema.define(:version => 1) do
            create_table :articles do |t|
              t.string   :title
              t.datetime :created_at, :default => 'NOW()'
            end

            create_table :pages do |t|
              t.string   :title
              t.datetime :created_at, :default => 'NOW()'
            end
          end
        end

        should "delegate using the active_support method" do
          page = ::Page.create!(:title => "a page")
          assert_equal "delegated name", page.name
        end

        should "delegate method from Forwardable introduced when using Elasticsearch::Model alters expected rails delegate interface" do
          assert_raises(ArgumentError, "wrong number of arguments (2 for 1)") do 
            Article.delegate :name, :to => Delegated
          end
          # article = ::Article.create!(:title => "an article")
          # assert_equal "delegated name", article.name
        end

      end
    end
  end
end
