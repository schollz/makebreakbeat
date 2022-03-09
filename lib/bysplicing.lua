function do_params()
    break_options={
        {"reverse",10},
        {"stutter",20},
        {"pitch",5},
        {"reverb",5},
        {"revreverb",5},
        {"jump",20},
      }
      for _,op in ipairs(break_options) do
        params:add{type="number",id="break_"..op[1],name=op[1],min=0,max=100,default=op[2]}
      end
      params:add_option("break_tapedeck","tapedeck",{"no","yes"})
end

function do_startup()
    norns.system_cmd(_path.code .. "makebreakbeat/lib/install.sh", function(x)
        loading = false
    end)
    os.execute("mkdir -p " .. _path.audio .. "makebreakbeat")
    if not util.file_exists(_path.audio .. "makebreakbeat/amen_resampled.wav") then
        os.execute("cp " .. _path.code .. "makebreakbeat/lib/amen_resampled.wav " .. _path.audio .. "makebreakbeat/")
    end
    clock.run(function()
        os.cmd("chmod +x /home/we/dust/code/makebreakbeat/lib/sendosc")
        os.cmd("rm -rf /tmp/mangler")
        os.cmd("pkill -f 'nrt_server'")
        os.cmd("rm -f /tmp/nrt-scready")
        os.cmd('/home/we/dust/code/makebreakbeat/lib/sendosc --host 127.0.0.1 --addr "/quit" --port 57113')
        os.cmd("cd /home/we/dust/code/makebreakbeat/lib && sclang nrt_server.supercollider &")
    end)

    find_last_file_generated()
end

function do_beat()
    if util.file_exists("/tmp/mangler/breaktemp-progress") or making_beat then
        do
            return
        end
    end
    params:write()
    making_beat = true
    local tempo = math.floor(clock.get_tempo())
    local fname = find_last_file_generated()
    local cmd = "cd " .. _path.code .. "makebreakbeat/lib/ && lua mangler.lua --server-started"
    cmd = cmd .. " -t " .. tempo .. " -b " .. params:get("break_beats")
    cmd = cmd .. " -o " .. fname .. " " .. " -i " .. params:get("break_file")
    for _, op in ipairs(break_options) do
        cmd = cmd .. " --" .. op[1] .. " " .. params:get("break_" .. op[1])
    end
    if util.file_exists("/usr/share/SuperCollider/Extensions/PortedPlugins/AnalogTape_scsynth.so") and
        params:get("break_tapedeck") == 2 then
        cmd = cmd .. " -tapedeck"
    end
    cmd = cmd .. " &"
    print(cmd)
    clock.run(function()
        os.execute(cmd)
    end)
    print("running command!")
end


function do_cleanup()
    os.cmd('/home/we/dust/code/makebreakbeat/lib/sendosc --host 127.0.0.1 --addr "/quit" --port 57113')
    os.cmd("rm -f /tmp/nrt-scready")
    os.cmd("rm -rf /tmp/mangler")
    os.cmd("pkill -f 'nrt_server'")
end