defmodule Server do
  use Application

  def start(_type, _args) do
    IO.puts("Server starting on ports 13001")
    Task.start_link(Router, :start, [13001])
    Task.start_link(TCPServer, :start, [13001])
  end
end

defmodule Router do
	# My router stored in a global variable for ease
	@my_router :my_awesome_router;

	# Start the server with a custom port.
	# A port must be entered as of right now
	# because there are issues with reusing ports.
	def start(port) do
		# Create a new Router process and start the
		# TCP server but ONLY if there isn't already one.
    r = 0
		:global.trans({@my_router, @my_router},
			fn ->
				case :global.whereis_name(@my_router) do
					:undefined ->
						pid = spawn(Router, :route_message, [%{}])
						:global.register_name(@my_router, pid)
					_	-> :ok
				end
			end);
      IO.inspect r
	end

	# Stop the Router process
	def stop() do
		# If our Router process exists, then shut it down
		:global.trans({@my_router, @my_router},
		fn ->
			case :global.whereis_name(@my_router) do
				:undefined -> :ok
				_	->
					:global.send @my_router, {:shutdown}
			end
		end)
	end

	# Send a message to the Router to add a new client to the Map.
	def register_nickname(nickname, client_socket) do
		IO.puts "Client Registered: #{nickname}";
		:global.send @my_router, { :register_nickname, nickname, client_socket };
	end

	# Send a message to the Router to remove a client from the Map.
	def unregister_nickname(nickname) do
		IO.puts "Client Unregistered: #{nickname}";
		:global.send @my_router, { :unregister_nickname, nickname };
	end

	# Pass on the addresseeName and message to the Router
	# so that it can pass it on to the correct client.
	def send_chat_message_to(addresseeName, message) do
		:global.send @my_router, {:send_chat_message_to, addresseeName, message}
	end

	# Pass the x and y values to the Router to
	# set the position of the "addresseeName" client.
	def set_position_to(x, y, addresseeName) do
		:global.send @my_router, {:set_position_to, addresseeName, x, y}
	end

	# Pass the addresseeName to the Router so
	# that the other players can be aware of the state (in game when sent)
	def waiting_challenge(addresseeName) do
		:global.send @my_router, {:waiting_challenge, addresseeName}
	end
	def cancel_challenge(addresseeName) do
		:global.send @my_router, {:cancel_challenge, addresseeName}
	end
	def challenge(addresseeName, opponentName) do
		:global.send @my_router, {:challenge, addresseeName, opponentName}
	end

	# Pass choice so that it can be stored and used
	# later to decide the winner of a match
	def choice(choiceRPS, addresseeName) do
		:global.send @my_router, {:choice, addresseeName, choiceRPS}
	end

	# Pass message and sender to send back a message
	# which looks like "A sent: hello world"
	def send_global(addresseeName, message) do
		:global.send @my_router, {:send_global, addresseeName, message}
	end

	# Pass addresseeName so the server can send the initialisation
	# data back to the client (addresseeName)
	# This includes every player's position and state
	def initialisation(addresseeName) do
			:global.send @my_router, {:initialisation, addresseeName}
	end

	# Pass the x and y values to the Router to
	# update the position of the client by adding the
	# new quantities onto the existing position.
	def update_position_by(x, y, addresseeName) do
		:global.send @my_router, {:update_position_by, addresseeName, x, y}
	end

	# Send a message to the Router to display all of the
	# player's positions.
	def print_positions(addresseeName) do
		:global.send @my_router, {:print_positions, addresseeName}
	end

	# Router Loop, clients being a Map of the registered clients.
	def route_message(clients) do
		receive do

			# Add a client to the Map
			{:register_nickname, nickname, client_socket}	->

				# Output to Client
				binary_to_send = "REGISTERED: #{nickname}\n"
				:ok = :gen_tcp.send(client_socket, binary_to_send);

				route_message(Map.put_new(clients, nickname, [client_socket: client_socket, client_position: {0,0}, current_choice: "-1", opponent_name: "", score: 0, current_state: 0]));

			# Remove client from the Map
			{:unregister_nickname, nickname}	->
				# Stop the client loop
				case Map.get(clients, nickname) do
					nil ->
						IO.puts "Addressee #{nickname} unkown.";
					clientvalue ->
						# Output to Client
						binary_to_send = "UNREGISTERED: #{nickname}\n"
						:gen_tcp.send(clientvalue[:client_socket], binary_to_send);

						# Send "Leave" to all players except self to delte from their view
						for {client2_key, client2_value} <- clients do

							if (client2_value[:client_socket] != clientvalue[:client_socket]) do
								# Output to client
								binary_to_send2 = "LEAVE:#{nickname}:\n"
								:gen_tcp.send(client2_value[:client_socket], binary_to_send2);
							end
						end

						#send clientvalue[:client_socket], {:stop};
				end

				route_message(Map.delete(clients, nickname));

			# Send a chat message to the client if they are registered in
			# the map.
			{:send_chat_message_to, addresseeName, message}	->
				case Map.get(clients, addresseeName) do
					nil ->
						IO.puts "Addressee #{addresseeName} unkown.";
					clientvalue ->

						# Output to Client
						binary_to_send = "RECEIVED_CHAT_MESSAGE: #{message}\n"
						:gen_tcp.send(clientvalue[:client_socket], binary_to_send);
				end

				route_message(clients);

			# Set the position of a client to position {x, y}
			# (if they are registered in the map)
			{:set_position_to, addresseeName, x, y}	->
					clients = case Map.get(clients, addresseeName) do
											nil ->
												IO.puts "Addressee #{addresseeName} unkown.";
												clients;
											clientvalue ->


												clients = Map.put(clients, addresseeName, [client_socket: clientvalue[:client_socket], client_position: {x, y}, current_choice: clientvalue[:current_choice], opponent_name: clientvalue[:opponent_name], score: clientvalue[:score], current_state: clientvalue[:current_state]]);
					end


					case Map.get(clients, addresseeName) do
							nil ->
									IO.puts "Addressee #{addresseeName} unkown.";
									clients;
							clientvalue ->

							for {client2_key, client2_value} <- clients do

								if (client2_value[:client_socket] != clientvalue[:client_socket]) do
									# Output to client
									{c, d} = clientvalue[:client_position];
									binary_to_send = "UPDATEPOS:#{addresseeName}:#{c}:#{d}\n"
									:gen_tcp.send(client2_value[:client_socket], binary_to_send);
								end
							end
					end

					route_message(clients);

			# Update the client's (if they are registered) current position
			# by setting the position to be the sum of the current position
			# and the x & y values.
			{:update_position_by, addressee, x, y}	->
						clients = case Map.get(clients, addressee) do
												nil ->
														IO.puts "Addressee #{addressee} unkown.";
														clients;
												clientvalue ->
														{a, b} = clientvalue[:client_position];
														newPosition = {a + x, b + y};

														clients = Map.put(clients, addressee, [client_socket: clientvalue[:client_socket], client_position: newPosition, current_choice: clientvalue[:current_choice], opponent_name: clientvalue[:opponent_name], score: clientvalue[:score], current_state: clientvalue[:current_state]]);
												end

						case Map.get(clients, addressee) do
								nil ->
										IO.puts "Addressee #{addressee} unkown.";
										clients;
								clientvalue ->

								for {client2_key, client2_value} <- clients do

											# TODO: Need this if statrement when sending message ot all, dont want to send to out own!!
											if (client2_value[:client_socket] != clientvalue[:client_socket]) do
													{c, d} = clientvalue[:client_position];
													binary_to_send = "UPDATEPOS:#{addressee}:#{c}:#{d}\n";
													:gen_tcp.send(client2_value[:client_socket], binary_to_send);
											end
								end
						end

						route_message(clients);

		 # Loop through all of the clients twice so that the client
		 # will receive all of the other client's positions (including their own).
		 {:print_positions, addresseeName}	->

			 case Map.get(clients, addresseeName) do
				 nil ->
					 IO.puts "Addressee #{addresseeName} unkown.";
				 clientvalue ->

					 for {client2_key, client2_value} <- clients do

					 			if (client2_value[:client_socket] != clientvalue[:client_socket]) do
							 # Output to Client
							 {x, y} = client2_value[:client_position];
							 binary_to_send = "UPDATEPOS:#{client2_key}:#{x}:#{y}:\n"
						 :gen_tcp.send(clientvalue[:client_socket], binary_to_send);
						 end
					 end
			 	end

				route_message(clients);

		# Simple message send so that the other players are aware of the new state
		{:waiting_challenge, addresseeName} ->

			clients = case Map.get(clients, addresseeName) do
									nil ->
											IO.puts "Addressee #{addresseeName} unkown.";
											clients;
									clientvalue ->
											clients = Map.put(clients, addresseeName, [client_socket: clientvalue[:client_socket], client_position: clientvalue[:client_position], current_choice: clientvalue[:current_choice], opponent_name: clientvalue[:opponent_name], score: clientvalue[:score], current_state: 1]);
									end

			case Map.get(clients, addresseeName) do
					nil ->
							IO.puts "Addressee #{addresseeName} unkown.";
							clients;
					clientvalue ->

					for {client2_key, client2_value} <- clients do
								if (client2_value[:client_socket] != clientvalue[:client_socket]) do
										# Output to Client
										binary_to_send = "WAITING_CHALLENGE:#{addresseeName}:\n"
										:gen_tcp.send(client2_value[:client_socket], binary_to_send);
								end
					end
			end

			route_message(clients);
		{:cancel_challenge, addresseeName} ->

				clients = case Map.get(clients, addresseeName) do
										nil ->
												IO.puts "Addressee #{addresseeName} unkown.";
												clients;
										clientvalue ->
												clients = Map.put(clients, addresseeName, [client_socket: clientvalue[:client_socket], client_position: clientvalue[:client_position], current_choice: clientvalue[:current_choice], opponent_name: "", score: clientvalue[:score], current_state: 0]);
										end

			case Map.get(clients, addresseeName) do
					nil ->
							IO.puts "Addressee #{addresseeName} unkown.";
							clients;
					clientvalue ->

					for {client2_key, client2_value} <- clients do
								if (client2_value[:client_socket] != clientvalue[:client_socket]) do
										# Output to Client
										binary_to_send = "CANCEL_CHALLENGE:#{addresseeName}:\n"
										:gen_tcp.send(client2_value[:client_socket], binary_to_send);
								end
					end
			end

			route_message(clients);
		{:challenge, addresseeName, opponentName} ->

				clients = case Map.get(clients, addresseeName) do
											nil ->
													IO.puts "Addressee #{addresseeName} unkown.";
													clients;
											clientvalue ->
													clients = Map.put(clients, addresseeName, [client_socket: clientvalue[:client_socket], client_position: clientvalue[:client_position], current_choice: clientvalue[:current_choice], opponent_name: opponentName, score: clientvalue[:score], current_state: 2]);
											end

			case Map.get(clients, addresseeName) do
					nil ->
							IO.puts "Addressee #{addresseeName} unkown.";
							clients;
					clientvalue ->

					for {client2_key, client2_value} <- clients do
								if (client2_value[:client_socket] != clientvalue[:client_socket]) do
										# Output to Client
										binary_to_send = "CHALLENGE:#{addresseeName}:\n"
										:gen_tcp.send(client2_value[:client_socket], binary_to_send);
								end
					end
			end

			route_message(clients);

		# Initialise client (addresseeName)
		{:initialisation, addresseeName} ->

			case Map.get(clients, addresseeName) do
					nil ->
							IO.puts "Addressee #{addresseeName} unkown.";
							clients;
					clientvalue ->

					# Send initialisation data about everyone, including the user
					for {client2_key, client2_value} <- clients do

							{xPos, yPos} = client2_value[:client_position];
							otherState = client2_value[:current_state];
							binary_to_send = "INITIALISE:#{client2_key}:#{xPos}:#{yPos}:#{otherState}:\n"
							:gen_tcp.send(clientvalue[:client_socket], binary_to_send);

							# send my stuff to everyone else already in
							if (client2_value[:client_socket] != clientvalue[:client_socket]) do
								{xPos2, yPos2} = clientvalue[:client_position];
								myState = clientvalue[:current_state];
								binary_to_send2 = "INITIALISE:#{addresseeName}:#{xPos2}:#{yPos2}:#{myState}:\n"
								:gen_tcp.send(client2_value[:client_socket], binary_to_send2);
							end
					end
			end

			route_message(clients);

		# Send the global message to every client
		{:send_global, addresseeName, message} ->

			globalChatMessage = "#{addresseeName} said < #{message}";

			#Send message to everyone
			for {client_key, client_value} <- clients do
						binary_to_send = "SENDGLOBALMESSAGE:#{globalChatMessage}:\n"
						:gen_tcp.send(client_value[:client_socket], binary_to_send);
			end

			route_message(clients);

		# Store choice and check if opponent has a choice, if so pick winner
		{:choice, addresseeName, choiceRPS} ->

			clients = case Map.get(clients, addresseeName) do
									nil ->
											IO.puts "Addressee #{addresseeName} unkown.";
											clients;
									clientvalue ->
											clients = Map.put(clients, addresseeName, [client_socket: clientvalue[:client_socket], client_position: clientvalue[:client_position], current_choice: choiceRPS, opponent_name: clientvalue[:opponent_name], score: clientvalue[:score], current_state: clientvalue[:current_state]]);
									end


			case Map.get(clients, addresseeName) do
					nil ->
							IO.puts "Addressee #{addresseeName} unkown.";
							clients;
					clientvalue ->

						if(clientvalue[:opponent_name] != "") do
							# Find opponent to see if they have picked a choice
							for {client2_key, client2_value} <- clients do
								if(client2_value[:opponent_name] != "") do
									if (client2_key == clientvalue[:opponent_name]) do
										aChoice = clientvalue[:current_choice];
										bChoice = client2_value[:current_choice];

										if (bChoice != "-1") do
											 	if(aChoice != "-1") do
													# has picked so now test to see who wins
													IO.puts "#{addresseeName}: #{aChoice} vs. #{client2_key}: #{bChoice}"
													winner_key = "";

													if(aChoice == "0") do
														if(bChoice == "1") do
																#client2_value wins
																winner_key = client2_key;
																winner = "ADDSCORE:#{client2_key}:\n"
																:gen_tcp.send(client2_value[:client_socket], winner);
														end
													end
													if(aChoice == "1") do
														if(bChoice == "0") do
																#clientvalue wins
																winner_key = addresseeName;
																winner = "ADDSCORE:#{addresseeName}:\n"
																:gen_tcp.send(clientvalue[:client_socket], winner);
														end
													end
													if(aChoice == "0") do
														if(bChoice == "2") do
																#clientvalue wins
																winner_key = addresseeName;
																winner = "ADDSCORE:#{addresseeName}:\n"
																:gen_tcp.send(clientvalue[:client_socket], winner);
														end
													end
													if(aChoice == "2") do
														if(bChoice == "0") do
																#client2_value wins
																winner_key = client2_key;
																winner = "ADDSCORE:#{client2_key}:\n"
																:gen_tcp.send(client2_value[:client_socket], winner);
														end
													end
													if(aChoice == "1") do
														if(bChoice == "2") do
																#client2_value wins
																winner_key = client2_key;
																winner = "ADDSCORE:#{client2_key}:\n"
																:gen_tcp.send(client2_value[:client_socket], winner);
														end
													end
													if(aChoice == "2") do
														if(bChoice == "1") do
																#clientvalue wins
																winner_key = addresseeName;
																winner = "ADDSCORE:#{addresseeName}:\n"
																:gen_tcp.send(clientvalue[:client_socket], winner);
														end
													end

													#give winner +1 score
													if(winner_key != "") do
														clients = case Map.get(clients, winner_key) do
																nil ->
																	IO.puts "Addressee #{winner_key} unkown.";
																	clients;
																clientvalue5 ->
																	clients = Map.put(clients, winner_key, [client_socket: clientvalue5[:client_socket], client_position: clientvalue5[:client_position], current_choice: clientvalue5[:current_choice], opponent_name: clientvalue5[:opponent_name], score: (clientvalue5[:score] + 1), current_state: 0]);
																end
													end


													# Both guys sent message that game done so that their state is idle
													end_game_0 = "ENDGAME:#{client2_key}:\n"
													:gen_tcp.send(client2_value[:client_socket], end_game_0);

													end_game_1 = "ENDGAME:#{addresseeName}:\n"
													:gen_tcp.send(clientvalue[:client_socket], end_game_1);

													:global.send @my_router, { :reset_player, addresseeName };
													:global.send @my_router, { :reset_player, client2_key };
												end
										end
									end
								end
							end
						end
			end

			route_message(clients);

		{:reset_player, addresseeName} ->

			clients = case Map.get(clients, addresseeName) do
					nil ->
						IO.puts "Addressee #{addresseeName} unkown.";
						clients;
					clientvalue ->
							IO.puts "Servers says: Reset #{addresseeName}";
						clients = Map.put(clients, addresseeName, [client_socket: clientvalue[:client_socket], client_position: clientvalue[:client_position], current_choice: "-1", opponent_name: "", score: clientvalue[:score], current_state: 0]);
					end


			route_message(clients);

		 # End the loop
		 {:shutdown} ->
				IO.puts "Shutting down!";

				 for {client2_key, client2_value} <- clients do
							 # Output to Client
							 binary_to_send = "CLOSE\n"
						 :gen_tcp.send(client2_value[:client_socket], binary_to_send);
					 end

		 # In case there is an unkown message
		 anything_else ->
				IO.puts "Unkown Message:";
				IO.inspect anything_else;

				route_message(clients);
		end
	end

