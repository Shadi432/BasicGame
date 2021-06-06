
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

local function ballServe()
    lastCollision = nil
    ball.x = ball.xi
    ball.y = ball.yi
    ball.startDirection = START_DIRECTION[math.random(1,2)]

    pauseTime = time + 5
    ball.vy = 0
    ball.vx = ball.vxi
    rallyCount = 0
end

function love.load()
    love.window.setMode(320, 180, {fullscreen = true})
    lastCollide = nil -- Debugging purposes
    holdCalc = false -- Debugging purposes
    posEndCorrection = nil -- Debugging purposes
    pauseGame = false -- Debugging purposes
    frameCounter = 0 -- Debugging purposes
    pauseFrame = 0 -- Debugging purposes

    lastCollision = nil -- Stop ball colliding with the same paddle twice
    time = 0 -- Time since program has started
    pauseTime = 0 -- If this time is > time then the time will need to catch up to pausetime before code continues updating
    rallyCount = 0

-- SmallPaddlPowerUp
    smallPaddleIcon = love.graphics.newImage("SmallPaddlePowerUp.png")
    smallPaddleFrames = {}

    local smallPaddle_width = smallPaddleIcon:getWidth()
    local smallPaddle_height = smallPaddleIcon:getHeight()


    local smallPaddleFrameWidth = 16
    local smallPaddleFrameHeight = 16

    for i = 0,3 do
        table.insert(smallPaddleFrames, love.graphics.newQuad(i * smallPaddleFrameWidth, 0, smallPaddleFrameWidth, smallPaddleFrameHeight, smallPaddle_width, smallPaddle_height))
    end

    for i=0,3 do
        table.insert(smallPaddleFrames, love.graphics.newQuad(i * smallPaddleFrameWidth, smallPaddleFrameHeight, smallPaddleFrameWidth, smallPaddleFrameHeight, smallPaddle_width, smallPaddle_height))
    end

    for i=0,3 do
        table.insert(smallPaddleFrames,love.graphics.newQuad(i * smallPaddleFrameWidth,smallPaddleFrameHeight*2,smallPaddleFrameWidth,smallPaddleFrameHeight,smallPaddle_width,smallPaddle_height))
    end


    --for i=1, #smallPaddleFrames do

    --end

    currentSmallPaddleFrame = 1


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
        speed = 400,
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
        speed = 400,
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
    print(time)
    print(pauseTime)
    time = time + dt

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


        currentSmallPaddleFrame = currentSmallPaddleFrame + 10 * dt

        if currentSmallPaddleFrame >= #smallPaddleFrames+1 then
            currentSmallPaddleFrame = 1
        end


    -- Player 1 Movement
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

    function love.draw()

        love.graphics.draw(smallPaddleIcon, smallPaddleFrames[math.floor(currentSmallPaddleFrame)], 100*6, 100*6,0,6,6)

        love.graphics.setColor(1,1,1)
        love.graphics.rectangle("fill", paddle1.x, paddle1.y, paddle1.width, paddle1.height)
        love.graphics.rectangle("fill", paddle2.x, paddle2.y, paddle2.width, paddle2.height)

        -- Below both at 10/10
            love.graphics.print("Ball X Velocity: " .. ball.vx .. " Ball Y Velocity: " .. ball.vy,0,50)


        if lastCollide then
            love.graphics.print("Last collided with: Paddle1")
        elseif lastCollide == false then
            love.graphics.print("Last collided with: Paddle2")
        elseif lastCollide == nil then
            love.graphics.print("Last collided with: None")
        end

        love.graphics.draw(ball.image, ball.x, ball.y,0,ball.sX,ball.sY) --0, ball.sX, ball.sY) -- 138 from left edge of ball drawing to the horizontal edge of the "image"
        -- 71 from the top of ball to top of the plane
        love.graphics.setColor(144/255,255/255,255/255)
        --love.graphics.rectangle("fill",ball.x,ball.y+ball.height/2,10,10)
        love.graphics.print("RelYIntersect: " .. testRect.y,250)

        love.graphics.print("Player 1: " .. paddle1.score .. "  Player 2: " .. paddle2.score,0,250)
        love.graphics.print("Rally Count: " .. rallyCount,250,150)

        local endCorrectionMsg = "No end correction"

        if posEndCorrection then
            endCorrectionMsg = ("Positive end correction")
        elseif posEndCorrection == false then
            endCorrectionMsg = ("Negative end correction")
        else
            endCorrectionMsg = ("No end correction needed!")
        end


        if pauseGame then
            if frameCounter == pauseFrame+10000 then
                love.timer.sleep(10000)
            end
        end
    end
end
