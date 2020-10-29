--[[
    Silent Hill 1
    1999 <-> Playstation 1 <-> NTSC-U [SLUS-00707]

    - Score Screen UI -
    Shows the score screen entries in an User Interface, in real time
]]

-- Variables                                                            Memory Address      GUI Text                Order in GUI
local desc_show_key, desc_hide_key, idx_sh_key                      =   "<%s> Show Stats",  "<%s> Hide Stats",      0
local addr_mode, desc_mode, idx_mode                                =   0x0BCC97,           "Mode: %s",             1
local addr_games_clear, desc_games_clear, idx_games_clear           =   0x0BCC7E,           "Games Clear: %d",      2
local desc_ending, idx_ending                                       =    "Ending:\n -.5(G)-.7(B+)-.9(B)-1(U)",      3
                                                                        -- Skip 1 line, "ending" uses 2 lines (\n)
local addr_saves, desc_saves, idx_saves                             =   0x0BCADA,           "Saves: %d",            5
local addr_continues, desc_continues, idx_continues                 =   0x0BCCAF,           "Continues: %d",        6
local addr_playtime, desc_playtime, idx_playtime                    =   0x0BCC84,           "Total Time: %s",       7
local addr_w_distance, desc_w_distance, idx_w_distance              =   0x0BCC8C,           "W. Distance: %.3f km", 8
local addr_r_distance, desc_r_distance, idx_r_distance              =   0x0BCC88,           "R. Distance: %.3f km", 9
local addr_items_picked, desc_items_picked, idx_items_picked        =   0x0BCC70,           "Items Picked: %d/204", 10
local addr_special_items, desc_special_items, idx_special_items     =   0x0BCC90,           "Special Items: %d/15", 11
local addr_fighting_kills, desc_fighting_kills, idx_fighting_kills  =   0x0BCC91,           "Fighting Kills: %d",   12
local addr_shooting_kills, desc_shooting_kills, idx_shooting_kills  =   0x0BCC93,           "Shooting Kills: %d",   13
local addr_s_range_shots, desc_s_range_shots, idx_s_range_shots     =   0x0BCC9A,           "S. Range Shots: %.2f", 14
local addr_m_range_shots, desc_m_range_shots, idx_m_range_shots     =   0x0BCC9C,           "M. Range Shots: %.2f", 15
local addr_l_range_shots, desc_l_range_shots, idx_l_range_shots     =   0x0BCC9E,           "L. Range Shots: %.2f", 16
local desc_na_range_shots, idx_na_range_shots                       =                       "No Aiming Shots: %.2f",17
local desc_rank, idx_rank                                           =                       "Rank: %1.1f",          18
local addr_attk_hidden_weapons                                      =   0x0BCCAC    -- Used but not displayed
local addr_total_shots                                              =   0x0BCC98    -- Used but not displayed
local addr_kills_shared                                             =   0x0BCC92    -- Byte used for both fighting and shooting kills


-- GUI Variables
local gui_x             = 1             -- GUI X Coordinate
local gui_y             = 1             -- GUI Y Coordinate
local gui_anchor        = null          -- Text Anchor: topleft, topright, bottomleft, bottomright
local line_hight        = 15            -- Space between Text Lines
local txt_color_normal  = 0xFFFFFFFF    -- Normal Text Color: White
local txt_color_maxed   = 0xFFF8D868    -- Maxed Text Color: Gold
local txt_color_sh      = 0x99FFFFFF    -- Show/Hide button Text Color: Transparent White


-- More Variables
local saves_max             = 999           -- Maximum number of saves to display
local fighting_kills_max    = 4000          -- Maximum number of fighting kills to display
local shooting_kills_max    = 4000          -- Maximum number of shooting kills to display
local sh_gui_key            = "ControlLeft" -- Button to show/hide stats GUI
local input_cooldown        = 30            -- Cooldown frames between show/hide GUI button presses (60 fps ~ 0.5s)