end


defmodule Client do

	# Pass nickname to be added to the Map
	def register_nickname(nickname) do
		client_pid = spawn(Client, :receive_message, [nickname]);
		Router.register_nickname(nickname, client_pid);
	end

	# Pass nickname to be removed from the Map.
	def unregister_nickname(nickname) do
		Router.unregister_nickname(nickname);
	end

	# Pass message data to the Router
	def send_chat_message_to(addresseeName, message) do
		Router.send_chat_message_to(addresseeName, message)
	end

	# Pass new position data to the Router
	def set_position_to(x, y, addresseeName) do
		Router.set_position_to(x, y, addresseeName)
	end

	# Pass name of person waiting for challenge to the Router
	def waiting_challenge(addresseeName) do
		Router.waiting_challenge(addresseeName)
	end
	# Pass name of person cancelling their challenge to the Router
	def cancel_challenge(addresseeName) do
		Router.cancel_challenge(addresseeName)
	end
	# Pass name of person in the challenge to the Router
	def challenge(addresseeName, opponentName) do
		Router.challenge(addresseeName, opponentName)
	end

	# Pass the choice to the router to save it and deal with it later
	def choice(choiceRPS, addresseeName) do
		Router.challenge(choiceRPS, addresseeName)
	end

	# Pass message and sender to the server to send back a message
	def send_global(addresseeName, message) do
			Router.send_global(addresseeName, message);
	end

	# Pass addresseeName to the server so it can send the initialisation
	# data back to the client (addresseeName)
	def initialisation(addresseeName) do
			Router.initialisation(addresseeName);
	end

	# Pass move quantities to the Router
	def update_position_by(x, y, addresseeName) do
			Router.update_position_by(x, y, addresseeName)
	end

	# Pass print_positions to the Router
	def print_positions(addresseeName) do
			Router.print_positions(addresseeName);
	end


	# Client Loop
	def receive_message(who) do
		receive do
			{:stop} ->
				IO.puts "Client #{who} closing";

			{:chat_msg, message, {x, y}} ->
				IO.puts "#{who} received #{message} who is at (#{x},#{y})";
				receive_message(who);

			{:update_pos_msg, {x, y}} ->
				IO.puts "#{who}'s position has been updated to (#{x},#{y})";
				receive_message(who);

			{:set_pos_msg, {x, y}} ->
				IO.puts "#{who}'s position has been set to (#{x},#{y})";
				receive_message(who);

			{:show_pos, {x, y}} ->
				IO.puts "#{who}'s position is (#{x},#{y})";
				receive_message(who);

			other ->
				IO.puts "Incorrect right hand value: "
				IO.inspect other;
				receive_message(who);
		end
	end

