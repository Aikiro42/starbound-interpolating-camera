require '/scripts/vec2.lua'
require '/scripts/util.lua'

function printf(s, ...)
  chat.addMessage(string.format(s, ...))
end

function init()

  local settings = root.assetJson('/configs/aikiro42-interpolating-camera.config')

  for k, v in pairs(settings) do
    self[k] = v
  end
  
  self.hasStarExtensions = _ENV.starExtensions ~= nil
  
  -- chase cam
  self.chaseCamPos = mcontroller.position()
  self.chaseCamSpeed = {0, 0}
  
  -- cursor offset
  self.targetOffset = {0, 0}

  -- lookahead
  self.targetLookahead = {0, 0}
  
  self.loadTimer = 0.1
  if self.hasStarExtensions then
    camera.override({0, 0}, 0, {type="additive", influence=1})
  end
end

function update(dt)
  updatePlayerVelocity(dt)
  if self.hasStarExtensions then
    if self.loadTimer > 0 then  
      -- prevents jumpy camera on teleport
      self.loadTimer = math.max(0, self.loadTimer - dt)
    elseif self.loadTimer == 0 then
      -- prevents jumpy camera on teleport
      initCamera()
      self.loadTimer = -1
    else
      -- main process
      if self.enableChaseCam then
        updateChaseCam(dt)
        local chaseCamOffset = getOffset(self.chaseCamPos)
        camera.override(chaseCamOffset, 0, {type="additive", influence=1})
      end
      
      if self.enableCursorOffset then
        updateCursorCamOffset()
        camera.override(world.xwrap(self.targetOffset), 1, {type="additive", influence=1})
      end

      if self.enableLookahead then
        updateLookaheadOffset()
        camera.override(world.xwrap(self.targetLookahead), 2, {type="additive", influence=1})
      end

    end
  end
end

function initCamera()
  self.targetPos = mcontroller.position()
end

-- update functions

function updatePlayerVelocity(dt)
  self.prevPlayerPos = self.currentPlayerPos or mcontroller.position()
  self.currentPlayerPos = mcontroller.position()
  local speedNorm = world.distance(self.currentPlayerPos, self.prevPlayerPos)
  self.playerVelocity = vec2.mul(speedNorm, 1/dt)
end

function updateChaseCam(dt)
  local targetSpeed = playerVelocity()
  self.chaseCamSpeed = lerp(self.lerpSpeed, self.chaseCamSpeed, targetSpeed)
  self.chaseCamPos = vec2.add(self.chaseCamPos, vec2.mul(self.chaseCamSpeed, dt))
end

function updateCursorCamOffset()
  if self.hasStarExtensions then
    local aimPos = player.aimPosition()
    local playerPos = mcontroller.position()
    local normal = vec2.norm(world.distance(aimPos, playerPos))
    local tentativeMag = world.magnitude(aimPos, playerPos)
    local newOffset = vec2.mul(normal, self.cursorOffsetIntensity * math.min(tentativeMag, self.maxCamDistance))
    self.targetOffset = vec2.lerp(self.lerpSpeed * self.offsetLerpSpeedMult, self.targetOffset, newOffset)
  end
end

function updateLookaheadOffset()
  if self.hasStarExtensions then
    local directionOffsets = {
      N  = { 0, self.lookaheadDistance[2] },
      NE = { self.lookaheadDistance[1], self.lookaheadDistance[2] },
      E  = { self.lookaheadDistance[1], 0 },
      SE = { self.lookaheadDistance[1], -self.lookaheadDistance[2] },
      S  = { 0, -self.lookaheadDistance[2] },
      SW = { -self.lookaheadDistance[1], -self.lookaheadDistance[2] },
      W  = { -self.lookaheadDistance[1], 0 },
      NW = { -self.lookaheadDistance[1], self.lookaheadDistance[2] }
    }
    local newOffset = shouldLookahead() and directionOffsets[getDirection(mcontroller.position(), player.aimPosition())] or {0, 0}
    self.targetLookahead = vec2.lerp(self.lerpSpeed * self.lookaheadLerpSpeedMult, self.targetLookahead, newOffset)
  end
end

-- helpers: general

function playerVelocity()
  return self.playerVelocity or {0, 0}
end

function playerSpeed()
  return vec2.mag(playerVelocity() or {0, 0})
end

-- helpers: chase cam

function lerp(ratio, a, b)
  local diff = world.distance(b, a)
  return vec2.add(a, vec2.mul(diff, ratio))
end

function getOffset(pos)
  local playerPos = mcontroller.position()
  local offset = world.distance(pos, playerPos)
  return offset
end

-- helpers: camera offset

-- helpers: lookahead

function shouldLookahead()
  if self.hasStarExtensions then
    local playerPos = mcontroller.position()
    local aimPos = player.aimPosition()
    return world.magnitude(aimPos, playerPos) > self.lookaheadDeadzone
  else
    return false
  end
end

function getDirection(player, cursor)

  local theta = vec2.angle(world.distance(cursor, player))

  -- start = pi/8 = 0.39269908169872414
  -- step = pi/4 = 0.7853981633974483
  local start = 0.39269908169872414
  local step = 0.7853981633974483

  -- i = 1...8
  for i, v in ipairs({"NE", "N", "NW", "W", "SW", "S", "SE", "E"}) do
    local minAngle = start + (step * (i - 1))
    local maxAngle = start + (step *  i)
    if minAngle <= theta and theta < maxAngle then
      return v
    end
  end

end