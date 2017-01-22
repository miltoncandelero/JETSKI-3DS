player = {}

agua = {}

wave = {}

bottomscreen = {}

angulo = 0

gamespeed = 20;

distance = 0;

function lerp(a,b,t) return (1-t)*a + t*b end

PlayingGame = false;

 
function love.load()

	--For the restart
	
	angulo = 0

	gamespeed = 20;

	distance = 0;
--
	banner = love.graphics.newImage("banner.png")



  --3DS stuff
  love.timer.step() -- wooot?
  
--  	-- Enables 3D mode.
	love.graphics.set3D(true) -- #3DS

--	-- Seeds the random number generator with the time (Actually makes it random)
math.randomseed(os.time())

  
  --desktop stuff
  
  success = love.window.setMode(400, 240)
  
  agua.x = 0
  agua.y = 0
  
  agua.img0 = love.graphics.newImage("BG/0.png")
  agua.img1 = love.graphics.newImage("BG/1.png")
  agua.img2 = love.graphics.newImage("BG/2.png")
  agua.img3 = love.graphics.newImage("BG/3.png")
  agua.img4 = love.graphics.newImage("BG/4.png")
  
  
  
  player.img = love.graphics.newImage("player.png")
  player.shadow = love.graphics.newImage("shadow.png")
  player.x = love.graphics.getWidth() /4   -- This sets the player at the middle of the screen based on the width of the game window. 
	player.y = love.graphics.getHeight() / 2  -- This sets the player at the middle of the screen based on the height of the game window. 
  
  
  player.canJump=true;
  
  player.depth = 0
  
  player.isJumping = false;
  
  
  jump = love.audio.newSource("jmp.ogg","static")
  splash = love.audio.newSource("splash.ogg","static")
  hurt = love.audio.newSource("hurt.ogg","static")
  music = love.audio.newSource("bg.ogg","static")
  music:setLooping(true)
  music:play()
  
  wave.img = love.graphics.newImage("wave.png")
  wave.imgBridge= love.graphics.newImage("bridge.png")
  wave.isWave = true;
  wave.x = 400 + 32 + math.floor(math.random( 0, 200 ))
  wave.y = 0
  
  bottomscreen.bg = love.graphics.newImage("BG/bot.png")
  
  font = love.graphics.newFont("KoolBean.ttf", 25)
  love.graphics.setFont(font)
  
end
 
function love.update(dt)

  if angulo > math.pi * 2 then
    angulo = 0
  end
  
  agua.y = math.floor(math.sin(angulo) * 8)-8;
  
  if PlayingGame == true then


		if wave.x <=-32 then
			wave.x = 400 + 32 + math.floor(math.random( gamespeed, gamespeed+200 ))
			if math.random(0,1) == 1 then
				wave.isWave=true
			else
				wave.isWave=false
			end
		end

	  agua.x =  math.floor(agua.x - gamespeed * dt)
	  wave.x =  math.floor(wave.x - gamespeed * dt)
	  
	  distance = distance + gamespeed*dt
	  
	  gamespeed = gamespeed + 10*dt --No logro encontrar un buen factor para DT :'(
	  
	  if player.x >= wave.x and player.x <= wave.x+32 then
		
		if wave.isWave == true then
			if player.canJump == true then -- YOU ARE DEAD TO ME SON!
				hurt:play()
				PlayingGame = false
			end
		else
			if player.canJump == false then -- YOU ARE DEAD TO ME SON!
				hurt:play()
				PlayingGame=false
			end
		end
		
	  end
	  
	  if agua.x <= -400 then
		agua.x = 0
	  end
	  
	  angulo = angulo + 1 * dt
	  
	  if player.canJump == false then
		if player.isJumping == true then
		  --AND THE PLAYER GOES UP! ╰།   ◉ ◯ ◉ །╯
			player.depth = lerp(player.depth,10,5*dt)
			if player.depth >= 9.9 then --I don't put 10 here because I am paranpoid about lerp reaching the final number
			  player.isJumping=false
			end
		else
		  -- and the player goes down ┌( ◐ o ◐ )┐
		  player.depth = lerp(player.depth,0,5*dt)
		  if player.depth <= 2 then
			splash:play()
			player.canJump = true
		  end
		end
	  end
   end
end
 
function love.draw()
  
	love.graphics.setScreen('bottom') --#3DS
	
	love.graphics.setColor(255,255,255, 255)
  	love.graphics.draw(bottomscreen.bg, 0, 0, 0, 1, 1)
	
	love.graphics.setColor(184,134,11, 255)

	if PlayingGame == true then
	love.graphics.print("Speed:  " .. math.floor(gamespeed) .." px/s\nDistance:  " .. math.floor(distance/1000) .. " Kpx\n\n\nPress A to jump\nPress Start to quit", 50, 50)
	else
	love.graphics.print("Speed:  " .. math.floor(gamespeed) .." px/s\nDistance:  " .. math.floor(distance/1000) .. " Kpx\n\n\nPress A to play again\nPress Start to quit", 50, 50)
	end

	
	
  love.graphics.setScreen('top') --#3DS
  
	love.graphics.setColor(255,255,255, 255)
	
  love.graphics.setDepth(2)--#3DS
  love.graphics.draw(agua.img0, agua.x, agua.y, 0, 1, 1)
  love.graphics.setDepth(1)--#3DS
  love.graphics.draw(agua.img1, agua.x, agua.y, 0, 1, 1)
  love.graphics.setDepth(0)--#3DS
  love.graphics.draw(agua.img2, agua.x, agua.y, 0, 1, 1)
  love.graphics.setDepth(-1)--#3DS
  love.graphics.draw(agua.img3, agua.x, agua.y, 0, 1, 1)
  love.graphics.setDepth(-2)--#3DS
  love.graphics.draw(agua.img4, agua.x, agua.y, 0, 1, 1)
  
  
  if PlayingGame == true then

	  if wave.isWave ==true then 
		  love.graphics.setDepth(-5)--3DS
		  
		  love.graphics.draw(wave.img, wave.x, wave.y, 0, 1, 1,0,0)
	  end
	  
	  
	  if player.canJump == false then
		love.graphics.draw(player.shadow, player.x, player.y, 0, 1, 1,36,18)
	  end

	  
	  love.graphics.setDepth(-1 * player.depth)--#3DS
	  
	  
	  local scale = ((player.depth)+15)/15
	  
	  
	  love.graphics.draw(player.img, player.x, player.y, 0, scale, scale,24,11)
	  
	  if wave.isWave == false then
		  love.graphics.setDepth(-7)--3DS
		  
		  love.graphics.draw(wave.imgBridge, wave.x, wave.y, 0, 1, 1,0,0)
	  end
	else
	  love.graphics.setDepth(-7)--3DS
	  love.graphics.draw(banner, 72, 56, 0, 1, 1,0,0)
  end
end


function love.keypressed(key)

	-- If the start button is pressed, we return to the Homebrew Launcher
	if key == 'start' then
		love.event.quit()
	end
  if PlayingGame == true then
    if key == 'a' and player.canJump then
		jump:play()
        player.canJump = false;
        player.isJumping = true;
    end
   else
       if key == 'a' then
	   	PlayingGame = true;
		love.load()
		end
	end
	
  
end