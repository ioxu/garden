local _sprite_sheet = love.graphics.newImage( "resources/sprites/cherrymelon_a_r.png" )
_sprite_sheet:setFilter( "nearest", "nearest")

local Entity_Manager = {}
Entity_Manager.entities = {}
Entity_Manager.player_id = nil


function Entity_Manager.spawn( player_id, xpos, ypos)
    local ent = {
        color = {1,1,1,1},
        x = xpos or 0.0,
        y = ypos or 0.0,
        id = player_id,
        _quad = love.graphics.newQuad(31*16,22*16,16,16, _sprite_sheet),
    }
    Entity_Manager.entities[ player_id ] = ent
    return ent
end


function Entity_Manager.despawn( player_id )
    Entity_Manager.entities[ player_id ] = nil
end


function Entity_Manager.move( player_id, x, y )
    Entity_Manager.entities[player_id].x = x
    Entity_Manager.entities[player_id].y = y
end


function Entity_Manager.draw_entity( entity )
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw( _sprite_sheet, entity._quad, entity.x-(16*4)/2, entity.y-(16*4), 0, 4, 4 )
    love.graphics.setColor(0,1,0,0.25)
    love.graphics.circle("fill", entity.x, entity.y, 5)
    
end

--- draw all entitites
function Entity_Manager.draw()
    for k, entity in pairs( Entity_Manager.entities ) do
        Entity_Manager.draw_entity( entity )
    end
end

return Entity_Manager