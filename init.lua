HUDMAP_UPDATE_TIME = 1
HUDMAP_MARKER_SIZE = {x=15, y=15}
HUDMAP_PLAYER_MARKERS = true
HUDMAP_PLAYER_INFOS = true
HUDMAP_DEFAULT_PREFS = {visible=false, scale=1, players=false, infos=false}

hudmap = {
	marker = {},
	map = {},
    edge = {},
    info = {},
    coord = {},
	pref = {},
	player = {},
	registered_maps = {},
}

function hudmap:register_map(name, def)
	local scale_size = {
		x = def.maxp.x - def.minp.x,
		z = def.maxp.z - def.minp.z,
	}
	table.insert(hudmap.registered_maps, {
		name = name,
		size = def.size,
		minp = def.minp,
		maxp = def.maxp,
		area = scale_size.x * scale_size.z,
		texture = def.texture,
		scale = {
			x = scale_size.x / def.size.x,
			y = scale_size.z / def.size.y,
		},
	})
	table.sort(hudmap.registered_maps, function(a, b)
		return a.area < b.area
	end)
end

hudmap:register_map("world", {
	size = {x=320, y=320},
	minp = {x=-2000, y=-1000, z=-2000},
	maxp = {x=2000, y=30000, z=2000},
	texture = "world.png",
})


local timer = 0
local marker_offset = {
	x = math.ceil(HUDMAP_MARKER_SIZE.x / 2),
	y = math.ceil(HUDMAP_MARKER_SIZE.y / 2),
}

local function pos_inside_map(pos, map)
	return pos.x >= map.minp.x and pos.x <= map.maxp.x and
		pos.y >= map.minp.y and pos.y <= map.maxp.y and
		pos.z >= map.minp.z and pos.z <= map.maxp.z
end

local function get_marker_pos(pos, map, name)
	local x = pos.x - map.minp.x
	local y = pos.z - map.minp.z
	x = map.size.x - x / map.scale.x - marker_offset.x
	y = map.size.y - y / map.scale.y - marker_offset.y
	return {
		x = -x,
		y = y,
	}
end

local function get_map(player)
	local name = player:get_player_name()
	local pos = hudmap.player[name].pos
	if name and pos.x and pos.z then
		for _, map in ipairs(hudmap.registered_maps) do
			if pos_inside_map(pos, map) then
				return map
			end
		end
	end
end

local function remove_hud(player, name)
	player:hud_remove(hudmap.map[name])
	player:hud_remove(hudmap.marker[name])
	player:hud_remove(hudmap.info[name])
    player:hud_remove(hudmap.edge[name])

    local i=0
    for i=0,99,1 do
        player:hud_remove(hudmap.coord[name][i])
    end

	hudmap.map[name] = nil
	hudmap.marker[name] = nil
    hudmap.edge[name] = nil
    hudmap.info[name] = nil
    hudmap.edge[name] = nil
    hudmap.coord[name] = nil

end

