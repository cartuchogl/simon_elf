require 'elf'

class Game
  attr_accessor :level
  attr_accessor :steps
  attr_accessor :cursor
  
  attr_accessor :snd
  attr_accessor :played
  
  def initialize(level)
    start_level(level)
    self.played = false
    self.snd = nil
  end
  
  def start_level(level)
    self.level = level
    self.steps = Array.new(level) { |i| rand(4) }
    self.cursor = 0
  end
  
  def restart_level
    self.cursor = 0
    puts '..xx..'
  end
  
  def next_step
    self.steps[self.cursor]
  end
  
  def do_step(step)
    if self.steps[self.cursor] == step
      self.cursor+=1
      true
    else
      false
    end
  end
  
  def cleared?
    self.cursor>= self.steps.length
  end
end

class Button
  attr_accessor :snd
  attr_accessor :btn
  attr_accessor :imgover
  attr_accessor :imgoff
  def initialize(number)
    @imgoff = Elf.CreateTextureFromFile(File.join(File.dirname(__FILE__),"./resources/simon#{number}.png") )
    @imgover = Elf.CreateTextureFromFile(File.join(File.dirname(__FILE__),"./resources/simon#{number}over.png") )
    self.snd = Elf.LoadSound(File.join(File.dirname(__FILE__),"./resources/snd#{number}.ogg"))
    self.btn = Elf.CreateButton('SndBtn'+rand(20).to_s)
    Elf.SetButtonOffTexture(self.btn, @imgoff) 
    Elf.SetButtonOverTexture(self.btn, @imgover) 
    Elf.SetButtonOnTexture(self.btn, @imgoff)
  end
  
  def rx
    Elf.GetGuiObjectSize(@btn).x
  end
  
  def ry
    Elf.GetGuiObjectSize(@btn).y
  end
end

# Initialize blendelf
Elf.Init(800,600,"opening...",false)

# set window title 
Elf.SetTitle("BlendELF Simon's elf at #{Elf.GetWindowWidth}x#{Elf.GetWindowHeight}")

# limit fps
Elf.SetFpsLimit(25)

# create and set a gui
gui = Elf.CreateGui()
Elf.SetGui(gui)

# elf logo
tex = Elf.CreateTextureFromFile(File.join(File.dirname(__FILE__),"./resources/Elf.png"))
pic = Elf.CreatePicture("ELFLogo")
Elf.SetPictureTexture(pic, tex)
Elf.AddGuiObject(gui, pic)
size = Elf.GetGuiObjectSize(pic)
Elf.SetGuiObjectPosition(pic, Elf.GetWindowWidth()-size.x, 0)

# create font for labels
font = Elf.CreateFontFromFile(File.join(File.dirname(__FILE__),'./resources/FreeSans.ttf'), 26)

# New game at level one
game = Game.new 1

# tracked info
functions = [
	lambda do "The Simon's elf under #{Elf.GetVersion}" end,
  # lambda do "FPS: #{Elf.GetFps}" end,
	lambda do "Level: #{game.level}" end,
]

# create text list for text
txt = Elf.CreateTextList("TXTlist")
Elf.SetTextListFont(txt,font)
Elf.SetTextListSize(txt,functions.length,Elf.GetWindowWidth-16)
Elf.SetGuiObjectPosition(txt, 8, 8)
Elf.AddGuiObject(gui, txt)

# create musical buttons
coords = [[0,0],[1,0],[0,1],[1,1]]
snds = []
(1..4).each do |i| 
  snds << Button.new(i)
  Elf.SetGuiObjectPosition(snds.last.btn, 
    (Elf.GetWindowWidth-snds.last.rx*2)/2+coords[i-1].first*snds.last.rx,
    (Elf.GetWindowHeight-snds.last.ry*2)/2+coords[i-1].last*snds.last.ry)
  Elf.AddGuiObject(gui, snds.last.btn)
end

# create menu
btns = [
  {
    :name => 'ExitButton',
    :images=>["./resources/btnoff.png","./resources/btnover.png","./resources/btnon.png"],
    :clicked=>lambda do Elf.Quit end
  },
  {
    :name => 'RepeatButton',
    :images=>["./resources/repeatoff.png","./resources/repeatover.png","./resources/repeaton.png"],
    :clicked=>lambda do game.restart_level; game.snd = nil; game.played = false end
  }
]

btns.each do |b|
  exbtexoff = Elf.CreateTextureFromFile File.join(File.dirname(__FILE__), b[:images][0])
  exbtexover = Elf.CreateTextureFromFile(File.join(File.dirname(__FILE__),b[:images][1]) )
  exbtexon = Elf.CreateTextureFromFile(File.join(File.dirname(__FILE__),b[:images][2]) )
  b[:elf_btn] = Elf.CreateButton(b[:name]) 
  Elf.SetButtonOffTexture(b[:elf_btn], exbtexoff) 
  Elf.SetButtonOverTexture(b[:elf_btn], exbtexover) 
  Elf.SetButtonOnTexture(b[:elf_btn], exbtexon) 
  size = Elf.GetGuiObjectSize(b[:elf_btn])
  Elf.SetGuiObjectPosition(b[:elf_btn], Elf.GetWindowWidth-size.x, Elf.GetWindowHeight-(size.y*(btns.index(b)+1)))
  Elf.AddGuiObject(gui, b[:elf_btn])
end

# main loop
while Elf.Run do
  # uptade text info
  Elf.RemoveTextListItems txt
  functions.each { |v| Elf.AddTextListItem(txt, v.call) }
	
	# check mouse interection when not in playing mode
	if game.played
  	for i in snds
    	if Elf.GetGuiObjectEvent(i.btn) == Elf::CLICKED
    	  if(game.do_step(snds.index(i)))
    	    game.snd = Elf.PlaySound(i.snd,1.0)
    	    if(game.cleared?)
    	      game.start_level(game.level+1)
    	      game.played = false
  	      end
        else
          # Elf.PlaySound(i.snd,1.0)
        end
      end
    end
  # play current steps first
  else
    unless game.snd && Elf.IsSoundPlaying(game.snd)
      unless game.cleared?
        puts game.next_step
        game.snd = Elf.PlaySound(snds[game.next_step].snd,1.0)
        game.do_step(game.next_step)
      else
        game.restart_level
        game.snd = nil
        game.played = true
      end
    end  
  end
  
  # check menu callbacks
  for b in btns
    if Elf.GetGuiObjectEvent(b[:elf_btn]) == Elf::CLICKED
      b[:clicked].call
    end
  end
end
