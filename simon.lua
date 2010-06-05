-- class.lua
-- Compatible with Lua 5.1 (not 5.0).
function class(base, init)
  local c = {}    -- a new class instance
  if not init and type(base) == 'function' then
    init = base
    base = nil
  elseif type(base) == 'table' then
    -- our new class is a shallow copy of the base class!
    for i,v in pairs(base) do
      c[i] = v
    end
    c._base = base
  end
  -- the class will be the metatable for all its objects,
  -- and they will look up their methods in it.
  c.__index = c

  -- expose a constructor which can be called by <classname>(<args>)
  local mt = {}
  mt.__call = function(class_tbl, ...)
    local obj = {}
    setmetatable(obj,c)
    if init then
      init(obj,...)
    else 
      -- make sure that any stuff from the base class is initialized!
      if base and base.init then
        base.init(obj, ...)
      end
    end
    return obj
  end
  c.init = init
  c.is_a = function(self, klass)
    local m = getmetatable(self)
    while m do 
      if m == klass then return true end
      m = m._base
    end
    return false
  end
  setmetatable(c, mt)
  return c
end

-- Initialize the pseudo random number generator
math.randomseed( os.time() )

Game = class(function(game,level)
  game.level = 0
  game.steps = {}
  game:start_next_level()
  game.played = false
  game.snd = nil
end)

function Game:start_next_level()
  self.level = self.level+1
  table.insert(self.steps,math.random(4))
  self.cursor = 1
end

function Game:restart_level()
  self.cursor = 1
  print("..xx..")
end

function Game:next_step()
  return self.steps[self.cursor]
end

function Game:prev_step()
  return self.steps[self.cursor-1]
end

function Game:do_step(step)
  if self.steps[self.cursor] == step then
    self.cursor = self.cursor+1
    return true
  else
    return false
  end
end

function Game:cleared()
  return self.cursor > #self.steps
end


Button = class(function(btn,number)
  btn.number = number
  btn.imgoff = elf.CreateTextureFromFile("resources/simon"..number..".png")
  btn.imgover = elf.CreateTextureFromFile("resources/simon"..number.."over.png")
  btn.imglight = elf.CreateTextureFromFile("resources/simon"..number.."light.png")
  btn.snd = elf.LoadSound("resources/snd"..number..".ogg")
  btn.btn = elf.CreateButton('SndBtn'..number)
  elf.SetButtonOffTexture(btn.btn, btn.imgoff) 
  elf.SetButtonOverTexture(btn.btn, btn.imgover) 
  elf.SetButtonOnTexture(btn.btn, btn.imglight)
end)

function Button:rx()
  return elf.GetGuiObjectSize(self.btn).x
end

function Button:ry()
  return elf.GetGuiObjectSize(self.btn).y
end

function Button:highlight()
  self.pic = elf.CreatePicture("ButtonHihighlight"..self.number)
  elf.SetPictureTexture(self.pic, self.imglight)
  elf.AddGuiObject(gui, self.pic)
  size = elf.GetGuiObjectPosition(self.btn)
  elf.SetGuiObjectPosition(self.pic, size.x, size.y)
end

function Button:dehighlight()
  if self.pic then
    elf.RemoveGuiObjectByObject(gui, self.pic)
    self.pic = nil
  end
end

-- set window title 
elf.SetTitle("The Simon's blendelf")

-- limit fps
elf.SetFpsLimit(25)

-- create and set a gui
gui = elf.CreateGui()
elf.SetGui(gui)

-- elf logo
tex = elf.CreateTextureFromFile("resources/Elf.png")
pic = elf.CreatePicture("ELFLogo")
elf.SetPictureTexture(pic, tex)
elf.AddGuiObject(gui, pic)
size = elf.GetGuiObjectSize(pic)
elf.SetGuiObjectPosition(pic, elf.GetWindowWidth()-size.x, 0)

-- create font for labels
font = elf.CreateFontFromFile('resources/FreeSans.ttf', 26)

-- New game at level one
game = Game(1)

-- tracked info
functions = {
  function() return "The Simon's elf under "..elf.GetVersion() end,
  -- function() return "FPS: " .. elf.GetFps() end,
  function() return "Level: "..game.level end,
}

-- create text list for text
txt = elf.CreateTextList("TXTlist")
elf.SetTextListFont(txt,font)
elf.SetTextListSize(txt,# functions,elf.GetWindowWidth()-16)
elf.SetGuiObjectPosition(txt, 8, 8)
elf.AddGuiObject(gui, txt)

-- create musical buttons
coords = {{0,0},{1,0},{0,1},{1,1}}
snds = {}
for i = 1,4,1 do
  table.insert(snds,Button(i))
  local last = snds[#snds]
  elf.SetGuiObjectPosition(last.btn, 
    (elf.GetWindowWidth()-last:rx()*2)/2+coords[i][1]*last:rx(),
    (elf.GetWindowHeight()-last:ry()*2)/2+coords[i][2]*last:ry())
  elf.AddGuiObject(gui, last.btn)
end

-- create menu
btns = {
  {
    name = 'ExitButton',
    images = {"resources/btnoff.png","resources/btnover.png","resources/btnon.png"},
    clicked = "elf.Quit()"
  },
  {
    name = 'RepeatButton',
    images = {"resources/repeatoff.png","resources/repeatover.png","resources/repeaton.png"},
    clicked = [[
    game:restart_level()
    game.snd = nil
    game.played = false
    ]]
  }
}

for i,b in ipairs(btns) do
  exbtexoff  = elf.CreateTextureFromFile(b.images[1])
  exbtexover = elf.CreateTextureFromFile(b.images[2])
  exbtexon   = elf.CreateTextureFromFile(b.images[3])
  b.elf_btn  = elf.CreateButton(b.name) 
  elf.SetButtonOffTexture(b.elf_btn, exbtexoff) 
  elf.SetButtonOverTexture(b.elf_btn, exbtexover) 
  elf.SetButtonOnTexture(b.elf_btn, exbtexon) 
  size = elf.GetGuiObjectSize(b.elf_btn)
  elf.SetGuiObjectPosition(b.elf_btn, 
  elf.GetWindowWidth()-size.x, 
  elf.GetWindowHeight()-(size.y*(i))
  )

  exscr = elf.CreateScript() 
  elf.SetScriptText(exscr, b.clicked) 
  elf.SetGuiObjectScript(b.elf_btn, exscr) 
  elf.AddGuiObject(gui, b.elf_btn)
end

-- main loop
while elf.Run()==true do
  -- uptade text info
  elf.RemoveTextListItems( txt )
  for i,v in ipairs(functions) do
    elf.AddTextListItem(txt, v() )
  end

  -- -- check mouse interection when not in playing mode
  if game.played==true then
    for indx,i in ipairs(snds) do
      if elf.GetGuiObjectEvent(i.btn) == elf.CLICKED then
        if(game:do_step(indx)==true) then
          game.snd = elf.PlaySound(i.snd,1.0)
          if(game:cleared()==true) then
            game:start_next_level()
            game.played = false
          end
        else
          elf.PlaySound(i.snd,0.3)
        end
      end
    end
    -- play current steps first
  else
    if not (game.snd~=nil and elf.IsSoundPlaying(game.snd)==true) then
      if game:prev_step()~=nil then
        snds[game:prev_step()]:dehighlight()
      end
      if not game:cleared()==true then
        print(game:next_step())
        game.snd = elf.PlaySound(snds[game:next_step()].snd,1.0)
        snds[game:next_step()]:highlight()
        game:do_step(game:next_step())
      else
        game:restart_level()
        game.snd = nil
        game.played = true
      end
    end  
  end

end
