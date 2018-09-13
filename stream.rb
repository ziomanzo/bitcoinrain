require 'socket'
require_relative 'lib/bitcoin.rb'

# 0. Connect to bitcoin server port
puts "Connecting to the internets!"
socket = Bitcoin.connect('46.19.137.74')
puts "Welcome to the Bitcoin Network: #{socket.inspect}"

# 1. Handshake (also made convenience function `socket.handshake` if you like)
socket.handshake
# i. send version
# version = Bitcoin::Protocol::Message.version # create a version message to send
# socket.write version.binary # Send binary across the wire
# puts "version->"

# # ii. get the version
# message = socket.gets
# puts "<-#{message.type}"

# # iii. get the verack
# message = socket.gets
# puts "<-#{message.type}"

# # iv. reply to verack
# verack = Bitcoin::Protocol::Message.new('verack') # "F9BEB4D9 76657261636b000000000000 00000000 5df6e0e2"
# socket.write verack.binary
# puts "verack->"


# 2. Receive Messages
loop do

  message = socket.gets
  puts "<-#{message.type}"
  # puts message.payload

  # 3. Respond to pings (keeps connection alive)
  if message.type == 'ping' # 70696E670000000000000000
    puts "pong->"
    pong = Bitcoin::Protocol::Message.new('pong', message.payload) # reply with ping's payload
    socket.write pong.binary
  end

  # 4. Respond to invs (with getdata (to get txs...))
  if message.type == 'inv'
    #puts message.payload

    # Segwit - Must explicitly ask for witness data by changing the inv types used in getdata
    message.payload.gsub!("01000000", "01000040") # MSG_WITNESS_TX
    message.payload.gsub!("02000000", "02000040") # MSG_WITNESS_BLOCK
    # https://github.com/bitcoin/bips/blob/master/bip-0144.mediawiki#relay

    puts " getdata->"
    getdata = Bitcoin::Protocol::Message.new('getdata', message.payload)
    socket.write getdata.binary
  end

  # 5. Receive txs (in response to our getdata)
  if message.type == 'tx'
    # Decode tx to json
    if message.payload.length < 6000 # FIX: Argument list too long - decoderawtransaction
      json = `decoderawtransaction #{message.payload}`
      # puts json
    end
  end

end

# <-version
# <-verack
# verack->

# <-alert
# <-ping
#   pong->
# <-addr
# <-getheaders

# <-inv
#   getdata->
#     <-tx
# ...
