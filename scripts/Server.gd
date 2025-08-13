extends Node

var udp := PacketPeerUDP.new()
var server_ip := "5.165.236.132"  # 替换为你的服务器IP
var server_port := 27015           # 服务器端口
var timeout := 3.0                # 超时时间（秒）
var time_elapsed := 0.0
var ping_start_time := 0.0

var server_map := ""
var server_name := ""
var server_ping := ""

var space = "            "
var return_text = "服务器名称：" + server_name + space + "地图:" + server_map + space + "延迟:" + server_ping

func start_server():
	query_server(server_ip, server_port)
	set_process(true)


func query_server(ip: String, port: int):
	server_ip = ip
	server_port = port
	ping_start_time = Time.get_ticks_msec()
	
	if udp.connect_to_host(ip, port) != OK:
		printerr("无法连接到服务器 %s:%d" % [ip, port])
		return
	
	var query = PackedByteArray([
		0xFF, 0xFF, 0xFF, 0xFF, 0x54,
		0x53, 0x6F, 0x75, 0x72, 0x63, 0x65, 0x20, 0x45, 0x6E, 0x67, 0x69, 0x6E, 0x65, 0x20, 0x51, 0x75, 0x65, 0x72, 0x79, 0x00
	])
	udp.put_packet(query)

func _process(delta: float) -> void:
	time_elapsed += delta
	if time_elapsed > timeout:
		printerr("查询超时")
		set_process(false)
		return
	
	while udp.get_available_packet_count() > 0:
		parse_response(udp.get_packet())
		set_process(false)

func parse_response(packet: PackedByteArray):
	var strings = extract_strings_from_packet(packet)
	if strings.size() < 4:
		printerr("响应数据不完整")
		return
	
	server_map = strings[1].strip_edges()
	server_name = strings[0].strip_edges()
	server_ping = str(Time.get_ticks_msec() - ping_start_time)
	print(server_map)
	print(server_name)
	print(server_ping)
	
	return_text = "服务器名称：" + server_name + space + "地图:" + server_map + space + "延迟:" + server_ping
	
	var server_info = {
		"名称": strings[0].strip_edges(),       # 字符串2
		"描述": strings[2].strip_edges(),       # 字符串3
		"地图": strings[1].strip_edges(),   # 字符串4
		"玩家": 0,
		"最大玩家": 0,
		"延迟": "%.0fms" % ((Time.get_ticks_msec() - ping_start_time))
	}
	
	# 在原始数据中查找玩家数量
	var player_offset = find_players_data(packet, strings[3])
	if player_offset != -1 and packet.size() > player_offset + 2:
		server_info["玩家"] = packet[player_offset]
		server_info["最大玩家"] = packet[player_offset + 1]
	
	print("\n════ 服务器状态 ════")
	print("🖥️ 名称: %s" % server_info["名称"])
	print("📝 描述: %s" % server_info["描述"])
	print("🗺️ 地图: %s" % server_info["地图"])
	print("👥 玩家: %d/%d" % [server_info["玩家"], server_info["最大玩家"]])
	print("⏱️ 延迟: %s" % server_info["延迟"])
	print("══════════════════")
	
	#return return_text

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
			# 跳过: 字符串(变长) + null(1) + 协议(1) + 名称(变长) + null(1) + 地图(变长) + null(1) + 游戏目录(变长) + null(1) + 游戏描述(变长) + null(1)
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