end


defmodule  TCPServer do

	# Start a TCPServer process of the desired port number
	def start(port) do
		server port, 5
	end

	# Initialise the TCPServer
	def server(port, pending_connections) do
		{:ok, listening_socket} =
			:gen_tcp.listen(port, [:binary,
															backlog: pending_connections,
															reuseaddr: true,
															active: false,
															packet: :line]);
		loop(listening_socket);
	end

	# TCPServer Loop (to check for incoming connections)
	def loop(listening_socket) do
		case :gen_tcp.accept(listening_socket) do

				{:ok, client_socket} ->
					spawn(fn -> client_loop(client_socket) end);

					binary_to_send = "CONNECTED!\n"
					:gen_tcp.send(client_socket, binary_to_send);

					loop(listening_socket);

				{:error, why} ->
						IO.puts "Error: ";
						IO.inspect why;
		end
	end

	# Client Loop (to check for imcoming messages sent to the client)
	def client_loop(client_socket) do
		case :gen_tcp.recv(client_socket, 0) do
				{:ok, message} ->
					IO.puts message
					case String.split(message, "::") do
							["CLOSE" |_] ->
								IO.puts "Closing";
								IO.inspect client_socket;
								:gen_tcp.close(client_socket);

							["REG", addresseeName | _] ->
								Router.register_nickname(addresseeName, client_socket);
								client_loop(client_socket);

							["SEND", addresseeName, message | _] ->
								Router.send_chat_message_to(addresseeName, message);
								client_loop(client_socket);

							["UNREG", addresseeName | _] ->
								Router.unregister_nickname(addresseeName);
								#:gen_tcp.close(client_socket);
								client_loop(client_socket);

							["UPDATEPOS", x, y, addresseeName | _] ->
								{xInt, _} = Integer.parse(x);
								{yInt, _} = Integer.parse(y);
								Router.update_position_by(xInt, yInt, addresseeName);
								client_loop(client_socket);

							["SHOWPOSITIONS", addresseeName |_] ->
								Router.print_positions(addresseeName);
								client_loop(client_socket);

							["SETPOS", x, y, addresseeName | _] ->
								{xInt, _} = Integer.parse(x);
								{yInt, _} = Integer.parse(y);
								Router.set_position_to(xInt, yInt, addresseeName);
								client_loop(client_socket);

							["WAITINGCHALLENGE", addresseeName |_] ->
								Router.waiting_challenge(addresseeName);
								client_loop(client_socket);

							["CANCELCHALLENGE", addresseeName |_] ->
								Router.cancel_challenge(addresseeName);
								client_loop(client_socket);

							["CHALLENGE", addresseeName, opponentName |_] ->
								Router.challenge(addresseeName, opponentName);
								client_loop(client_socket);

							["CHOICE", addresseeName, choiceRPS |_] ->
								#{choiceRPSint, _} = Integer.parse(choiceRPS);
								Router.choice(choiceRPS, addresseeName)
								client_loop(client_socket);

							["SENDGLOBAL", addresseeName, message |_] ->
								Router.send_global(addresseeName, message);
								client_loop(client_socket);

							["INITIALISATION", addresseeName |_] ->
								Router.initialisation(addresseeName);
								client_loop(client_socket);

							other ->
								IO.puts "Incorrect message: #{other}"
								client_loop(client_socket);
					end

				{:error, why} ->
					IO.puts "Error: ";
					IO.inspect why;
					:gen_tcp.close(client_socket);
		end
	end

end