-- Returns an array with the elements:
--    [idx]=variableIdx     [desc]=variableDesc     [val]=variableValues    [txt_color]=textColor
local function to_vect(idx, desc, value, text_color)
    return {["idx"]=idx, ["desc"]=desc, ["val"]=value, ["txt_color"]=text_color}
end

-- Convert Playtime from seconds to H:m:s string
local function playtime_tostr(val_playtime)
    local playtime_h = math.floor(val_playtime/3600)
    local playtime_m = math.floor(math.fmod(val_playtime,3600)/60)
    local playtime_s = math.floor(math.fmod(val_playtime,60))
    return string.format("%2dh %2dm %2ds", playtime_h, playtime_m, playtime_s)
end

-- Transform Game Mode (1 Byte)
local function transform_mode(raw_mode)
    local mode = ""
    if raw_mode == 0xF0 then
        mode = "Easy"
    elseif raw_mode == 0x00 then
        mode = "Normal"
    elseif raw_mode == 0x10 then
        mode = "Hard"
    end
    
    return mode
end

-- Transform Games Clear (1 Byte)
local function transform_games_clear(raw_games_clear)
    return raw_games_clear
end

-- Transform Saves (2 Bytes)
local function transform_saves(raw_saves)
    return math.min(raw_saves, saves_max)
end

-- Transform Continues (1 Byte)
local function transform_continues(raw_continues)
    return raw_continues
end

-- Transform Play time (4 Bytes as Fixed 20.12, ignoring .12 decimals)
local function transform_playtime(raw_playtime)
    return bit.band(bit.rshift(raw_playtime, 12), 0xFFFFF)
end

-- Transform Walk Distance (4 Bytes as Fixed 20.12, ignoring .12 decimals)
local function transform_w_distance(raw_w_distance)
    local w_distance = 0
    tmp_w_distance = bit.band(bit.rshift(raw_w_distance, 12), 0xFFFFF)
    return tmp_w_distance / 1000
end

-- Transform Run Distance (4 Bytes as Fixed 20.12, ignoring .12 decimals)
local function transform_r_distance(raw_r_distance)
    local r_distance = 0
    tmp_r_distance = bit.band(bit.rshift(raw_r_distance, 12), 0xFFFFF)
    return tmp_r_distance / 1000
end

-- Transform Items Picked (2 Bytes)
local function transform_items_picked(raw_items_picked)
    return raw_items_picked
end

-- Transform Special Items (4 bits in 2 Byte)
-- 0111 1000 = Max Special Items
local function transform_special_items(raw_special_items)
    return bit.band(bit.rshift(raw_special_items, 3), 0x0F)
end

-- Transform Fighting Kills (12 bits in 2 Byte, 1 Byte shared with Shooting Kills)
-- Sh. Kills Byte    F. Kills Byte
-- 0000 1111         1111 1111     = Max Fighting Kills
local function transform_fighting_kills(raw_fighting_kills, raw_kills_shared)
    local kills_shared_f = bit.lshift(bit.band(raw_kills_shared, 0x0F), 8)
    return math.min(kills_shared_f + raw_fighting_kills, fighting_kills_max)
end

-- Transform Shooting Kills (12 bits in 2 Byte, 1 Byte shared with Fighting Kills)
-- Sh. Kills Byte    S. Kills Byte
-- 1111 0000         1111 1111     = Max Shooting Kills
local function transform_shooting_kills(raw_shooting_kills, raw_kills_shared)
    local kills_shared_s = bit.lshift(bit.band(raw_kills_shared, 0xF0), 4)
    return math.min(kills_shared_s + raw_shooting_kills, shooting_kills_max)
end

-- Transform Short Range Shots (2 Byte truncated to 2 decimals)
local function transform_s_range_shots(raw_s_range_shots, raw_total_shots)
    local s_range_shots = 0.0
    if raw_total_shots > 0 then
        s_range_shots = math.floor( (raw_s_range_shots / raw_total_shots) *100)/100
    end
    return s_range_shots