local function update_hud(player)
	local name = player:get_player_name()
    local playerpos = vector.round(player:getpos())
    local timeofday = tostring(math.floor(minetest.get_timeofday() * 24000))

	if hudmap.pref[name].visible == false then
		return
	end

	local map = get_map(player)
	local scale = 1
	if map then
		local pos = get_marker_pos(hudmap.player[name].pos, map, name)
        local timeofday = tostring(math.floor(minetest.get_timeofday() * 24000))

		if pos then
			if hudmap.map[name] then
				player:hud_change(hudmap.map[name], "text", map.texture)
				player:hud_change(hudmap.marker[name], "offset", pos)

                player:hud_change(hudmap.info[name], "text", 
                                                            "\nTime of day: " .. timeofday ..
                                                            "\nPlayer pos X: " .. tostring(playerpos.x) .. " Y: " .. tostring(playerpos.y) ..  " Z: " .. tostring(playerpos.z) ..
                                                            "\nItem on hand: " .. player:get_wielded_item():get_name() ..
                                                            "\nIP: " .. minetest.get_player_information(name).address ..
                                                            "\nUptime server: " .. tonumber(math.floor(minetest.get_server_uptime())) ..
                                                            "\nGame time: " .. tostring(minetest.get_gametime()) .. 
                                                            "\nNumber of Day: " .. tostring(minetest.get_day_count()))

			else
				hudmap.map[name] = player:hud_add({
					hud_elem_type = "image",
					position = {x=1,y=0},
					scale = {x=scale, y=scale},
					text = map.texture,
					offset = {x=0,y=0},
					alignment = {x=-1,y=1},
				})

				hudmap.marker[name] = player:hud_add({
					hud_elem_type = "image",
					position = {x=1,y=0},
					scale = {x=scale, y=scale},
					text = "hudmap_marker_1.png",
					offset = pos,
					alignment = {x=-1,y=1},
				})

                hudmap.info[name] = player:hud_add({
                    hud_elem_type = "text",
                    name = "Info",
                    number = 0xFFFFFF,
                    position = { x = 1, y = 1 },
                    offset = {x = -256, y = -256},
                    direction = 0,
                    text = "",
                    scale = {x = 200, y = 60 },
                    alignment = { x = 1, y = 1 },
                })


				hudmap.edge[name] = player:hud_add({
					hud_elem_type = "image",
					position = {x=0.5,y=0.5},
					scale = {x=-100, y=-100},
					text = "blackedge.png",
				})

                
                hudmap.coord[name] = {}
                local i = 0
                for coordstepx=0,288,32 do
                    for coordstepy=0,288,32 do
                        hudmap.coord[name][i] = player:hud_add({
                            hud_elem_type = "text",
                            name = "Coord",
                            number = 0xFFFFFF,
                            position = { x = 1, y = 1 },
                            offset = {x = -312 + coordstepx, y = -596 + coordstepy},
                            direction = 0,
                            text = tostring(coordstepx/32) .. tostring(coordstepy/32),
                            scale = {x = 200, y = 60 },
                            alignment = { x = 1, y = 1 },
                        })
                       i=i+1     
                    end
                end

	   


			end
		else
			return
		end
	else
		remove_hud(player, name)
		return
	end
	if HUDMAP_PLAYER_MARKERS == true and
			hudmap.pref[name].players == true then
		for k, v in pairs(hudmap.player) do
			if k ~= name and v.pos.x and v.pos.z then
				if pos_inside_map(v.pos, map) then
					local pos = get_marker_pos(v.pos, map, name)
					if v.marker[name] then
						player:hud_change(v.marker[name], "offset", pos)
					else
						v.marker[name] = player:hud_add({
							hud_elem_type = "image",
							position = {x=1,y=0},
							scale = {x=scale, y=scale},
							text = "hudmap_marker_2.png",
							offset = pos,
							alignment = {x=-1,y=1},
						})
					end
				else
					if v.marker[name] then
						player:hud_remove(v.marker[name])
						v.marker[name] = nil
					end
				end
			end
		end
	end
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	hudmap.pref[name] = HUDMAP_DEFAULT_PREFS
	hudmap.player[name] = {marker={}, info={}, pos={x=0, z=0}}
	minetest.after(1, function(player)
		if player then
			update_hud(player)
		end
	end, player)
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	hudmap.player[name] = nil
end)

minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer > HUDMAP_UPDATE_TIME then
		for _,player in ipairs(minetest.get_connected_players()) do
			local name = player:get_player_name()
			local pos = player:getpos()
			if name and pos then
				hudmap.player[name].pos = pos
				update_hud(player)
			end
		end
		timer = 0
	end
end)

minetest.register_chatcommand("helmet", {
	params = "<cmd> [args]",
	description = "Helmet",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if param == nil or player == nil then
			return
		end
		local cmd, args = string.match(param, "([^ ]+) (.+)")
		cmd = cmd or param
		if cmd == "on" then
			hudmap.pref[name].visible = true
			update_hud(player)
		elseif cmd == "off" then
			hudmap.pref[name].visible = false
			remove_hud(player, name)
		elseif cmd == "players" then
			if args == "on" then
				hudmap.pref[name].players = true
			elseif args == "off" then
				hudmap.pref[name].players = false
			end
			update_hud(player)
		end
	end,
})

