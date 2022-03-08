math.randomseed(os.time())

debugging=true
function os.file_exists(name)
  local f=io.open(name,"r")
  if f~=nil then
    io.close(f)
    return true
  else
    return false
  end
end

function os.capture(cmd,raw)
  local f=assert(io.popen(cmd,'r'))
  local s=assert(f:read('*a'))
  f:close()
  if raw then return s end
  s=string.gsub(s,'^%s+','')
  s=string.gsub(s,'%s+$','')
  s=string.gsub(s,'[\n\r]+',' ')
  return s
end

function os.cmd(cmd)
  if debugging then
    print(cmd)
  end
  os.execute(cmd.." 2>&1")
end

local snare_file="snare.wav"
local kick_file="kick.wav"
local debugging=false
local save_onset=false
local charset={}

-- qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890
for i=48,57 do table.insert(charset,string.char(i)) end
for i=65,90 do table.insert(charset,string.char(i)) end
for i=97,122 do table.insert(charset,string.char(i)) end

function string.random(length)
  if length>0 then
    return string.random(length-1)..charset[math.random(1,#charset)]
  else
    return ""
  end
end

function string.random_filename(suffix,prefix)
  suffix=suffix or ".wav"
  prefix=prefix or "/tmp/breaktemp-"
  return prefix..string.random(8)..suffix
end

function math.round(number,quant)
  if quant==0 then
    return number
  else
    return math.floor(number/(quant or 1)+0.5)*(quant or 1)
  end
end

function math.std(numbers)
  local mu=math.average(numbers)
  local sum=0
  for _,v in ipairs(numbers) do
    sum=sum+(v-mu)^2
  end
  return math.sqrt(sum/#numbers)
end

function math.average(numbers)
  if next(numbers)==nil then
    do return end
  end
  local total=0
  for _,v in ipairs(numbers) do
    total=total+v
  end
  return total/#numbers
end

function math.trim(numbers,std_num)
  local mu=math.average(numbers)
  local std=math.std(numbers)
  local new_numbers={}
  for _,v in ipairs(numbers) do
    if v>mu-(std*std_num) and v<mu+(std*std_num) then
      table.insert(new_numbers,v)
    end
  end
  return math.average(new_numbers)
end

function table.clone(org)
  return {table.unpack(org)}
end

function table.merge(t1,t2)
  n=#t1
  for i=1,#t2 do
    t1[n+i]=t2[i]
  end
end

function table.reverse(t)
  local len=#t
  for i=len-1,1,-1 do
    t[len]=table.remove(t,i)
  end
end

function table.permute(t,n,count)
  n=n or #t
  for i=1,count or n do
    local j=math.random(i,n)
    t[i],t[j]=t[j],t[i]
  end
end

function table.shuffle(tbl)
  for i=#tbl,2,-1 do
    local j=math.random(i)
    tbl[i],tbl[j]=tbl[j],tbl[i]
  end
end

function table.add(t,scalar)
  for i,_ in ipairs(t) do
    t[i]=t[i]+scalar
  end
end

function table.is_empty(t)
  return next(t)==nil
end

function table.get_rotation(t)
  local t2={}
  local v1=0
  for i,v in ipairs(t) do
    if i>1 then
      table.insert(t2,v)
    else
      v1=v
    end
  end
  table.insert(t2,v1)
  return t2
end

function table.average(t)
  local sum=0
  for _,v in pairs(t) do
    sum=sum+v
  end
  return sum/#t
end

function table.rotate(t)
  for i,v in ipairs(table.get_rotation(t)) do
    t[i]=v
  end
end

function table.rotatex(t,d)
  if d<0 then
    table.reverse(t)
  end
  local d_abs=math.abs(d)
  if d_abs>0 then
    for i=1,d_abs do
      table.rotate(t)
    end
  end
  if d<0 then
    table.reverse(t)
  end
end

function table.clone(org)
  return {table.unpack(org)}
end

function table.copy(t)
  local t2={}
  for i,v in ipairs(t) do
    table.insert(t2,v)
  end
  return t2
end

function table.print(t)
  for i,v in ipairs(t) do
    print(i,v)
  end
end

function table.print_matrix(m)
  for _,v in ipairs(m) do
    local s=""
    for _,v2 in ipairs(v) do
      s=s..v2.." "
    end
    print(s)
  end
end

function table.get_change(m)
  local total_change=0
  for col=1,#m[1] do
    local last_val=0
    for row=1,#m do
      local val=m[row][col]
      if row>1 then
        total_change=total_change+math.abs(val-last_val)
      end
      last_val=val
    end
  end
  return total_change
end

function table.minimize_row_changes(m)
  local m_=table.clone(m)
  -- generate random rotations
  local best_change=100000
  local best_m={}
  for i=1,10000 do
    -- rotate a row randomly
    local random_row=math.random(1,#m)
    m_[random_row]=table.get_rotation(m_[random_row])
    local change=table.get_change(m_)
    if change<best_change then
      best_change=change
      best_m=table.clone(m_)
    end
  end
  return best_m
  -- table.print_matrix(best_m)
end

function table.contains(t,x)
  for _,v in ipairs(t) do
    if v==x then
      do return true end
    end
  end
  return false
end

-- lfo goes from 0 to 1
function math.lfo(t,period,phase)
  return (math.sin(2*3.14159265/period+phase)+1)/2
end

local audio={}

function audio.tempo(fname)
  local audio_length=audio.length(fname)
  local closet_bpm={0,100000}
  for bpm=100,200 do 
    local measures=audio_length/((60/bpm)*4)
    if math.round(measures)%2==0 then 
      local dif=math.abs(math.round(measures)-measures)
      dif=dif-math.round(measures)/60
      -- print(bpm,math.round(measures),measures,dif)
      if dif<closet_bpm[2] then 
        closet_bpm[2]=dif 
        closet_bpm[1]=bpm
      end
    end
  end
  return closet_bpm[1]
end

function audio.length(fname)
  local s=os.capture("sox "..fname.." -n stat 2>&1  | grep Length | awk '{print $3}'")
  return tonumber(s)
end

function audio.mean_norm(fname)
  local s=os.capture("sox "..fname.." -n stat 2>&1  | grep Mean | grep norm | awk '{print $3}'")
  return tonumber(s)
end

function audio.silence_add(fname,silence_length)
  local sample_rate,channels=audio.get_info(fname)
  local silence_file=string.random_filename()
  local fname2=string.random_filename()
  -- first create the silence
  os.cmd("sox -n -r "..sample_rate.." -c "..channels.." "..silence_file.." trim 0.0 "..silence_length)
  -- combine with original file
  os.cmd("sox "..fname.." "..silence_file.." "..fname2)
  os.cmd("rm "..silence_file)
  return fname2
end

function audio.silence_trim(fname)
  local fname2=string.random_filename()
  os.cmd("sox "..fname.." "..fname2.." silence 1 0.1 0.025% reverse silence 1 0.1 0.025% reverse")
  return fname2
end

function audio.trim(fname,start,length)
  local fname2=string.random_filename()
  if length==nil then
    os.cmd("sox "..fname.." "..fname2.." trim "..start)
  else
    os.cmd("sox "..fname.." "..fname2.." trim "..start.." "..length)
  end
  return fname2
end

function audio.reverse(fname)
  local fname2=string.random_filename()
  os.cmd(string.format("sox %s %s reverse",fname,fname2))
  return fname2
end

function audio.pitch(fname,notes)
  local fname2=string.random_filename()
  os.cmd(string.format("sox %s %s pitch %d",fname,fname2,notes*100))
  return fname2
end

function audio.join(fnames)
  local fname2=string.random_filename()
  os.cmd(string.format("sox %s %s",table.concat(fnames," "),fname2))
  return fname2
end

function audio.repeat_n(fname,repeats)
  local fname2=string.random_filename()
  os.cmd(string.format("sox %s %s repeat %d",fname,fname2,repeats))
  return fname2
end

function audio.get_info(fname)
  local sample_rate=tonumber(os.capture("sox --i "..fname.." | grep 'Sample Rate' | awk '{print $4}'"))
  local channels=tonumber(os.capture("sox --i "..fname.." | grep 'Channels' | awk '{print $3}'"))
  return sample_rate,channels
end

-- copy_and_paste2 finds best positionn, but does not keep timing
function audio.copy_and_paste2(fname,copy_start,copy_stop,paste_start)
	local copy_length=copy_stop-copy_start
	local piece=string.random_filename()
	local part1=string.random_filename()
	local part2=string.random_filename()
	local fname2=string.random_filename()
	local e=5/1000 
	local l=5/1000
	os.cmd(string.format("sox %s %s trim %f %f",fname,piece,copy_start-e-l,copy_stop-copy_start+e+l+e))
	os.cmd(string.format("sox %s %s trim 0 %f",fname,part1,paste_start+e))
	os.cmd(string.format("sox %s %s trim %f",fname,part2,paste_start+copy_stop-copy_start-e-l))
	os.cmd(string.format("sox %s %s %s %s splice %f %f",part1,piece,part2,fname2,paste_start+e,paste_start+e+copy_stop-copy_start+e+l+e))
	return fname2
end

function audio.copy_and_paste(fname,copy_start,copy_stop,paste_start,crossfade)
	local copy_length=copy_stop-copy_start
	local piece=string.random_filename()
	local part1=string.random_filename()
	local part2=string.random_filename()
	local fname2=string.random_filename()
	local splice1=string.random_filename()
	local e=crossfade or 0.1 
	local l=0 -- no leeway
	os.cmd(string.format("sox %s %s trim %f %f",fname,piece,copy_start-e,copy_length+2*e))
	os.cmd(string.format("sox %s %s trim 0 %f",fname,part1,paste_start+e))
	os.cmd(string.format("sox %s %s trim %f",fname,part2,paste_start+copy_length-e))
	os.cmd(string.format("sox %s %s %s splice %f,%f,%f",part1,piece,splice1,paste_start+e,e,l))
	os.cmd(string.format("sox %s %s %s splice %f,%f,%f",splice1,part2,fname2,paste_start+copy_length+e,e,l))
	return fname2
end

-- pastes any piece into a place in the audio
-- assumes that the piece has "crossfade" length on both sides
-- in addition to its current length
function audio.paste(fname,piece,paste_start,crossfade)
	local copy_length=audio.length(piece)
	local part1=string.random_filename()
	local part2=string.random_filename()
	local fname2=string.random_filename()
	local splice1=string.random_filename()
	local e=crossfade or 0.1 
	local l=0 -- no leeway
	os.cmd(string.format("sox %s %s trim 0 %f",fname,part1,paste_start+e))
	os.cmd(string.format("sox %s %s trim %f",fname,part2,paste_start+copy_length-e*3))
	os.cmd(string.format("sox %s %s %s splice %f,%f,%f",part1,piece,splice1,paste_start+e,e,l))
	os.cmd(string.format("sox %s %s %s splice %f,%f,%f",splice1,part2,fname2,paste_start+copy_length+e,e,l))
	return fname2
end

function audio.gain(fname,gain)
  local fname2=string.random_filename()
  os.cmd(string.format("sox %s %s gain %f",fname,fname2,gain))
  return fname2
end

function audio.stretch(fname,stretch)
  local fname2=string.random_filename()
  os.cmd(string.format("sox %s %s stretch %f",fname,fname2,stretch))
  return fname2
end

function audio.stutter(fname,stutter_length,pos_start,count,crossfade_piece,crossfade_stutter,gain_amt)
	crossfade_piece=0.1 or crossfade_piece
	crossfade_stutter=0.005 or crossfade_stutter
	local partFirst=string.random_filename()
	local partMiddle=string.random_filename()
	local partLast=string.random_filename()
	os.cmd(string.format("sox %s %s trim %f %f",fname,partFirst,pos_start-crossfade_piece,stutter_length+crossfade_piece+crossfade_stutter))
	os.cmd(string.format("sox %s %s trim %f %f",fname,partMiddle,pos_start-crossfade_stutter,stutter_length+crossfade_stutter+crossfade_stutter))
	os.cmd(string.format("sox %s %s trim %f %f",fname,partLast,pos_start-crossfade_stutter,stutter_length+crossfade_piece+crossfade_stutter))
  gain_amt=gain_amt or (count>8 and -1.5 or -2)
	for i=1,count do 
		local fnameNext=""
		if i==1 then 
			fnameNext=audio.gain(partFirst,gain_amt*(count-i))
		else
			fnameNext=string.random_filename()
      local fnameMid=i<count and partMiddle or partLast 
      if gain_amt~=0 then 
        fnameMid=audio.gain(fnameMid,gain_amt*(count-i))
      end
			os.cmd(string.format("sox %s %s %s splice %f,%f,0",fname2,fnameMid,fnameNext,audio.length(fname2),crossfade_stutter))
		end
		fname2=fnameNext
	end
	return fname2
end

function audio.supercollider_effect(fname,effect)
  local fname2=string.random_filename()
  local durationScaling=1 
  if effect=="reverberate" then 
    durationScaling=4
  end
  os.cmd(string.format('sendosc --host 127.0.0.1 --addr "/score" --port 57113 --recv-port 8888 -s %s -s %s -s %s -s %s -s 8888',fname,fname2,effect,durationScaling))
  return fname2
end


os.cmd('sendosc --host 127.0.0.1 --addr "/quit" --port 57113')
os.cmd("sclang nrt_server.sc > /dev/null 2>&1 &")
os.cmd("sleep 3")
os.cmd("rm -f /tmp/breaktemp-*")
local fname="172-32-100.wav"
-- local fname="Bpm124_Blink01_PL_key_bpm124.wav"
-- local fname="amen_resampled.wav"
local bpm=audio.tempo(fname)
fname=audio.silence_trim(fname)
print("bpm guess",bpm)
fname=audio.silence_add(fname,0.1)
local beats=math.floor(audio.length(fname)/(60/bpm))
fname=audio.trim(fname,0,beats*60/bpm)
beats=audio.length(fname)/(60/bpm)
print(beats)

fname=audio.repeat_n(fname,4)
local total_beats=math.floor(audio.length(fname)/(60/bpm))
print(total_beats)
os.cmd("cp "..fname.." original.wav")


local fname_original=fname
-- copy and pitch and paste
for i=1,3 do 
	local start_beat=math.random(8,total_beats-8)
	local length_beat=math.random(1,4)/8
	local paste_beat=start_beat
	local crossfade=0.005
	local piece=audio.pitch(audio.trim(fname,60/bpm*start_beat-crossfade,60/bpm*length_beat+crossfade*2),2)
	fname=audio.paste(fname,piece,60/bpm*paste_beat,crossfade)
end
-- basic copy and paste
for i=1,40 do 
	local start_beat=math.random(4,total_beats-4)*2
	local length_beat=math.random(1,3)*2
  local paste_beat=math.random(8,total_beats-length_beat/2-8)*2
  local crossfade=0.05
	fname=audio.copy_and_paste(fname,60/bpm/2*start_beat,60/bpm/2*(start_beat+length_beat),60/bpm/2*paste_beat,crossfade)
end
-- copy and reverse and paste
for i=1,4 do 
  local start_beat=math.random(2,total_beats-2)*2
  local length_beat=math.random(1,3)
  local paste_beat=math.random(2,math.floor(total_beats-total_beats/2-4))*2
  local crossfade=0.05
  local piece=audio.reverse(audio.trim(fname,60/bpm/2*start_beat-crossfade,60/bpm/2*length_beat+crossfade*2))
  fname=audio.paste(fname,piece,60/bpm/2*paste_beat,crossfade)
end
-- copy and reverberate and paste
for i=1,4 do 
  local start_beat=math.random(3,total_beats-3)
  local length_beat=math.random(1,2)
  local paste_beat=math.random(2,math.floor(total_beats-total_beats/2-4))*2
  local crossfade=0.005
  local piece=audio.trim(fname_original,60/bpm*start_beat-crossfade,60/bpm/4*length_beat+crossfade*2)
  piece=audio.supercollider_effect(piece,"reverberate")
  piece=audio.reverse(piece)
  fname=audio.paste(fname,piece,60/bpm/2*paste_beat,crossfade)
end
-- -- copy and stretch and paste
-- for i=1,2 do 
--   local start_beat=math.random(4,total_beats*2-4)
--   local length_beat=math.random(1,4)
--   local paste_beat=math.random(4,total_beats*2-4-length_beat)
--   local crossfade=0.05
--   local piece=audio.stretch(audio.trim(fname,60/bpm/2*start_beat-crossfade,60/bpm/4*length_beat+crossfade*2),2)
--   fname=audio.paste(fname,piece,60/bpm/2*paste_beat,crossfade)
-- end
-- copy and stutter and paste
for i=1,3 do 
  local crossfade=0.005
  local beat_start=math.random(4,total_beats-4)
  local piece=audio.stutter(fname_original,60/bpm/4,60/bpm*beat_start,12,crossfade,0.001,nil)
  if math.random()<0.5 then 
    piece=audio.supercollider_effect(piece,"lpf_rampup")
  end
  fname=audio.paste(fname,piece,60/bpm/4*math.random(16,total_beats*4-16),crossfade)
end
-- for i=1,2 do 
--   local crossfade=0.005
--   local beat_start=math.random(4,total_beats*4-4)
--   local piece=audio.stutter(fname_original,60/bpm/4,60/bpm/4*beat_start,8,crossfade,0.001)
--   fname=audio.paste(fname,piece,60/bpm/4*math.random(16,total_beats*4-16),crossfade)
-- end
-- for i=1,2 do 
--   local crossfade=0.005
--   local beat_start=math.random(4,total_beats*4-4)
--   local piece=audio.stutter(fname_original,60/bpm/4,60/bpm/4*beat_start,4,crossfade,0.001)
--   fname=audio.paste(fname,piece,60/bpm/4*math.random(16,total_beats*4-16),crossfade)
-- end
-- cleanup
os.cmd("cp "..fname.." mangled.wav")
os.cmd('sendosc --host 127.0.0.1 --addr "/quit" --port 57113')





-- -- choose a random portion to excise
-- local excise={start=60/bpm*3,len=60/bpm*4} -- start and length
-- fname_i=audio.trim(fname,excise.start,excise.len)
-- fname_l=audio.trim(fname,0,excise.start)
-- fname_r=audio.trim(fname,excise.start+excise.len)

-- excise={start=60/bpm*16,len=60/bpm*4} -- start and length
-- fname_i2=audio.trim(fname,excise.start,excise.len)

-- fname=audio.join({fname_l,fname_i2,fname_r},true)
-- os.cmd("cp "..fname.." 4.wav")
-- create long version

-- sox 1_silent.wav 2.wav trim 0 6 # trim to closet number of beats
-- sox 2.wav 3.wav repeat 8

--   # excise
--   sox 3.wav ei.wav trim 3 1.5 reverse
--   sox 3.wav el.wav trim 0 3
--   sox 3.wav er.wav trim 4.5
--   sox el.wav ei.wav er.wav efull.wav

