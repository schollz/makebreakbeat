-- make break beat v2.0.0
--
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

lattice_=require("lattice")

UI=require("ui")

engine.name="Makebreakbeat"

function init()
  print("v1.0.0")
  playing=true
  loading=true
  startup_done=false
  last_file_generated=nil

  params:add{
    type='binary',
    name="make beat",
    id='break_make',
    behavior='trigger',
    action=function(v)
      make_beat()
    end
  }
  params:add_file("break_file","load sample",_path.audio.."makebreakbeat/amen_resampled.wav")
  params:add{type="number",id="break_beats",name="beats",min=4,max=128,default=16}
  break_options={
    {"deviation",10},
    {"reverse",10},
    {"stutter",20},
    {"pitch",5},
    {"trunc",2},
    {"half",1},
    {"reverb",5},
    {"stretch",2},
    {"kick",50},
    {"snare",20},
  }
  for _,op in ipairs(break_options) do
    params:add{type="number",id="break_"..op[1],name=op[1],min=0,max=100,default=op[2]}
  end
  params:add{type="number",id="break_kickdb",name="kick db",min=-96,max=0,default=-6}
  params:add{type="number",id="break_snaredb",name="snare db",min=-96,max=0,default=-6}

  lattice=lattice_:new()
  lattice_beats=-1
  pattern=lattice:new_pattern{
    action=function(t)
      if not startup_done then
        startup_done=true
        do_startup()
      end
      lattice_beats=lattice_beats+1
      if lattice_beats%(params:get("break_beats"))==0 then
        print("resetting")
        engine.tozero()
      end
      if debounce_load~=nil then
        debounce_load=debounce_load-1
        if debounce_load==0 then
          debounce_load=nil
          engine.load_track(_path.audio.."makebreakbeat/"..last_tempo_generated.."_"..last_file_generated..".wav")
        end
      end
      redraw()
    end,
    division=1/4,
  }
  lattice:start()

  params:default()
end

function do_startup()
  norns.system_cmd(_path.code.."makebreakbeat/lib/install.sh",function(x)
    loading=false
  end)
  os.execute("mkdir -p ".._path.audio.."makebreakbeat")
  if not util.file_exists(_path.audio.."makebreakbeat/amen_resampled.wav") then
    os.execute("cp ".._path.code.."makebreakbeat/lib/amen_resampled.wav ".._path.audio.."makebreakbeat/")
  end
end

function make_beat()
  if util.file_exists("/tmp/breaktemp-progress") or making_beat then
    do return end
  end
  params:write()
  making_beat=true
  local fname=""
  local tempo=math.floor(clock.get_tempo())
  for i=1,1000 do
    last_file=i
    last_file_generated=i
    last_tempo_generated=tempo
    fname=_path.audio.."makebreakbeat/"..tempo.."_"..i..".wav"
    if not util.file_exists(fname) then
      break
    end
  end
  local cmd="lua ".._path.code.."makebreakbeat/lib/dnb.lua --no-logo --snare-file /home/we/dust/code/makebreakbeat/lib/snare.wav --kick-file /home/we/dust/code/makebreakbeat/lib/kick.wav "
  cmd=cmd.." -t "..tempo.." -b "..(params:get("break_beats")+1)
  cmd=cmd.." -o "..fname.." ".." -i "..params:get("break_file")
  for _,op in ipairs(break_options) do
    cmd=cmd.." --"..op[1].." "..params:get("break_"..op[1])
  end
  cmd=cmd.." --snare-mix ".." "..params:get("break_snaredb")
  cmd=cmd.." --kick-mix ".." "..params:get("break_kickdb")
  cmd=cmd.." &"
  print(cmd)
  clock.run(function()
    os.execute(cmd)
  end)
  print("running command!")
end

function enc(k,d)
  if last_file_generated~=nil then
    d=d>0 and 1 or-1
    last_file_generated=util.clamp(last_file_generated+d,1,last_file)
    debounce_load=4
  end
end

function key(k,z)
  if k==2 and z==1 then
    make_beat()
  elseif k==3 and z==1 then
    playing=not playing
    if not playing then
      engine.amp(0)
    else
      engine.amp(1)
      lattice_beats=-1
      lattice:hard_restart()
    end
  end

end

function redraw()
  screen.clear()
  screen.level(15)
  if last_file_generated~=nil then
    screen.move(64,32-15)
    screen.text_center(last_tempo_generated.."_"..last_file_generated)
  end
  if loading==true then
    screen.move(64,32)
    screen.text_center("installing aubio and sox . . . ")
  else
    if util.file_exists("/tmp/breaktemp-progress") then
      draw_progress()
    else
      if making_beat==true then
        debounce_load=1
        making_beat=false
      end
      screen.move(64,32-5)
      screen.text_center("press K2 to generate beat")
      if last_file_generated~=nil then
        screen.move(64,32+5)
        screen.text_center("press K3 to stop/start beat")
      end
    end
  end
  screen.update()
end

slider=UI.Slider.new(4,55,118,8,0,0,100,{},"right")
slider.label="progress"
function draw_progress()
  local _,filename,_=string.match(params:get("break_file"),"(.-)([^\\/]-%.?([^%.\\/]*))$")
  screen.move(64,32-5)
  screen.text_center(string.format("generating beat from"))
  screen.move(64,32+5)
  screen.text_center(string.format("'%s'",filename))
  local progress=tonumber(util.os_capture("tail -n1 /tmp/breaktemp-progress"))
  if progress==nil then
    do return end
  end
  slider:set_value(progress)
  slider:redraw()
end
