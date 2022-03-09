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
lattice_=require("lattice")
UI=require("ui")

engine.name="Makebreakbeat"

PROGRESS_FILE="/tmp/mangler/breaktemp-progress"
max_index=0
samplei=1
shift=false

function os.cmd(cmd)
  print(cmd)
  os.execute(cmd.." 2>&1")
end

audi_o={}
function audi_o.length(fname)
  local s=os.capture("sox "..fname.." -n stat 2>&1  | grep Length | awk '{print $3}'")
  return tonumber(s)
end

function init()
  sample={}
  for i=1,3 do
    sample[i]={playing=false,index=0,beats=0,beats_offset=0,debounce_index=nil}
  end
  startup_done=false
  current_tempo=clock.get_tempo()
  max_index=get_max_index()

  params:add{type='binary',name="make beat",id='break_make',behavior='trigger',action=function(v) make_beat() end}
  params:add_file("break_file","load sample",_path.audio.."makebreakbeat/amen_resampled.wav")
  params:add{type="number",id="break_beats",name="beats",min=16,max=128,default=32}
  do_params()

  lattice=lattice_:new()
  lattice_beats=-1
  pattern=lattice:new_pattern{
    action=function(t)
      if clock.get_tempo()~=current_tempo then
        current_tempo=clock.get_tempo()
        max_index=get_max_index()
      end
      if not startup_done then
        startup_done=true
        do_startup()
      end
      lattice_beats=lattice_beats+1
      for i=1,3 do
        if sample[i].beats>0 then
          if (lattice_beats-sample[i].beats_offset)%sample[i].beats==0 then
            print("mbb: resetting sample "..i)
            engine.tozero(i)
          end
        end
        if sample[i].debounce_index~=nil then
          sample[i].debounce_index=sample[i].debounce_index-1
          if sample[i].debounce_index==0 then
            sample[i].debounce_index=nil
            if sample[i].index>0 then
              local fname=filename_from_index(sample[i].index)
              if util.file_exists(fname) then
                engine.load_track(i,fname)
                sample[i].beats=audi_o.length(fname)/(60/clock.get_tempo())
              end
            end
          end
        end
      end
      redraw()
    end,
    division=1/4
  }
  lattice:start()

  params:default()
end

function filename_from_index(index)
  local tempo=math.floor(clock.get_tempo())
  return _path.audio.."makebreakbeat/"..tempo.."_"..index..".wav"
end

function get_max_index()
  local tempo=math.floor(clock.get_tempo())
  local mi=0
  for i=1,1000 do
    if not util.file_exists(filename_from_index(i)) then
      break
    end
    mi=i
  end
  return mi
end

function toggle_sample(i)
  sample[i].playing=not sample[i].playing
  if not sample[i].playing then
    engine.amp(i,0)
  else
    engine.amp(i,1)
  end
end

function enc(k,d)
  if k==2 then
    samplei=util.clamp(samplei+(d>0 and 1 or-1),1,3)
  elseif k==3 then
    if last_file_generated~=nil then
      d=d>0 and 1 or-1
      sample[samplei].index=util.clamp(sample[samplei]+d,0,max_index)
      sample[samplei].debounce_index=4
    end
  end
end

function key(k,z)
  if k==1 then
    shift=z==1
  elseif k==2 and z==1 then
    make_beat()
  elseif k==3 and z==1 then
    if shift then
      lattice_beats=-1
      lattice:hard_restart()
    else
      toggle_sample(samplei)
    end
  end

end

function redraw()
  screen.clear()
  screen.level(15)
  for i=1,3 do
    local x=128/4*i
    local icon=UI.PlaybackIcon.new(x,1,6,4)
    icon.status=sample[samplei].playing and 1 or 4
    icon:redraw()
    screen.move(x,10)
    screen.text(""..(sample[samplei].index==0 and "none" or sample[samplei].index))
  end
  if last_file_generated~=nil then
    screen.move(64,32-15)
    screen.text_center(last_tempo_generated.."_"..last_file_generated)
  end
  if loading==true then
    screen.move(64,32)
    screen.text_center("installing aubio and sox . . . ")
  else
    if util.file_exists(PROGRESS_FILE) then
      draw_progress()
    else
      if making_beat==true then
        debounce_load=4
        making_beat=false
        playing=true
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
  local progress=tonumber(util.os_capture("tail -n1 "..PROGRESS_FILE))
  if progress==nil then
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
