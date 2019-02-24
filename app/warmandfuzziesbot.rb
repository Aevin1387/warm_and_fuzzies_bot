#
# file: warmandfuzziesbot.rb
#
require 'telegram/bot'
require 'pq'
require 'pg'
require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: 'warmandfuzzies',
  username: 'fuzzies',
  password: ENV['FUZZIES_PASSWORD']
)

# Set up database tables and columns
ActiveRecord::Schema.define do
  create_table :warm_and_fuzzy_shifts, force: true do |t|
    t.integer "user_id"
    t.datetime "start_time", null: false
    t.datetime "end_time"
    t.integer "chat_id"
  end
end

class WarmAndFuzzyShift < ActiveRecord::Base
end

class WarmAndFuzzyShiftHandler
  attr_reader :token, :client, :message, :chat_id

  def initialize(message)
    @token = ENV['TELEGRAM_API_KEY']
    puts "Initialized with key #{@token}"
    @client = Telegram::Bot::Client.new(@token)
    @message = message
    @chat_id = message.chat.id
  end

  def start_shift
    puts "Running start_shift"
    shift = WarmAndFuzzyShift.create(user_id: @message.from.id, start_time: Time.now, chat_id: @chat_id)
    puts "Sending message #{@message.from.username} has started a shift"
    @client.api.send_message(chat_id: @chat_id, text: "#{@message.from.username} has started a shift")
  end

  def end_shift
    shift = WarmAndFuzzyShift.where(user_id: @message.from.id, end_time: nil).first
    return unless shift
    shift.update(end_time: Time.now)
    shift_length = (shift.end_time - shift.start_time) / 60.0
    @client.api.send_message(chat_id: @chat_id, text: "#{@message.from.username} has ended their shift. Shift length: #{shift_length} minutes")
  end

  def list_shifts
    shifts = WarmAndFuzzyShift.where.not(end_time: nil)
    shift_results = []
    members_cache = {}
    shifts.each do |result|
      member_id = result.user_id
      member = members_cache[member_id]
      unless member
        member_result = @client.api.get_chat_member(chat_id: @chat_id, user_id: result.user_id)['result']
        member = member_result['user']
        members_cache[member_id] = member
      end

      shift_results.push(
        member: member,
        start_time: result.start_time,
        end_time: result.end_time
      )
    end

    shift_results.sort_by! do |result|
      result[:start_time]
    end

    shift_str = ["Finished shifts:"]
    shift_results.each do |result|
      time_diff = (result[:end_time] - result[:start_time]) / 60.0
      shift_str.push("#{result['member']} worked #{time_diff} minutes")
    end
    @client.api.send_message(chat_id: @chat_id, text: shift_str.join("\n"))
  end

  def on_shift
    shifts = WarmAndFuzzyShift.where(end_time: nil)
    on_shift_results = ["Currently on shift:"]
    shifts.each do |results|
      member_result = @client.api.get_chat_member(chat_id: @chat_id, user_id: results.user_id)['result']
      member = member_result['user']
      on_shift_time = Time.at(results.start_time).strftime('%m/%d %H:%M')
      on_shift_results.push("#{member['username']} since #{on_shift_time}")
    end

    @client.api.send_message(chat_id: @chat_id, text: on_shift_results.join("\n"))
  end

end

class WarmAndFuzziesBot
  #
  # message(s) updates from telegram server.
  # put ALL your Telegram Bot logic here.
  #
  def update(data)
    # instantiate a client update object
    update = Telegram::Bot::Types::Update.new(data)

    update_id = update.update_id
    message = update.message
    puts "Message is #{message}"
    puts "Text iss #{message.text}"
    puts "Chat id is #{message.chat.id}"
    puts "User is #{message.from.id}"
    unless message.nil?
      puts "Message is not nil"
      handler = WarmAndFuzzyShiftHandler.new(update.message)
      case message.text
      when /\/start_shift.*/
	puts "Running start_shift"
        handler.start_shift
      when /\/end_shift.*/
        handler.end_shift
      when /\/list_shifts.*/
        handler.list_shifts
      when /\/on_shift.*/
        handler.on_shift
      else
        "Couldnt handle message #{message.text}"
      end
    end
  end
end