end

-- Transform Medium Range Shots (2 Byte truncated to 2 decimals)
local function transform_m_range_shots(raw_m_range_shots, raw_total_shots)
    local m_range_shots = 0.00
    if raw_total_shots > 0 then
        m_range_shots = math.floor( (raw_m_range_shots / raw_total_shots) *100)/100
    end
    return m_range_shots
end

-- Transform Long Range Shots (2 Byte truncated to 2 decimals)
local function transform_l_range_shots(raw_l_range_shots, raw_total_shots)
    local l_range_shots = 0.00
    if raw_total_shots > 0 then
        l_range_shots = math.floor( (raw_l_range_shots / raw_total_shots) *100)/100
    end
    return l_range_shots
end

-- Transform No Aiming Shots (2 Byte truncated to 2 decimals)
local function transform_na_range_shots(val_s_range_shots, val_m_range_shots, val_l_range_shots, raw_total_shots)
    local na_range_shots = 0.00
    if raw_total_shots > 0 then
        na_range_shots = 1.00 - (val_s_range_shots + val_m_range_shots + val_l_range_shots)
        na_range_shots = math.floor(na_range_shots*100)/100
    end
    return na_range_shots
end

-- Process all the data and calculate the rank
-- Returns a table with the columns:
--    [idx]=variableIdx     [desc]=variableDesc     [val]=variableValues    [txt_color]=textColor
--
--  Points Formula (0-100 => 0.0-10.0):
--      Dificulty (Mode):
--          Hard    0p
--          Normal  0p
--          Easy    -5p
--      Games Clear:
--          5+      10p
--          4       8p
--          3       6p
--          2       4p
--          1       2p
--          0       0p
--      Ending Type:
--          Good+   10p
--          Good    5p
--          Bad+    3p
--          Bad     1p
--          UFO     0p
--      Number of Saves:
--          0-2     5p
--          3-5     4p
--          6-10    3p
--          11-20   2p
--          21-30   1p
--          31+     0p
--      Number of Continues:
--          0-1     5p
--          2-3     4p
--          4-5     3p
--          6-7     2p
--          8-9     1p
--          10+     0p
--      Total Time:
--          01:30:00    10p
--          03:00:00    5p
--          04:00:00    3p
--          06:00:00    2p
--          12:00:00    1p
--          12:00:00+   0p
--      Items Picked:
--          150+    10p
--          135     9p
--          120     8p
--          105     7p
--          90      6p
--          75      5p
--          60      4p
--          45      3p
--          30      2p
--          15      1p
--          0-15    0p
--     Special Items Picked:
--          5-6     10p
--          4       8p
--          3       6p
--          2       4p
--          1       2p
--          0       0p
--      Kills (0-30p):
--          (A + B / 2) / (5 + C)
--          A = The bigger of Fighting and Shooting Kills
--          B = The smaller of Fighting and Shooting Kills
--          C = attacks with special weapons - (15 + (game clears x 5))
--      Shooting Style (0-10p):
--          A x 10 + B x 20 + C x 30 - D x 40
--          A = Short Range Shots
--          B = Medium Range Shots
--          C = Long Range Shots
--          D = No Aiming Range Shots
local function process_data(val_mode, val_games_clear, val_saves, val_continues, val_playtime, val_w_distance, val_r_distance,
                            val_items_picked, val_special_items, val_fighting_kills, val_shooting_kills, val_s_range_shots,
                            val_m_range_shots, val_l_range_shots, val_na_range_shots, val_attk_hidden_weapons, str_playtime)
    
    -- Text Color for point based stats
    local txt_c_games_clear = txt_color_normal
    local txt_c_saves = txt_color_normal
    local txt_c_continues = txt_color_normal
    local txt_c_playtime = txt_color_normal
    local txt_c_items_picked = txt_color_normal
    local txt_c_special_items = txt_color_normal
    local txt_c_kills = txt_color_normal
    local txt_c_shots_range = txt_color_normal
    local txt_c_rank = txt_color_normal

    -- Dificulty Points
    local tmp_p_mode = 0
    if val_mode == 0xF0 then
        tmp_p_mode = -5
    end
    
    -- Games Clear Points
    local tmp_p_games_clear = math.min((val_games_clear+1) * 2, 10)
    if tmp_p_games_clear >= 10 then
        txt_c_games_clear = txt_color_maxed
    end
    
    -- Ending Type Points
    local tmp_p_ending = 10 -- Good+ ending
    -- tmp_p_ending = 5     -- Good ending
    -- tmp_p_ending = 3     -- Bad+ ending
    -- tmp_p_ending = 1     -- Bad ending
    -- tmp_p_ending = 0     -- UFO ending
    
    -- Saves Number Points
    local tmp_p_save = 0
    if val_saves <= 2 then
        tmp_p_save = 5
        txt_c_saves = txt_color_maxed
    elseif val_saves <= 5 then
        tmp_p_save = 4
    elseif val_saves <= 10 then
        tmp_p_save = 3
    elseif val_saves <= 20 then
        tmp_p_save = 2
    elseif val_saves <= 30 then
        tmp_p_save = 1
    end
    
    -- Continue Number Points
    local tmp_p_continues = 0
    if val_continues <= 1 then
        tmp_p_continues = 5
        txt_c_continues = txt_color_maxed
    elseif val_continues <= 3 then
        tmp_p_continues = 4
    elseif val_continues <= 5 then
        tmp_p_continues = 3
    elseif val_continues <= 7 then
        tmp_p_continues = 2
    elseif val_continues <= 9 then
        tmp_p_continues = 1
    end
    
    -- Playtime Points
    local tmp_p_playtime = 0
    if val_playtime < 5400 then            -- 1h 30min
        tmp_p_playtime = 10
        txt_c_playtime = txt_color_maxed
    elseif val_playtime <= 10800 then    -- 3h
        tmp_p_playtime = 5
    elseif val_playtime <= 14400 then    -- 4h
        tmp_p_playtime = 3
    elseif val_playtime <= 21600 then    -- 6h
        tmp_p_playtime = 2
    elseif val_playtime <= 43200 then    -- 12h
        tmp_p_playtime = 1
    end
    
    -- Items Picked Points
    local tmp_p_items_picked = 0
    if val_items_picked >= 150 then
        tmp_p_items_picked = 10
        txt_c_items_picked = txt_color_maxed
    elseif val_items_picked >= 135 then
        tmp_p_items_picked = 9
    elseif val_items_picked >= 120 then
        tmp_p_items_picked = 8
    elseif val_items_picked >= 105 then
        tmp_p_items_picked = 7
    elseif val_items_picked >= 90 then
        tmp_p_items_picked = 6
    elseif val_items_picked >= 75 then
        tmp_p_items_picked = 5
    elseif val_items_picked >= 60 then
        tmp_p_items_picked = 4
    elseif val_items_picked >= 45 then
        tmp_p_items_picked = 3
    elseif val_items_picked >= 30 then
        tmp_p_items_picked = 2
    elseif val_items_picked >= 15 then
        tmp_p_items_picked = 1
    end
    
    -- Special Items Points
    local tmp_p_sitems_picked = math.min(val_special_items * 2, 10)
    if tmp_p_sitems_picked >= 10 then
        txt_c_special_items = txt_color_maxed
    end
    
    -- Kills Points between 0 and 30 Points, truncated (Floored)
    local tmp_p_kills_C = math.max(val_attk_hidden_weapons - ( 15 + (val_games_clear+1) * 5), 0)
    -- A = Fighting Kills < B = Shooting KIlls
    local tmp_p_kills_A = val_fighting_kills
    local tmp_p_kills_B = val_shooting_kills
    -- B = Fighting Kills > A = Shooting KIlls
    if val_fighting_kills > val_shooting_kills then
        tmp_p_kills_A = val_shooting_kills
        tmp_p_kills_B = val_fighting_kills
    end
    local tmp_p_kills = (tmp_p_kills_A + (tmp_p_kills_B/2)) / (5 + tmp_p_kills_C)
    tmp_p_kills = math.min(math.max(math.floor(tmp_p_kills), 0), 30)
    if tmp_p_kills >= 30 then
        txt_c_kills = txt_color_maxed
    end
    
    -- Shooting Style Points between 0 and 10, truncated (Floored)
    local tmp_p_shot_style = (val_s_range_shots * 10) + (val_m_range_shots * 20) + (val_l_range_shots * 30) - (val_na_range_shots * 40)
    tmp_p_shot_style = math.min(math.max(math.floor(tmp_p_shot_style), 0), 10)
    if tmp_p_shot_style >= 10 then
        txt_c_shots_range = txt_color_maxed
    end

    -- Final Score between 0 and 10 (truncated to 1 decimal)
    local val_rank = 0.0
    val_rank = val_rank + tmp_p_mode 
                        + tmp_p_games_clear
                        + tmp_p_save
                        + tmp_p_ending
                        + tmp_p_continues
                        + tmp_p_playtime
                        + tmp_p_items_picked
                        + tmp_p_sitems_picked
                        + tmp_p_kills
                        + tmp_p_shot_style
    val_rank = math.min(math.max(val_rank, 0), 100)
    val_rank = math.floor(val_rank + 0.5) / 10
    if val_rank >= 10 then
        txt_c_rank = txt_color_maxed
    end
    
    -- Build Output
    local output = {}
    table.insert(output, to_vect(idx_sh_key, desc_hide_key, sh_gui_key, txt_color_sh))
    table.insert(output, to_vect(idx_mode, desc_mode, val_mode, txt_color_normal))
    table.insert(output, to_vect(idx_games_clear, desc_games_clear, val_games_clear, txt_c_games_clear))
    table.insert(output, to_vect(idx_ending, desc_ending, "", txt_color_normal))
    table.insert(output, to_vect(idx_saves, desc_saves, val_saves, txt_c_saves))
    table.insert(output, to_vect(idx_continues, desc_continues, val_continues, txt_c_continues))
    table.insert(output, to_vect(idx_playtime, desc_playtime, str_playtime, txt_c_playtime))
    table.insert(output, to_vect(idx_w_distance, desc_w_distance, val_w_distance, txt_color_normal))
    table.insert(output, to_vect(idx_r_distance, desc_r_distance, val_r_distance, txt_color_normal))
    table.insert(output, to_vect(idx_items_picked, desc_items_picked, val_items_picked, txt_c_items_picked))
    table.insert(output, to_vect(idx_special_items, desc_special_items, val_special_items, txt_c_special_items))
    table.insert(output, to_vect(idx_fighting_kills, desc_fighting_kills, val_fighting_kills, txt_c_kills))
    table.insert(output, to_vect(idx_shooting_kills, desc_shooting_kills, val_shooting_kills, txt_c_kills))
    table.insert(output, to_vect(idx_s_range_shots, desc_s_range_shots, val_s_range_shots, txt_c_shots_range))
    table.insert(output, to_vect(idx_m_range_shots, desc_m_range_shots, val_m_range_shots, txt_c_shots_range))
    table.insert(output, to_vect(idx_l_range_shots, desc_l_range_shots, val_l_range_shots, txt_c_shots_range))
    table.insert(output, to_vect(idx_na_range_shots, desc_na_range_shots, val_na_range_shots, txt_c_shots_range))
    table.insert(output, to_vect(idx_rank, desc_rank, val_rank, txt_c_rank))
    return output
