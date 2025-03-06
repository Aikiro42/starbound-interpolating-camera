require '/scripts/vec2.lua'
require '/scripts/util.lua'

function print(s)
  chat.addMessage(string.format("%s", s))
end

function init()
  
  self.hasStarExtensions = _ENV.starExtensions ~= nil
  
  self.enableInterpCam = true
  self.enableCursorOffset = true

  -- interp cam
  self.lerpSpeed = 0.1
  self.targetPos = mcontroller.position()
  
  -- cursor offset
  self.offsetLerpSpeedMult = 0.5
  self.targetOffset = {0, 0}
  self.maxCamDistance = 5
  self.cursorOffsetIntensity = 1
  
  self.loadTimer = 0.1
  if self.hasStarExtensions then
    camera.override({0, 0}, 0, {type="additive", influence=1})
  end
end

function update(dt)
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
      if self.enableInterpCam then
        updateTargetPos()
        camera.override(getOffset(), 0, {type="additive", influence=1})
      end
      
      if self.enableCursorOffset then
        updateCursorCamOffset()
        camera.override(self.targetOffset, 1, {type="additive", influence=1})
      end

    end
  end
end

function initCamera()
  self.targetPos = mcontroller.position()
end

function updateTargetPos()
  local playerPos = mcontroller.position()
  local tentative = vec2.lerp(self.lerpSpeed, self.targetPos, playerPos)
  self.targetPos = tentative
end

function getOffset()
  local playerPos = mcontroller.position()
  return world.distance(self.targetPos, playerPos)
end

function updateCursorCamOffset()
  if self.hasStarExtensions then
    local normal = vec2.norm(world.distance(player.aimPosition(), mcontroller.position()))
    local tentativeMag = world.magnitude(player.aimPosition(), mcontroller.position())
    local newOffset = vec2.mul(normal, self.cursorOffsetIntensity * math.min(tentativeMag, self.maxCamDistance))
    self.targetOffset = vec2.lerp(self.lerpSpeed * self.offsetLerpSpeedMult, self.targetOffset, newOffset)
  end
end