-- makebreakbeat v2.0.0
-- bysplicing
--
-- llllllll.co/t/makebreakbeat
--
--
--
--    ▼ instructions below ▼
--
-- K2 generates beat
-- K3 toggles beat
-- E changes sample
lattice_ = require("lattice")

UI = require("ui")

engine.name = "Makebreakbeat"

PROGRESS_FILE="/tmp/mangler/breaktemp-progress"


function os.cmd(cmd)
    print(cmd)
    os.execute(cmd .. " 2>&1")
end

function init()
    sample={}
    for i=1,3 do 
        sample[i]={playing=false,loaded_index=0,beats=0}
    end
    startup_done = false
    file_indexes_available = 0
    current_tempo=clock.get_tempo()
    get_next_file_and_indexes()

    params:add{
        type = 'binary',
        name = "make beat",
        id = 'break_make',
        behavior = 'trigger',
        action = function(v)
            make_beat()
        end
    }
    params:add_file("break_file", "load sample", _path.audio .. "makebreakbeat/amen_resampled.wav")
    params:add{
        type = "number",
        id = "break_beats",
        name = "beats",
        min = 16,
        max = 128,
        default = 32
    }
    do_params()

    lattice = lattice_:new()
    lattice_beats = -1
    pattern = lattice:new_pattern{
        action = function(t)
            if clock.get_tempo()~=current_tempo then 
                current_tempo=clock.get_tempo()
                get_next_file_and_indexes()
            end
            if not startup_done then
                startup_done = true
                do_startup()
            end
            lattice_beats = lattice_beats + 1
            for i=1,3 do 
                if sample[i].beats>0 then 
                    if lattice_beats % sample[i].beats == 0 then
                        print("resetting")
                        engine.tozero(1)
                    end        
                end
            end
            if debounce_load ~= nil then
                debounce_load = debounce_load - 1
                if debounce_load == 0 then
                    debounce_load = nil
                    engine.load_track(1, _path.audio .. "makebreakbeat/" .. last_tempo_generated .. "_" ..
                        last_file_generated .. ".wav")
                end
            end
            redraw()
        end,
        division = 1 / 4
    }
    lattice:start()

    params:default()
end

function get_next_file_and_indexes()
    local fname=""
    local tempo = math.floor(clock.get_tempo())
    file_indexes_available=0
    for i = 1, 1000 do
        fname = _path.audio .. "makebreakbeat/" .. tempo .. "_" .. i .. ".wav"
        if not util.file_exists(fname) then
            break
        end
        file_indexes_available=i
    end
    return fname
end

function enc(k, d)
    if last_file_generated ~= nil then
        d = d > 0 and 1 or -1
        last_file_generated = util.clamp(last_file_generated + d, 1, last_file)
        debounce_load = 4
    end
end

function key(k, z)
    if k == 2 and z == 1 then
        make_beat()
    elseif k == 3 and z == 1 then
        playing = not playing
        if not playing then
            engine.amp(1, 0)
        else
            engine.amp(1, 1)
            lattice_beats = -1
            lattice:hard_restart()
        end
    end

end

function redraw()
    screen.clear()
    screen.level(15)
    local icon = UI.PlaybackIcon.new(1, 1, 6, 4)
    icon.status = playing and 1 or 4
    icon:redraw()
    if last_file_generated ~= nil then
        screen.move(64, 32 - 15)
        screen.text_center(last_tempo_generated .. "_" .. last_file_generated)
    end
    if loading == true then
        screen.move(64, 32)
        screen.text_center("installing aubio and sox . . . ")
    else
        if util.file_exists(PROGRESS_FILE) then
            draw_progress()
        else
            if making_beat == true then
                debounce_load = 4
                making_beat = false
                playing = true
            end
            screen.move(64, 32 - 5)
            screen.text_center("press K2 to generate beat")
            if last_file_generated ~= nil then
                screen.move(64, 32 + 5)
                screen.text_center("press K3 to stop/start beat")
            end
        end
    end
    screen.update()
end

slider = UI.Slider.new(4, 55, 118, 8, 0, 0, 100, {}, "right")
slider.label = "progress"
function draw_progress()
    local _, filename, _ = string.match(params:get("break_file"), "(.-)([^\\/]-%.?([^%.\\/]*))$")
    screen.move(64, 32 - 5)
    screen.text_center(string.format("generating beat from"))
    screen.move(64, 32 + 5)
    screen.text_center(string.format("'%s'", filename))
    local progress = tonumber(util.os_capture("tail -n1 "..PROGRESS_FILE))
    if progress == nil then
        do
            return
        end
    end
    slider:set_value(progress)
    slider:redraw()
end

function cleanup()
    do_cleanup()
end
