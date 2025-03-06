require '/scripts/vec2.lua'

function init()
  self.hasStarExtensions = _ENV.starExtensions ~= nil
  if(self.hasStarExtensions) then
    camera.override(mcontroller.position(), 0) 
  end
end

function update(dt)
  if self.hasStarExtensions then
    camera.override({1, 0}, 0, {type="additive", influence=1})
  end
end

function interpolate(prev, current)
  local mag = world.magnitude(current, prev)
  local vec = world.distance(current, prev)
  return vec2.norm(vec) * mag / 2
end
