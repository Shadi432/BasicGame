
local MAX_BOUNCE_ANGLE = math.rad(75) -- Maximum angle it can bounce at
local START_DIRECTION = {-1,1}
math.randomseed(os.time())

local function pauseGameExec() -- Pause game execution for debugging purposes
    if not pauseGame then
        pauseFrame = frameCounter
    end
    pauseGame = true
end

local function collisionDetection(object1,object2) -- AABB Collision

    if ((object1.x + object1.width > object2.x) and (object1.x < object2.x + object2.width)) and ((object1.y < object2.y+object2.height) and (object1.y+object1.height > object2.y)) then
        return true
    else
        return false
    end
end

local function reboundCalculation(ball,paddle) -- assume paddle1.y is the centre
    local intersectY = (math.abs(paddle.y)+(paddle.height/2)) - math.abs(ball.y+ball.height/2) --(expecting a negative value if it's on one side of the paddle and a positive one on the other, so each side is half the length of the paddle)

    local normalisedRelativeIntersectY = math.abs(intersectY)/(paddle.height/2) -- Divide distance down the paddle by the height to normalise it from 0 to 1

    if intersectY < 0 then
        normalisedRelativeIntersectY = normalisedRelativeIntersectY * -1
    end

    if normalisedRelativeIntersectY > 1  then
        posEndCorrection = true
        normalisedRelativeIntersectY = 1
    elseif normalisedRelativeIntersectY < -1 then
        posEndCorrection = false
        normalisedRelativeIntersectY = -1
    end

    local bounceAngle = normalisedRelativeIntersectY * MAX_BOUNCE_ANGLE -- from 1 to -1 so we can get the range of the angles witha max


    ball.vy = -(2 * math.sin(bounceAngle)) * 500 -- These outside constants control speed of the balls post rebound
    ball.vx = (2 * math.cos(bounceAngle)) * 500
end



local function createBall()
    local ball = {
        x = love.graphics.getWidth()/2, -- Taking away the width so it's properly centred since origin is usually top left corner.
        y = love.graphics.getHeight()/2,
        image = love.graphics.newImage("Pong.Ball.png"),
        width = 7,
        height = 7,
        sX = 3,
        sY = 3, -- was 6
        vx = 400, -- Horizontal speed
        vxi = 400, -- Initial horizontal speed
        vy = 0, -- Vertical speed
        startDirection = START_DIRECTION[math.random(1,2)],
        lastCollision = nil-- Stop ball colliding with the same paddle twice
    }

    ball.xi = ball.x -- initial x and y
    ball.yi = ball.y

    ball.width = ball.width * ball.sX   -- Correct the width and height for the sf of the ball
    ball.height = ball.height * ball.sY

    ball.x = love.graphics.getWidth()/2
    ball.y = love.graphics.getHeight()/2

    return ball
end

local function ballServe(gameStart)
    currentPowerUp = nil

    ballList[#ballList + 1] = createBall()
    ballList[1].lastCollision = nil

    if gameStart then
        paddle1.y = paddle1.yi - paddle1.height
        paddle2.y = paddle2.yi - paddle2.height
        pauseTime = time + 5
        paddle1.score = 0
        paddle2.score = 0
        rallyCount = 0
    else
        pauseTime = time + 3
        rallyCount = 0
    end

    ballList[1].x = ballList[1].xi
    ballList[1].y = ballList[1].yi
    ballList[1].startDirection = START_DIRECTION[math.random(1,2)]


    ballList[1].vy = 0
    ballList[1].vx = ballList[1].vxi
    rallyCount = rallyCount + 1
end

local function resetPowerUpEffects(powerupName,paddleEffected,resetAll)

    if resetAll then
        for i=1,#powerUpEffectQueue do
            local powerupName = powerUpEffectQueue[i][1]
            local paddleEffected = powerUpEffectQueue[i][2]

            if powerupName == "Enlarge ball" then
                for j=1, #ballList do
                    ballList[j].sX = 3
                    ballList[j].sy = 3
                    ballList[j].width = ballList[j].width * ballList[j].sX
                    ballList[j].height = ballList[j].height * ballList[j].sY
                end
            elseif powerupName == "Shrink paddle" then
                paddleEffected.height = 600
            elseif powerupName == "Freeze paddle" then
                paddleEffected.speed = 600
            elseif powerupname == "Multi Ball" then
                for k=1, #ballList do
                    ballList[k] = nil
                end
            elseif powerupName == "Increase paddle speed" then
                paddleEffected.speed = 1200
            end
        end
        powerUpEffectQueue = {}
    else
        if powerupName == "Enlarge ball" then
            for j=1, #ballList do
                ballList[j].sX = 3
                ballList[j].sY = 3
                ballList[j].width = ballList[j].width * ballList[j].sX
                ballList[j].height = ballList[j].height * ballList[j].sY
            end
        elseif powerupName == "Shrink paddle" then
            paddleEffected.height =  600
        elseif powerupName == "Freeze paddle" then
            paddleEffected.speed = 600
        elseif powerupname == "Multi Ball" then
            ballList[#ballList] = nil
        elseif powerupName == "Increase paddle speed" then
            paddleEffected.speed = 1200
        end
    end
end

function love.load()
    love.window.setMode(320, 180, {fullscreen = true})
    holdCalc = false -- Debugging purposes
    posEndCorrection = nil -- Debugging purposes
    pauseGame = false -- Debugging purposes
    frameCounter = 0 -- Debugging purposes
    pauseFrame = 0 -- Debugging purposes

    time = 0 -- Time since program has started
    pauseTime = 0 -- If this time is > time then the time will need to catch up to pausetime before code continues updating
    rallyCount = 0 -- When displaying take away value by 1 because logic of first turns.
    scoreLimit = 10
    roundBegun = false
    winner = nil
    showTutorial = false
    nextPowerUpSpawn = 0
    gameEnd = false
    powerUpEffectQueue = {}
    ballList = {}

    powerUps = {
        --{Name = "Enlarge ball", image = love.graphics.newImage("BigBallPowerUp.png")},
        --{Name = "Shrink paddle",image = love.graphics.newImage("SmallPaddlePowerUp.png")},
        --{Name = "Freeze paddle", image = love.graphics.newImage("FreezePowerUp.png")},
        --{Name = "Multi Ball", image = love.graphics.newImage("MultiballPowerUp.png")},
        {Name = "Increase paddle speed", image = love.graphics.newImage("PaddleFasterPowerUp.png")},
    }

    currentPowerUp = nil
    currentAnimationFrame = 1
-- SmallPaddlPowerUp


    scoreCountImgs = {}

    for i=0, 9 do
        scoreCountImgs[i] = love.graphics.newImage("Number" .. i .. ".png")
    end

    for i=1, #powerUps do
        powerUps[i].animations = {}
        framesPerRow = 3
        quadWidth = 16
        quadHeight = 16


        for j=0,2 do
            for k=0,framesPerRow do
                table.insert(powerUps[i].animations,love.graphics.newQuad(k*quadWidth,j*quadHeight,quadWidth,quadHeight,64,64))
            end
        end
    end

    paddle1 = {
        x = 100,
        y = (love.graphics.getHeight()/2+10),
        xi = 100,
        yi = (love.graphics.getHeight()/2+10),
        width = 25,
        height = 200,
        rot = math.rad(0),
        sX = 6,
        sY = 6,
        speed = 1200,
        score = 0,
        oX = 10,
        oY = 0
    }

    paddle2 = {
        x = love.graphics.getWidth()-100,
        y = (love.graphics.getHeight()/2),
        xi = love.graphics.getWidth()-100,
        yi = (love.graphics.getHeight()/2+10),
        width = 25,
        height = 200,
        rot = 0,
        sX = 6,
        sY = 6,
        speed = 1200,
        score = 0,
        oX = 5,
        oY = 0,
    }

    testRect = {
        x = 0,
        y = 0,
        width = 10,
        height = 10,
    } -- Debugging purposes

    startButton = {
        x = love.graphics.getWidth()/2,
        y = (love.graphics.getHeight()/4)*3,
        ix = love.graphics.getWidth()/2,
        iy = (love.graphics.getHeight()/4)*3,
        image = love.graphics.newImage("StartButton.png"),
        width = 326,
        height = 66,
        iwidth = 326,
        iheight = 66,
        sx = 2,
        sy = 2,
        isx = 2, -- initial scale
        isy = 2,
    }

    title = {
        x = love.graphics.getWidth()/2,
        y = (love.graphics.getHeight()/4),
        image = love.graphics.newImage("Title.png"),
        width = 641,
        height = 121,
        sx = 2,
        sy = 2
    }


    gameEndMenu = {
        x = love.graphics.getWidth()/2,
        y = love.graphics.getHeight()/2,
        width = 1000,
        height = 250,
    }
    -- Centre the images on the x and give them a Y a certain distance from either y border of the image
    gameEndMenu.x = gameEndMenu.x - gameEndMenu.width/2 -- Centre the game end menu
    gameEndMenu.y = gameEndMenu.y - gameEndMenu.height/2


    playAgain = {
        x = gameEndMenu.x + gameEndMenu.width/2,
        y = gameEndMenu.y + 10,
        image = love.graphics.newImage("PlayAgainButton.png"),
        width =  635,
        height = 66,
        sx = 1,
        sy = 1
    }

    mainMenu = {
        x = gameEndMenu.x + gameEndMenu.width/2,
        y = (gameEndMenu.y + gameEndMenu.height),
        image = love.graphics.newImage("MainMenuButton.png"),
        width = 632,
        height = 66,
        sx = 1,
        sy = 1
    }



    startButton.width = startButton.iwidth * startButton.sx
    startButton.height = startButton.iheight * startButton.sy
    startButton.x = startButton.x - (startButton.iwidth/2)

    playAgain.width = playAgain.width * playAgain.sx
    playAgain.height = playAgain.height * playAgain.sy
    playAgain.x = playAgain.x - playAgain.width/2

    mainMenu.width = mainMenu.width * mainMenu.sx
    mainMenu.height = mainMenu.height * mainMenu.sy
    mainMenu.y = mainMenu.y - (10 + mainMenu.height)
    mainMenu.x = mainMenu.x - mainMenu.width/2


    title.width = title.width * title.sx
    title.height = title.height * title.sy
    title.x = title.x - (title.width/2)


    paddle2.x = paddle2.x - paddle2.width
    paddle1.y = paddle1.y - paddle1.height -- These 2 lines are to centre the paddle properly
    paddle2.y = paddle2.y - paddle2.height

    paddle1.iy = paddle1.y
    paddle2.iy = paddle2.y



    -- Below defines the x and y values of the boundaries of the screen
    upperYBoundary = 0
    lowerYBoundary = love.graphics.getHeight()
    upperXBoundary = love.graphics.getWidth()
    lowerXBoundary = 0
end

function love.update(dt)


    time = time + dt

    if roundBegun then
        -- Player 1 Movement
        if love.keyboard.isDown("s") then
            if paddle1.y < lowerYBoundary - paddle2.height then
                paddle1.y = paddle1.y + paddle1.speed * dt
            end
        end

        if love.keyboard.isDown("w") then
            if paddle1.y > upperYBoundary then
                paddle1.y = paddle1.y - paddle1.speed * dt
            end
        end

    -- Player 2 Movement
        if love.keyboard.isDown("down") then
            if paddle2.y < lowerYBoundary - paddle2.height then
                paddle2.y = paddle2.y + paddle2.speed * dt
            end
        end

        if love.keyboard.isDown("up") then
            if paddle2.y > upperYBoundary then
                paddle2.y = paddle2.y - paddle2.speed * dt
            end
        end


        if time >= pauseTime then


            frameCounter = frameCounter + 1


            if rallyCount == 0  then -- Because this situation only comes up at the beginning of each round
                showTutorial = true
                ballServe(true)
                nextPowerUpSpawn = math.random(7,10) + time
            else

                -- Show image variable is false here
                showTutorial = false
            end




            if time >= nextPowerUpSpawn  and not currentPowerUp then
                nextPowerUpSpawn = math.random(7,10) + time
                currentPowerUp = powerUps[math.random(#powerUps)]
                currentPowerUp.sx = 7
                currentPowerUp.sy = 7
                currentPowerUp.x = love.graphics.getWidth()/2 - 16*currentPowerUp.sy -- 16 x 16 img
                currentPowerUp.y = 0
                currentPowerUp.height = 16 * currentPowerUp.sy
                currentPowerUp.width = 16 * currentPowerUp.sx
                currentAnimationFrame = 1
            elseif currentPowerUp then
                currentPowerUp.y = currentPowerUp.y + 300 * dt

                if currentPowerUp.y > love.graphics.getHeight()+16*currentPowerUp.sy then --if goes past the border then make it nil
                    currentPowerUp = nil
                end

                currentAnimationFrame = currentAnimationFrame + 10 * dt

                if currentPowerUp and currentAnimationFrame >= #currentPowerUp.animations+1 then
                    currentAnimationFrame = 1
                end

                for i=1, #ballList do
                    if  currentPowerUp and collisionDetection(ballList[i],currentPowerUp) then
                        local powerupName = currentPowerUp.Name
                        powerUpEffectQueue[#powerUpEffectQueue + 1] = {powerupName,ballList[i].lastCollision,time} -- Each powerup log is a log of the powerup's name, the paddle that has it and the time it was gotten at
                        currentPowerUp = nil
                        if powerupName == "Enlarge ball" then
                            print("Enlarge GET!")
                            for j=1, #ballList do
                                ballList[j].width = ballList[j].width / ballList[j].sX
                                ballList[j].height = ballList[j].height / ballList[j].sY

                                ballList[j].sX = 6
                                ballList[j].sy = 6
                                ballList[j].width = ballList[j].width * ballList[j].sX   -- Correct the width and height for the sf of the ball
                                ballList[j].height = ballList[j].height * ballList[j].sY
                            end
                        elseif powerupName == "Shrink paddle" then
                            print("Shrink GET!")
                            if ballList[i].lastCollision == paddle1 or ballList[i].lastCollision == paddle2 then
                                print(":)")
                            end
                            ballList[i].lastCollision.height = 300
                        elseif powerupName == "Freeze paddle" then
                            print("Freeze GET!")
                            ballList[i].lastCollision.speed = 0
                        elseif powerupName == "Multi Ball" then
                            print("Multi ball GET!")
                            ballList[#ballList + 1] = createBall()
                            ballList[#ballList + 1] = createBall()
                        elseif powerupName == "Increase paddle speed" then
                            print("INCREASE PADDLE SPEED GET!")
                            ballList[i].lastCollision.speed = 2400
                            print(":)")
                        end
                    end
                end
            end

            for i=1, #powerUpEffectQueue do
                if powerUpEffectQueue[i][3] + 3 < time then
                    -- Take off this powerup
                    local powerupName = powerUpEffectQueue[i][1]
                    local paddleEffected = powerUpEffectQueue[i][2]

                    resetPowerUpEffects(powerupName,paddleEffected)
                    table.remove(powerUpEffectQueue,i)
                end
            end


            if math.floor(rallyCount/5) > 0 then

                ballList[1].vx = ballList[1].vx + (math.floor(rallyCount/5) * 5)
                ballList[1].vy = ballList[1].vy + (math.floor(rallyCount/5) * 5)
            end


            for i=1, #ballList do
                ballList[i].x = ballList[i].x + (ballList[i].vx * dt * ballList[i].startDirection)
                ballList[i].y = ballList[i].y + (ballList[i].vy * dt)
            end



        --    Collisions

            for i=1, #ballList do
                if ballList[i].x > upperXBoundary-ballList[i].width then
                   paddle1.score = paddle1.score + 1

                   table.remove(ballList,i) -- Problem here

                   --resetPowerUpEffects(powerupName,paddleEffected,true)
                   if #ballList == 0 then
                       ballServe()
                   end

               elseif ballList[i].x < lowerXBoundary+ballList[i].width then
                   paddle2.score = paddle2.score + 1

                   table.remove(ballList,i)

                   --resetPowerUpEffects(powerupName,paddleEffected,true)
                   if #ballList == 0 then
                      ballServe()
                   end
               end
           end

            if paddle1.score == scoreLimit or paddle2.score == scoreLimit then
                winner = paddle1
                roundBegun = false
                gameEnd = true
                resetPowerUpEffects(powerupName,paddleEffected,true)

                ballList = {}
            end

            for i=1, #ballList do
                --print(i .. " " .. #ballList)
                if ballList[i].y < upperYBoundary then
                    ballList[i].vy = -ballList[i].vy

                elseif ballList[i].y > lowerYBoundary then
                    ballList[i].vy = -ballList[i].vy
                end
            end



            if not holdCalc then
                for i=1, #ballList do
                    if collisionDetection(ballList[i],paddle1) and ballList[i].lastCollision ~= paddle1 then
                        rallyCount = rallyCount + 1
                        ballList[i].lastCollision = paddle1
                        ballList[i].startDirection = ballList[i].startDirection * -1

                        reboundCalculation(ballList[i],paddle1)
                    elseif collisionDetection(ballList[i],paddle2) and ballList[i].lastCollision ~= paddle2 then
                        rallyCount = rallyCount + 1
                        ballList[i].lastCollision = paddle2
                        ballList[i].startDirection = ballList[i].startDirection * -1
                        reboundCalculation(ballList[i],paddle2)
                    end
                end
            end
        end
    end
end

function love.draw()

    if roundBegun then
        love.graphics.setColor(1,1,1)
        love.graphics.rectangle("fill", paddle1.x, paddle1.y, paddle1.width, paddle1.height)
        love.graphics.rectangle("fill", paddle2.x, paddle2.y, paddle2.width, paddle2.height)

        -- Below both at 10/10
        --love.graphics.print("Ball X Velocity: " .. ball.vx .. " Ball Y Velocity: " .. ball.vy,0,50)


        if currentPowerUp then
            love.graphics.draw(currentPowerUp.image,currentPowerUp.animations[math.floor(currentAnimationFrame)],currentPowerUp.x,currentPowerUp.y,0,currentPowerUp.sx,currentPowerUp.sy)
        end

        for i=1, #ballList do
            love.graphics.draw(ballList[i].image, ballList[i].x, ballList[i].y,0,ballList[i].sX,ballList[i].sY) --0, ball.sX, ball.sY) -- 138 from left edge of ball drawing to the horizontal edge of the "image"
        end

        love.graphics.draw(scoreCountImgs[paddle1.score],100,100,0,5,5)
        love.graphics.draw(scoreCountImgs[paddle2.score],love.graphics.getWidth()-200,100,0,5,5)

        -- 71 from the top of ball to top of the plane
        love.graphics.setColor(144/255,255/255,255/255)
        --love.graphics.rectangle("fill",ball.x,ball.y+ball.height/2,10,10)
        love.graphics.print("RelYIntersect: " .. testRect.y,250)

        love.graphics.print("Player 1: " .. paddle1.score .. "  Player 2: " .. paddle2.score,0,250)
        love.graphics.print("Rally Count: " .. rallyCount-1,250,150)

        local endCorrectionMsg = "No end correction"

        if posEndCorrection then
            endCorrectionMsg = ("Positive end correction")
        elseif posEndCorrection == false then
            endCorrectionMsg = ("Negative end correction")
        else
            endCorrectionMsg = ("No end correction needed!")
        end

        if pauseGame then
            if frameCounter == pauseFrame + 3 then
                love.timer.sleep(10000)
            end
        end

    elseif gameEnd then
        -- Make coloured background for buttons to go over (rectangle)
        love.graphics.setColor(68/255, 255/255, 255/255)
        love.graphics.rectangle("fill",gameEndMenu.x,gameEndMenu.y,gameEndMenu.width,gameEndMenu.height)
        love.graphics.draw(mainMenu.image,mainMenu.x,mainMenu.y,0,mainMenu.sx,mainMenu.sy)
        love.graphics.draw(playAgain.image,playAgain.x,playAgain.y,0,playAgain.sx,playAgain.sy)
        -- Show main menu button
        -- Show play again

    else
        -- Show menu screen
        love.graphics.setColor(1,1,1) -- If anything needs to get drawn here this needs to be the colour they're drawn in
        love.graphics.draw(startButton.image,startButton.x,startButton.y,0,startButton.sx,startButton.sy)
        love.graphics.draw(title.image,title.x,title.y,0,title.sx,title.sy)

        function love.mousemoved(x,y,dx,dy,istouch)
            if (x > (startButton.x) and x < startButton.x + startButton.width) and (y > startButton.y and y < startButton.y + startButton.height)  then
                startButton.sy = startButton.isy * 1.25
                startButton.sx = startButton.isx * 1.25
            else
                startButton.sy = startButton.isy
                startButton.sx = startButton.isx
            end

            startButton.width = startButton.iwidth * startButton.sx
            startButton.height = startButton.iheight * startButton.sy


            startButton.x = startButton.ix - (startButton.width/2)
            startButton.y = startButton.iy - (startButton.height/2)
        end
    end
end

function love.mousepressed(x,y,button)
    if button == 1 then
        if not roundBegun and not gameEnd then
            if (x > (startButton.x) and x < startButton.x + startButton.width) and (y > startButton.y and y < startButton.y + startButton.height) then
                roundBegun = true
                ballServe(true)
                resetPowerUpEffects(powerupName,paddleEffected,true)

            end
        elseif gameEnd then
            if (x > mainMenu.x and x < mainMenu.x + mainMenu.width) and (y > mainMenu.y and y < mainMenu.y + mainMenu.height) then -- Main menu button pressed
                roundBegun = false
                gameEnd = false

            elseif (x > playAgain.x and x < playAgain.x + playAgain.width) and (y > playAgain.y and y < playAgain.y + playAgain.height) then
                roundBegun = true--
                gameEnd = false
                ballServe(true)
            end
        end
    end
end

function love.keypressed(key)
    if key == "p" then
        pauseGameExec()
    end
end
