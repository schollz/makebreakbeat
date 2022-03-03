-- make break beats

lattice_=require("lattice")
UI = require("ui")


ooo={}

local ooomem={
  bnds={1,1,90,90,180,180,270,270},
  levels={0.5,0.5,0.5},
  rates={1,1,1},
  rate_factor={1,1,1},
  slews={1,1,1},
}

function ooo.init(num)
  if num==nil then
    num=3
  end
  -- setup three stereo loops
  softcut.reset()
  softcut.buffer_clear()
  audio.level_eng_cut(1)
  audio.level_tape_cut(1)
  audio.level_adc_cut(1)
  for i=1,6 do
    if i<=num*2 then
      softcut.enable(i,1)
      softcut.level(i,0.5)

      if i%2==1 then
        softcut.pan(i,1)
        softcut.buffer(i,1)
        softcut.level_input_cut(1,i,1)
        softcut.level_input_cut(2,i,0)
      else
        softcut.pan(i,-1)
        softcut.buffer(i,2)
        softcut.level_input_cut(1,i,0)
        softcut.level_input_cut(2,i,1)
      end

      softcut.rec(i,0)
      softcut.play(i,1)
      softcut.rate(i,1)
      softcut.loop_start(i,0)
      softcut.loop_end(i,200)
      softcut.position(i,0)
      softcut.loop(i,1)

      softcut.level_slew_time(i,0.4)
      softcut.rate_slew_time(i,0.4)
      softcut.pan_slew_time(i,0.4)
      softcut.recpre_slew_time(i,0.4)

      softcut.rec_level(i,0.0)
      softcut.pre_level(i,1.0)
      softcut.phase_quant(i,0.025)

      softcut.post_filter_dry(i,0.0)
      softcut.post_filter_lp(i,1.0)
      softcut.post_filter_rq(i,1.0)
      softcut.post_filter_fc(i,20000)

      softcut.pre_filter_dry(i,1.0)
      softcut.pre_filter_lp(i,1.0)
      softcut.pre_filter_rq(i,1.0)
      softcut.pre_filter_fc(i,20000)

      softcut.fade_time(i,0.1)
    else
      softcut.enable(i,0)
    end
  end
end

function ooo.fade_time(i,x)
  for j=i*2-1,i*2 do
    softcut.fade_time(j,x)
  end
end

function ooo.loop(i,start,stop)
  for j=i*2-1,i*2 do
    softcut.loop_start(j,ooomem.bnds[j]+start)
    softcut.loop_end(j,ooomem.bnds[j]+stop)
    softcut.position(j,ooomem.bnds[j]+start)
  end
end

function ooo.stop(i)
  for j=i*2-1,i*2 do
    softcut.rate(j,0)
    softcut.level(j,0)
  end
end

function ooo.rate(i,r)
  ooomem.rates[i]=r
  for j=i*2-1,i*2 do
    softcut.rate(j,r*ooomem.rate_factor[i])
  end
end

function ooo.rec(i,v,v2)
  for j=i*2-1,i*2 do
    softcut.rec_level(j,v)
    softcut.pre_level(j,v2)
  end
end

function ooo.slew(i,v)
  ooomem.slews[i]=v
  for j=i*2-1,i*2 do
    softcut.rate_slew_time(j,v)
    softcut.level_slew_time(j,v)
    softcut.pan_slew_time(j,v)
    softcut.recpre_slew_time(j,v)
  end
end

function ooo.level(i,v)
  ooomem.levels[i]=v
  for j=i*2-1,i*2 do
    softcut.level(j,v)
  end
end

function ooo.pan(i,v)
  v=v*2
  if v>0 then
    softcut.pan(i*2,util.clamp(v-1,-1,1))
    softcut.pan(i*2-1,1)
  else
    softcut.pan(i*2,-1)
    softcut.pan(i*2-1,util.clamp(1+v,-1,1))
  end
end

function ooo.start(i)
    ooo.seek(i,0)
  for j=i*2-1,i*2 do
    softcut.rate_slew_time(j,0)
    softcut.rate(j,ooomem.rates[i]*ooomem.rate_factor[i])
    softcut.level(j,ooomem.levels[i])
    clock.run(function()
      clock.sleep(0.5)
      softcut.rate_slew_time(j,ooomem.slews[i])
    end)
  end
end

function ooo.stop(i)
    for j=i*2-1,i*2 do
        softcut.level(j,0)
    end
end

function ooo.seek(i,pos)
  for j=i*2-1,i*2 do
    softcut.position(j,ooomem.bnds[j]+pos)
  end
end

function ooo.load(i,filename)
  print("ooo.load",i,filename)
  local ch,samples,samplerate=audio.file_info(filename)
  local duration=samples/samplerate
  ooomem.rate_factor[i]=samplerate/48000
  softcut.buffer_read_stereo(filename,0,ooomem.bnds[i*2-1],-1,0,1)
  ooo.loop(i,0,duration)
  ooo.seek(i,0)
  ooo.start(i)
end

function init()
    ooo.init(1)
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
    for _, op in ipairs(break_options) do 
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
            if lattice_beats%params:get("break_beats")==0 then
                ooo.seek(1,0)
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
        fname=_path.audio.."makebreakbeat/"..tempo.."_"..i..".wav"
        if not util.file_exists(fname) then 
            break
        end
    end
    last_file_generated=fname
    local cmd="lua ".._path.code.."makebreakbeat/lib/dnb.lua --no-logo --snare-file /home/we/dust/code/makebreakbeat/lib/snare.wav --kick-file /home/we/dust/code/makebreakbeat/lib/kick.wav "
    cmd=cmd.." -t "..tempo.." -b "..(params:get("break_beats")+1)
    cmd=cmd.." -o "..fname.." ".." -i "..params:get("break_file")
    for _, op in ipairs(break_options) do 
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

function key(k,z)
    if k==2 and z==1 then
        make_beat()
    elseif k==3 and z==1 then
        playing=not playing 
        if not playing then
            ooo.stop(1)
        else
            ooo.start(1)
            lattice_beats=-1
            lattice:hard_restart()
        end
    end

end

function redraw()
    screen.clear()
    screen.level(15)
    if loading==true then
        screen.move(64,32)
        screen.text_center("installing aubio and sox . . . ")
    else
        if util.file_exists("/tmp/breaktemp-progress")  then
            draw_progress()     
        else
            if making_beat==true then
                ooo.load(1,last_file_generated)
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

slider = UI.Slider.new(4,55,118,8,0,0,100,{},"right")
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