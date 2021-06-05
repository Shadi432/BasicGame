
local MAX_BOUNCE_ANGLE = math.rad(90) -- Maximum angle it can bounce at
local START_DIRECTION = {1,-1}
math.randomseed(os.time())



local function collisionDetection(object1,object2) -- AABB Collision
    if ((object1.x + object1.width > object2.x) and (object1.x < object2.x + object2.width)) and ((object1.y < object2.y+object2.height) and (object1.y+object1.height > object2.y)) then

    -- and (object1.y - object1.height/2 < object2.y + object2.height/2)
    --and (object1.y + object1.height/2 > object2.y - object2.height/2) then
        return true
    else
        return false
    end
end

local function reboundCalculation(ball,paddle) -- assume paddle1.y is the centre
    local intersectY = (paddle.y+(paddle.height/2)) - ball.y --(expecting a negative value if it's on one side of the paddle and a positive one on the other, so each side is half the length of the paddle)
    local normalisedRelativeIntersectY = intersectY/(paddle.height/2)
    --local relativeIntersectY = (paddle.y+(paddle.height/2)) - intersectY -- relative to the paddle the ball is in this space.

    if normalisedRelativeIntersectY > 1 then
        normalisedRelativeIntersectY = 1
    elseif normalisedRelativeIntersectY < -1 then
        normalisedRelativeIntersectY = -1
    end

    --local bounceAngle = normalisedRelativeIntersectY * MAX_BOUNCE_ANGLE
    --ball.vx = ball.vx * math.cos(normalisedRelativeIntersectY)
    ball.vy = -math.sin(normalisedRelativeIntersectY)


    --holdCalc = true
end

function love.load()
    love.window.setMode(320, 180, {fullscreen = true})
    lastCollide = nil -- Debugging purposes
    holdCalc = false -- Debugging purposes


    smallPaddleIcon = love.graphics.newImage("SmallPaddlePowerUp.png")
    smallPaddleFrames = {}
    local smallPaddle_width = smallPaddleIcon:getWidth()
    local smallPaddle_height = smallPaddleIcon:getHeight()

    local smallPaddleFrameWidth = 16
    local smallPaddleFrameHeight = 16

    for i = 0,6 do
        table.insert(smallPaddleFrames, love.graphics.newQuad(i * smallPaddleFrameWidth, 0, smallPaddleFrameWidth, smallPaddleFrameHeight, smallPaddle_width, smallPaddle_height))
    end

    currentSmallPaddleFrame = 1
    ball = {
        x = 0, -- Taking away the width so it's properly centred since origin is usually top left corner.
        y = 0,
        image = love.graphics.newImage("Pong.Ball.png"),
        width = 7,
        height = 7,
        sX = 6,
        sY = 6, -- was 6
        vx = 400, -- Horizontal speed
        vy = 0, -- Vertical speed
        startDirection = START_DIRECTION[math.random(1,2)]
    }

    paddle1 = {
        x = 100,
        y = (love.graphics.getHeight()/2),
        width = 100,
        height = 400,
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
        width = 100,
        height = 400,
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

    currentSmallPaddleFrame = currentSmallPaddleFrame + 10 * dt
    if currentSmallPaddleFrame >= 8 then
        currentSmallPaddleFrame = 1
    end


-- Player 1 Movement

    ball.x = ball.x + (ball.vx * dt * ball.startDirection)
    ball.y = ball.y + ((ball.vy*1000) * dt)


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


--    Collisions

    if ball.x > upperXBoundary-ball.width then
        ball.x = love.graphics.getWidth()/2
        print("Collision1")
       paddle1.score = paddle1.score + 1

       ball.startDirection = START_DIRECTION[math.random(1,2)]
   elseif ball.x < lowerXBoundary+ball.width then
       print("Collision2")
       ball.x = love.graphics.getWidth()/2
       paddle2.score = paddle2.score + 1
       ball.startDirection = START_DIRECTION[math.random(1,2)]
    end

    if ball.y < upperYBoundary then
        ball.vy = -ball.vy

    elseif ball.y > lowerYBoundary then
        ball.vy = -ball.vy
    end

    if not holdCalc then
        if collisionDetection(ball,paddle1) then
            ball.startDirection = ball.startDirection * -1
            lastCollide = true
            reboundCalculation(ball,paddle1)
        elseif collisionDetection(ball,paddle2) then

            ball.startDirection = ball.startDirection * -1
            lastCollide = false
            reboundCalculation(ball,paddle2)
        end
    end
end

function love.draw()
    love.graphics.draw(SmallPaddlePowerUp, smallPaddleFrames[math.floor(currentSmallPaddleFrame)], 100, 100)

    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("fill", paddle1.x, paddle1.y, paddle1.width, paddle1.height)
    love.graphics.rectangle("fill", paddle2.x, paddle2.y, paddle2.width, paddle2.height)

    -- Below both at 10/10
        love.graphics.print("Ball X Velocity: " .. ball.vx .. " Ball Y Velocity: " .. ball.vy,0,50)

    if lastCollide then
        love.graphics.print("Last collided with: Paddle1")
    elseif lastCollide == false then
        love.graphics.print("Last collided with: Paddle2")
    else
        love.graphics.print("Last collided with: None")
    end

    love.graphics.draw(ball.image, ball.x-(138*ball.sX)  , ball.y-(71*ball.sY),0,ball.sX,ball.sY) --0, ball.sX, ball.sY) -- 138 from left edge of ball drawing to the horizontal edge of the "image"
    -- 71 from the top of ball to top of the plane
    love.graphics.setColor(144/255,255/255,255/255)
    love.graphics.rectangle("fill",testRect.x,testRect.y,10,10)
    love.graphics.print("RelYIntersect: " .. testRect.y,250)

    love.graphics.print("Player 1: " .. paddle1.score .. "  Player 2: " .. paddle2.score,0,250)

end
