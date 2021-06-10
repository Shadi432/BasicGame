
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

local function ballServe(gameStart)
    currentPowerUp = nil
    lastCollision = nil
    ball.x = ball.xi
    ball.y = ball.yi
    ball.startDirection = START_DIRECTION[math.random(1,2)]


    if gameStart then
        pauseTime = time + 5
    else
        pauseTime = time + 3
    end


    ball.vy = 0
    ball.vx = ball.vxi
    rallyCount = rallyCount + 1
end

function love.load()
    love.window.setMode(320, 180, {fullscreen = true})
    holdCalc = false -- Debugging purposes
    posEndCorrection = nil -- Debugging purposes
    pauseGame = false -- Debugging purposes
    frameCounter = 0 -- Debugging purposes
    pauseFrame = 0 -- Debugging purposes

    lastCollision = nil -- Stop ball colliding with the same paddle twice
    time = 0 -- Time since program has started
    pauseTime = 0 -- If this time is > time then the time will need to catch up to pausetime before code continues updating
    rallyCount = 0 -- When displaying take away value by 1 because logic of first turns.
    scoreLimit = 10
    roundBegun = false
    winner = nil
    showTutorial = false
    nextPowerUpSpawn = 0

    powerUps = {
        {Name = "Enlarge ball", image = love.graphics.newImage("BigBallPowerUp.png")},
        {Name = "Shrink paddle",image = love.graphics.newImage("SmallPaddlePowerUp.png")},
        {Name = "Freeze paddle", image = love.graphics.newImage("FreezePowerUp.png")},
        {Name = "Multi Ball", image = love.graphics.newImage("MultiballPowerUp.png")},
        {Name = "Increase paddle speed", image = love.graphics.newImage("PaddleFasterPowerUp.png")}
    }

    currentPowerUp = nil
    currentAnimationFrame = 1
-- SmallPaddlPowerUp


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



    ball = {
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
        startDirection = START_DIRECTION[math.random(1,2)]
    }
    ball.xi = ball.x -- initial x and y
    ball.yi = ball.y

    paddle1 = {
        x = 100,
        y = (love.graphics.getHeight()/2+10),
        width = 25,
        height = 200,
        rot = math.rad(0),
        sX = 6,
        sY = 6,
        speed = 600,
        score = 0,
        oX = 10,
        oY = 0
    }

    paddle2 = {
        x = love.graphics.getWidth()-100,
        y = (love.graphics.getHeight()/2),
        width = 25,
        height = 200,
        rot = 0,
        sX = 6,
        sY = 6,
        speed = 600,
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

    startButton.width = startButton.iwidth * startButton.sx
    startButton.height = startButton.iheight * startButton.sy
    startButton.x = startButton.x - (startButton.iwidth/2)

    title.width = title.width * title.sx
    title.height = title.height * title.sy
    title.x = title.x - (title.width/2)


    paddle2.x = paddle2.x - paddle2.width
    paddle1.y = paddle1.y - paddle1.height -- These 2 lines are to centre the paddle properly
    paddle2.y = paddle2.y - paddle2.height

    ball.width = ball.width * ball.sX   -- Correct the width and height for the sf of the ball
    ball.height = ball.height * ball.sY

    ball.x = love.graphics.getWidth()/2
    ball.y = love.graphics.getHeight()/2

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
                paddle2.y = paddle2.y + paddle1.speed * dt
            end
        end

        if love.keyboard.isDown("up") then
            if paddle2.y > upperYBoundary then
                paddle2.y = paddle2.y - paddle1.speed * dt
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
                currentPowerUp.sx = 6
                currentPowerUp.sy = 6
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

                if  currentPowerUp and collisionDetection(ball,currentPowerUp) then
                    local powerupName = currentPowerUp.Name
                    currentPowerUp = nil
                    if powerupName == "Enlarge ball" then
                        ball.sX = 6
                        ball.sy = 6
                        ball.width = ball.width * ball.sX   -- Correct the width and height for the sf of the ball
                        ball.height = ball.height * ball.sY
                    elseif powerupName == "Shrink paddle" then
                        --lastCollision
                    elseif powerupName == "Freeze paddle" then

                    elseif powerupName == "Multi Ball" then

                    elseif powerupName == "Increase paddle speed" then

                    end
                end
            end


            ball.x = ball.x + (ball.vx * dt * ball.startDirection)
            ball.y = ball.y + (ball.vy * dt)




        --    Collisions

            if ball.x > upperXBoundary-ball.width then
               paddle1.score = paddle1.score + 1
               ballServe()

           elseif ball.x < lowerXBoundary+ball.width then
               paddle2.score = paddle2.score + 1
               ballServe()
            end

            if paddle1.score == scoreLimit or paddle2.score == scoreLimit then
                winner = paddle1
                roundBegun = false
            end

            if ball.y < upperYBoundary then
                ball.vy = -ball.vy

            elseif ball.y > lowerYBoundary then
                ball.vy = -ball.vy
            end

            if not holdCalc then
                if collisionDetection(ball,paddle1) and lastCollision ~= paddle1 then
                    rallyCount = rallyCount + 1
                    lastCollision = paddle1
                    ball.startDirection = ball.startDirection * -1
                    reboundCalculation(ball,paddle1)
                elseif collisionDetection(ball,paddle2) and lastCollision ~= paddle2 then
                    rallyCount = rallyCount + 1
                    lastCollision = paddle2
                    ball.startDirection = ball.startDirection * -1
                    reboundCalculation(ball,paddle2)
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
        love.graphics.print("Ball X Velocity: " .. ball.vx .. " Ball Y Velocity: " .. ball.vy,0,50)


        if currentPowerUp then
            love.graphics.draw(currentPowerUp.image,currentPowerUp.animations[math.floor(currentAnimationFrame)],currentPowerUp.x,currentPowerUp.y,0,currentPowerUp.sx,currentPowerUp.sy)
        end

        love.graphics.draw(ball.image, ball.x, ball.y,0,ball.sX,ball.sY) --0, ball.sX, ball.sY) -- 138 from left edge of ball drawing to the horizontal edge of the "image"
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
            if frameCounter == pauseFrame+1 then
                love.timer.sleep(10000)
            end
        end
    else
        -- Show menu screen
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
        if (x > (startButton.x) and x < startButton.x + startButton.width) and (y > startButton.y and y < startButton.y + startButton.height) then
            roundBegun = true
        end
    end
end
