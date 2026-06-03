extends Node

# === CONNECTION STATES ===
enum ConnectionState {
	DISCONNECTED,
	CONNECTING,
	CONNECTED,
	DISCONNECTING,
	CONNECTION_FAILED,
	SERVER_SHUTDOWN
}

var current_state: ConnectionState = ConnectionState.DISCONNECTED
var connection_error: String = ""

# === SIGNALS ===
signal state_changed(new_state: ConnectionState)
signal connection_established()
signal connection_lost(reason: String)
signal server_shutdown()
signal retry_requested() 


# === STATE MANAGEMENT ===
func set_state(new_state: ConnectionState, error: String = ""):
	if current_state == new_state:
		return
	
	current_state = new_state
	connection_error = error
	state_changed.emit(new_state)
	
	print("[ConnectionManager] State: ", ConnectionState.keys()[new_state])
	
	# Emit specific signals
	match new_state:
		ConnectionState.CONNECTED:
			connection_established.emit()
		ConnectionState.CONNECTION_FAILED:
			connection_lost.emit(error)
		ConnectionState.SERVER_SHUTDOWN:
			server_shutdown.emit()

func get_state() -> ConnectionState:
	return current_state

func get_state_name() -> String:
	return ConnectionState.keys()[current_state]

func is_network_connected() -> bool:
	return current_state == ConnectionState.CONNECTED	

func get_error() -> String:
	return connection_error
