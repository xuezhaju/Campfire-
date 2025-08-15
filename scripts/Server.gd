extends Node
class_name ServerQuery

signal query_completed(info)  # 当查询完成时发出信号
signal query_failed()         # 当查询失败时发出信号

var udp := PacketPeerUDP.new()
var server_ip := ""
var server_port := 0
var timeout := 6.0                # 超时时间（秒）
var time_elapsed := 0.0
var ping_start_time := 0.0

var ping :float = 0.0

var is_querying := false

# 默认服务器信息
var server_info := {
	"name": "未知",
	"map": "未知",
	"description": "",
	"players": 0,
	"max_players": 0,
	"ping": "超时"
}

# 查询服务器
func query(ip: String, port: int) -> void:
	if is_querying:
		return
	
	server_ip = ip
	server_port = port
	time_elapsed = 0.0
	is_querying = true
	
	# 重置服务器信息
	server_info = {
		"name": "未知",
		"map": "未知",
		"description": "",
		"players": 0,
		"max_players": 0,
		"ping": "超时"
	}
	
	ping_start_time = Time.get_ticks_msec()
	
	if udp.connect_to_host(ip, port) != OK:
		printerr("无法连接到服务器 %s:%d" % [ip, port])
		query_failed.emit()
		is_querying = false
		return
	
	var query = PackedByteArray([
		0xFF, 0xFF, 0xFF, 0xFF, 0x54,
		0x53, 0x6F, 0x75, 0x72, 0x63, 0x65, 0x20, 0x45, 0x6E, 0x67, 0x69, 0x6E, 0x65, 0x20, 0x51, 0x75, 0x65, 0x72, 0x79, 0x00
	])
	udp.put_packet(query)
	
	set_process(true)

func _process(delta: float) -> void:
	if not is_querying:
		return
	
	time_elapsed += delta
	if time_elapsed > timeout:
		printerr("查询超时")
		query_failed.emit()
		is_querying = false
		set_process(false)
		return
	
	while udp.get_available_packet_count() > 0:
		parse_response(udp.get_packet())
		is_querying = false
		set_process(false)

func parse_response(packet: PackedByteArray) -> void:
	var strings = extract_strings_from_packet(packet)
	if strings.size() < 4:
		printerr("响应数据不完整")
		query_failed.emit()
		return
	
	# 计算延迟
	ping = Time.get_ticks_msec() - ping_start_time
	
	server_info = {
		"name": strings[0].strip_edges(),
		"map": strings[1].strip_edges(),
		"description": strings[2].strip_edges(),
		"players": 0,
		"max_players": 0,
		"ping": "%dms" % ping
	}
	
	# 在原始数据中查找玩家数量
	var player_offset = find_players_data(packet, strings[3])
	if player_offset != -1 and packet.size() > player_offset + 2:
		server_info["players"] = packet[player_offset]
		server_info["max_players"] = packet[player_offset + 1]
	
	# 发出查询完成信号
	query_completed.emit(server_info)

# 从地图路径提取干净名称
func extract_map_name(map_path: String) -> String:
	return map_path.get_file().trim_suffix(".bsp")

# 查找玩家数量数据的位置
func find_players_data(packet: PackedByteArray, last_string: String) -> int:
	var search_bytes = last_string.to_utf8_buffer()
	search_bytes.append(0x00)  # 加上null终止符
	
	# 遍历数据包寻找匹配位置
	for i in range(packet.size() - search_bytes.size()):
		var found = true
		for j in range(search_bytes.size()):
			if packet[i + j] != search_bytes[j]:
				found = false
				break
		if found:
			# 返回玩家数量数据的起始位置
			return i + search_bytes.size() + 1 + 1 + 1 + 1 + 1
	return -1

# 提取所有以null结尾的字符串
func extract_strings_from_packet(packet: PackedByteArray) -> Array:
	var strings = []
	var current_str = ""
	for i in range(packet.size()):
		var byte = packet[i]
		if byte >= 32 and byte <= 126:  # 可打印ASCII字符
			current_str += char(byte)
		else:
			if byte == 0 and current_str.length() > 0:
				strings.append(current_str)
				current_str = ""
	return strings

# 获取格式化后的服务器信息文本
func get_formatted_info(space: String = "              ") -> String:
	return "服务器名称：%s%s地图: %s%s延迟: %s" % [
		server_info["name"],
		space,
		server_info["map"],
		space,
		server_info["ping"]
	]

# 清理资源
func cleanup() -> void:
	if udp.is_socket_connected():
		udp.close()
	is_querying = false
	set_process(false)

func _exit_tree() -> void:
	cleanup()