end

-- Draws GUI
-- Receives a table with the columns:
--  [idx]=variableIdx   [desc]=variableDesc     [val]=variableValues    [txt_color]=textColor
local function draw_gui(gui_data)
    for k, v in ipairs(gui_data) do
        gui.text(gui_x, gui_y + (line_hight*v["idx"]), string.format(v["desc"], v["val"]), v["txt_color"], gui_anchor)
    end
end


local show_gui = false
local cooldown_frames = 0
while true do
    -- Show/Hide GUI
    local input = input.get()
    if input[sh_gui_key] and cooldown_frames <= 0 then
        show_gui = not show_gui
        cooldown_frames = input_cooldown
    end
    
    -- Do not show GUI and the game is running (playtime > 0)
    local raw_playtime = mainmemory.read_u32_le(addr_playtime)
    if not show_gui and raw_playtime > 0 then
        gui.text(gui_x, gui_y + (line_hight*idx_sh_key), string.format(desc_show_key, sh_gui_key), txt_color_sh, gui_anchor)
    
    -- Show GUI and the game is running (playtime > 0)
    elseif raw_playtime > 0 then

        -- Read all values from main memory
        local raw_mode = mainmemory.read_u8(addr_mode)
        local raw_games_clear = mainmemory.read_u8(addr_games_clear)
        local raw_saves = mainmemory.read_u16_le(addr_saves)
        local raw_continues = mainmemory.read_u8(addr_continues)
        local raw_w_distance = mainmemory.read_u32_le(addr_w_distance)
        local raw_r_distance = mainmemory.read_u32_le(addr_r_distance)
        local raw_items_picked = mainmemory.read_u16_le(addr_items_picked)
        local raw_special_items = mainmemory.read_u16_le(addr_special_items)
        local raw_fighting_kills = mainmemory.read_u8(addr_fighting_kills)
        local raw_shooting_kills = mainmemory.read_u8(addr_shooting_kills)
        local raw_s_range_shots = mainmemory.read_u16_le(addr_s_range_shots)
        local raw_m_range_shots = mainmemory.read_u16_le(addr_m_range_shots)
        local raw_l_range_shots = mainmemory.read_u16_le(addr_l_range_shots)
        local raw_attk_hidden_weapons = mainmemory.read_u16_le(addr_attk_hidden_weapons)
        local raw_total_shots = mainmemory.read_u16_le(addr_total_shots)
        local raw_kills_shared = mainmemory.read_u8(addr_kills_shared)

        -- Transformations
        local val_mode = transform_mode(raw_mode)
        local val_games_clear = transform_games_clear(raw_games_clear)
        local val_saves = transform_saves(raw_saves)
        local val_continues = transform_continues(raw_continues)
        local val_playtime = transform_playtime(raw_playtime)
        local str_playtime = playtime_tostr(val_playtime)
        local val_w_distance = transform_w_distance(raw_w_distance)
        local val_r_distance = transform_r_distance(raw_r_distance)
        local val_items_picked = transform_items_picked(raw_items_picked)
        local val_special_items = transform_special_items(raw_special_items)
        local val_fighting_kills = transform_fighting_kills(raw_fighting_kills, raw_kills_shared)
        local val_shooting_kills = transform_shooting_kills(raw_shooting_kills, raw_kills_shared)
        local val_s_range_shots = transform_s_range_shots(raw_s_range_shots, raw_total_shots)
        local val_m_range_shots = transform_m_range_shots(raw_m_range_shots, raw_total_shots)
        local val_l_range_shots = transform_l_range_shots(raw_l_range_shots, raw_total_shots)
        local val_na_range_shots = transform_na_range_shots(val_s_range_shots, val_m_range_shots, val_l_range_shots, raw_total_shots)
        
        -- Process all data
        local data = process_data(val_mode, val_games_clear, val_saves, val_continues, val_playtime, val_w_distance, val_r_distance,
                                        val_items_picked, val_special_items, val_fighting_kills, val_shooting_kills, val_s_range_shots,
                                        val_m_range_shots, val_l_range_shots, val_na_range_shots, raw_attk_hidden_weapons, str_playtime)
        -- Draw GUI
        draw_gui(data)
    end
    
    cooldown_frames = cooldown_frames -1    
    emu.frameadvance();
end
