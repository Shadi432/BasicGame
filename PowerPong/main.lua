
local MAX_BOUNCE_ANGLE = math.rad(75) -- Maximum angle it can bounce at
local BALL_SPEED = 100

local function collisionDetection(object1,object2) -- AABB Collision
    --[[
    if (object1.x + object1.width/2 > object2.x - object2.width/2) and (object1.x - object1.width/2 < object2.x + object2.width/2) and (object1.y - object1.height/2 < object2.y + object2.height/2)
    and (object1.y + object1.height/2 > object2.y - object2.height/2) then
        return true
    else
        return false
    end
    ]]--
end

local function reboundCalculation(ball,paddle) -- assume paddle1.y is the centre
    --local intersectY = math.abs(paddle1.y) - math.abs(ball) (expecting a negative value if it's on one side of the paddle and a positive one on the other, so each side is half the length of the paddle)
    -- local relativeIntersectY = paddle1.y - intersectY -- relative to the paddle the ball is in this space.
    -- local normalisedRelativeIntersectY = relativeIntersectY/(paddle1.height/2)
    -- local bounceAngle = normalisedRelativeIntersectY * MAX_BOUNCE_ANGLE
    -- local ballVx = BALLSPEED * math.cos(bounceAngle)
    -- local ballVy = BALLSPEED * -math.sin(bounceAngle)


end

function love.load()
    love.window.setMode(320, 180, {fullscreen = true})
    paddle = love.graphics.newImage("Pong.Paddle.png")
    ball = love.graphics.newImage("Pong.Ball.png")

    player1Position = 0
    player2Position = 0

    player1Movespeed = 400
    player2Movespeed = 400

    upperBoundary = -374
    lowerBoundary = 463

end

function love.update(dt)
-- Player 1 Movement
    if love.keyboard.isDown("s") then
        if player1Position < lowerBoundary then
            player1Position = player1Position + player1Movespeed * dt
        end
    end

    if love.keyboard.isDown("w") then
        if player1Position > upperBoundary then
            player1Position = player1Position - player1Movespeed * dt
        end
    end

-- Player 2 Movement
    if love.keyboard.isDown("down") then
        if player2Position < lowerBoundary then
            player2Position = player2Position + player2Movespeed * dt
        end
    end

    if love.keyboard.isDown("up") then
        if player2Position > upperBoundary then
            player2Position = player2Position - player2Movespeed * dt
        end
    end


--[[    Collisions
    If ball.x > screenwidth, then
       player2.point = player2.point + 1
   elseif ball.x < 0 then
       player1.point = player.1.point + 1
   end

    if collisionDetection(ball,paddle1) then
         reboundCalculation(ball,paddle1)
    elseif collisionDetection(ball,paddle2) then
        reboundCalculation(ball,paddle2)
    end

]]--

end

function love.draw()
    love.graphics.draw(paddle, -800, player1Position, 0, 6, 6)
    love.graphics.draw(paddle, 915, player2Position, 0, 6, 6)
    love.graphics.draw(ball, 0, 0, 0, 6, 6)




end
