
local MAX_BOUNCE_ANGLE = math.rad(75) -- Maximum angle it can bounce at
local START_DIRECTION = {1,-1}
math.randomseed(os.time())



local function collisionDetection(object1,object2) -- AABB Collision
    if (object1.x + object1.width/2 > object2.x - object2.width/2) and (object1.x - object1.width/2 < object2.x + object2.width/2) and (object1.y - object1.height/2 < object2.y + object2.height/2)
    and (object1.y + object1.height/2 > object2.y - object2.height/2) then
        return true
    else
        return false
    end
end

local function reboundCalculation(ball,paddle) -- assume paddle1.y is the centre
    local intersectY = math.abs(paddle1.y) - math.abs(ball.y) --(expecting a negative value if it's on one side of the paddle and a positive one on the other, so each side is half the length of the paddle)
    local relativeIntersectY = paddle1.y - intersectY -- relative to the paddle the ball is in this space.
    local normalisedRelativeIntersectY = relativeIntersectY/(paddle1.height/2)
    local bounceAngle = normalisedRelativeIntersectY * MAX_BOUNCE_ANGLE
    ball.vx = ball.vx * math.cos(bounceAngle)
    ball.vy = ball.vy * -math.sin(bounceAngle)
    print(ball.vx)
    print(ball.vy)
end

function love.load()
    love.window.setMode(320, 180, {fullscreen = true})

    ball = {
        x = 0,
        y = 0,
        image = love.graphics.newImage("Pong.Ball.png"),
        width = 7,
        height = 7,
        sX = 6,
        sY = 6,
        vx = 400,
        vy = 0,
        startDirection = START_DIRECTION[math.random(1,2)]
    }

    paddle1 = {
        x = -700,
        y = 0,
        image = love.graphics.newImage("Pong.Paddle.png"),
        width = 10,
        height = 45,
        rot = math.rad(0),
        sX = 6,
        sY = 6,
        speed = 400,
        score = 0,
        oX = 10,
        oY = 0
    }

    paddle2 = {
        x = 950,
        y = 0,
        image = love.graphics.newImage("Pong.Paddle.png"),
        width = 10,
        height = 45,
        rot = 0,
        sX = 6,
        sY = 6,
        speed = 400,
        score = 0,
        oX = 5,
        oY = 0,
    }

    paddle1.height = paddle1.height * paddle1.sY
    paddle1.width =  paddle1.width * paddle1.sX
    paddle2.height = paddle2.height * paddle2.sY
    paddle2.width = paddle2.width * paddle2.sX
    ball.height = ball.height * ball.sY
    ball.width = ball.width * ball.sX

    upperYBoundary = -374
    lowerYBoundary = 463
    upperXBoundary = 1100
    lowerXBoundary = -900



end

function love.update(dt)
-- Player 1 Movement

    ball.x = ball.x + (ball.vx * dt * ball.startDirection)
    ball.y = ball.y + (ball.vy * dt * ball.startDirection)

    if love.keyboard.isDown("s") then
        if paddle1.y < lowerYBoundary then
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
        if paddle2.y < lowerYBoundary then
            paddle2.y = paddle2.y + paddle1.speed * dt
        end
    end

    if love.keyboard.isDown("up") then
        if paddle2.y > upperYBoundary then
            paddle2.y = paddle2.y - paddle1.speed * dt
        end
    end


--    Collisions
    if ball.x > upperXBoundary then
       paddle1.score = paddle1.score + 1
       ball.x = 0
       ball.startDirection = START_DIRECTION[math.random(1,2)]
    elseif ball.x < lowerXBoundary then
       paddle2.score = paddle2.score + 1
       ball.x = 0
       ball.startDirection = START_DIRECTION[math.random(1,2)]
    end


    if collisionDetection(ball,paddle1) then
        print("Colliding with paddle1")
         reboundCalculation(ball,paddle1)
         ball.startDirection = ball.startDirection * -1
    elseif collisionDetection(ball,paddle2) then
        print("Colliding with paddle2")
        ball.startDirection = ball.startDirection * -1
        reboundCalculation(ball,paddle2)
    end

end

function love.draw()
    love.graphics.draw(paddle1.image, paddle1.x, paddle1.y, paddle1.rot, paddle1.sX, paddle1.sY,paddle1.oX,paddle1.oY)
    love.graphics.draw(paddle2.image, paddle2.x, paddle2.y, paddle2.rot, paddle2.sX, paddle2.sY,paddle2.oX,paddle2.oY)
    love.graphics.draw(ball.image, ball.x, ball.y, 0, ball.sX, ball.sY)

    love.graphics.print("Player 1: " .. paddle1.score .. "  Player 2: " .. paddle2.score)

end
