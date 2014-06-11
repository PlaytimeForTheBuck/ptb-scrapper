# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140611235016) do

  create_table "games", force: true do |t|
    t.string   "name"
    t.datetime "launch_date"
    t.integer  "meta_score"
    t.text     "positive_reviews"
    t.text     "negative_reviews"
    t.float    "price"
    t.float    "sale_price"
    t.datetime "reviews_updated_at"
    t.datetime "game_list_updated_at"
    t.datetime "game_updated_at"
    t.text     "categories"
    t.integer  "os_flags",             default: 0, null: false
    t.integer  "features_flags",       default: 0, null: false
  end

  create_table "prices", force: true do |t|
    t.datetime "date"
    t.float    "price"
    t.float    "sale_price"
    t.integer  "game_id"
  end

  add_index "prices", ["game_id"], name: "index_prices_on_game_id"

end
