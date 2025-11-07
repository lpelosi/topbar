-- addons/topbar/addon.lua
_addon.name, _addon.author, _addon.version = 'topbar','lanzone','1.1'
_addon.desc = 'Top HUD bar: main/sub jobs, levels, EXP to next, stats modifiers.'

local JOB_ABBR={[0]='NON',[1]='WAR',[2]='MNK',[3]='WHM',[4]='BLM',[5]='RDM',[6]='THF',[7]='PLD',[8]='DRK',
[9]='BST',[10]='BRD',[11]='RNG',[12]='SAM',[13]='NIN',[14]='DRG',[15]='SMN',[16]='BLU',[17]='COR',
[18]='PUP',[19]='DNC',[20]='SCH',[21]='GEO',[22]='RUN'}

local txt; local state={x=100,y=5}

local function try(obj,name,...) local f=obj and obj[name]; if type(f)=='function' then local ok,v=pcall(f,obj,...) if ok then return v end end end

local function init_font()
  if txt then return end
  local fm=AshitaCore:GetFontManager(); if not fm then return end
  txt=fm:Create('topbar_text')
  txt:SetFontFamily('Consolas'); txt:SetFontHeight(14); txt:SetBold(true)
  txt:SetColor(0xFFFFFFFF); txt:SetPositionX(state.x); txt:SetPositionY(state.y); txt:SetVisibility(true)
end

local function stringify_mods(v)
  local t = type(v)
  if t == 'nil' then return 'n/a' end
  if t == 'number' or t == 'string' or t == 'boolean' then return tostring(v) end
  if t == 'table' then
    local parts, count, limit = {}, 0, 12
    for k,val in pairs(v) do
      parts[#parts+1] = string.format('%s=%s', tostring(k), tostring(val))
      count = count + 1
      if count >= limit then break end
    end
    local s = table.concat(parts, ',')
    return s ~= '' and s or 'n/a'
  end
  return 'n/a'
end

local function read_player()
  local pm = AshitaCore:GetDataManager() and AshitaCore:GetDataManager():GetPlayer()
  if not pm then return end

  -- Jobs and levels
  local mj  = try(pm,'GetMainJob') or 0
  local sj  = try(pm,'GetSubJob') or 0
  local ml  = try(pm,'GetMainJobLevel') or 0
  local sl  = try(pm,'GetSubJobLevel') or 0

  -- EXP current and needed
  local cur = try(pm,'GetExpCurrent')
  local need= try(pm,'GetExpNeeded')
  local tnl = (type(cur)=='number' and type(need)=='number') and math.max(0, need - cur) or nil

  -- Stat modifiers
  local mods = try(pm,'GetStatsModifiers')
  local mods_str = stringify_mods(mods)

  return {
    main_abbr = JOB_ABBR[mj] or 'UNK', main_lv = ml,
    sub_abbr  = JOB_ABBR[sj] or 'UNK', sub_lv  = sl,
    tnl = tnl, mods = mods_str
  }
end

ashita.register_event('load', function() init_font() end)

ashita.register_event('unload', function()
  local fm=AshitaCore:GetFontManager(); if fm then fm:Delete('topbar_text') end
  txt=nil
end)

-- /topbar pos x y  |  /topbar probe
ashita.register_event('command', function(cmd)
  cmd=cmd:lower(); if not cmd:find('^/topbar') then return false end
  local a={}; for w in cmd:gmatch('%S+') do a[#a+1]=w end
  if a[2]=='pos' and a[3] and a[4] then
    state.x=tonumber(a[3]) or state.x; state.y=tonumber(a[4]) or state.y
    if txt then txt:SetPositionX(state.x); txt:SetPositionY(state.y) end
    AshitaCore:GetChatManager():AddChatMessage(207,'[topbar] position updated'); return true
  elseif a[2]=='probe' then
    local pm=AshitaCore:GetDataManager():GetPlayer()
    for _,n in ipairs({'GetMainJob','GetSubJob','GetMainJobLevel','GetSubJobLevel','GetExpCurrent','GetExpNeeded','GetStatsModifiers'}) do
      local v=try(pm,n)
      AshitaCore:GetChatManager():AddChatMessage(207,('[topbar] %s = %s'):format(n, v==nil and 'nil' or type(v)=='table' and '<table>' or tostring(v)))
    end
    return true
  end
  AshitaCore:GetChatManager():AddChatMessage(207,'[topbar] usage: /topbar pos <x> <y> | /topbar probe'); return true
end)

ashita.register_event('render', function()
  if not txt then return end
  local p=read_player(); if not p then return end
  local exp_str = p.tnl and ('exp '..p.tnl) or 'exp n/a'
  local line = string.format('%s%d/%s%d | %s | stat modifiers: %s',
    p.main_abbr, p.main_lv, p.sub_abbr, p.sub_lv, exp_str, p.mods)
  txt:SetText(line)
end)