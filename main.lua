-- Player
local player = {}
player.position_x = 30
player.position_y = 30
player.ghost_position_x = player.position_x
player.ghost_position_y = player.position_y
player.speed_x = 200
player.speed_y = 200
player.radius = 5
player.no_obstacles = true
player.at_maze_entrance = false
player.at_maze_exit = false

function player.update( dt )
   player.no_obstacles = true
   player.ghost_move( dt )
end

function player.ghost_move( dt )
   if love.keyboard.isDown("right") then
      player.ghost_position_x = player.ghost_position_x + (player.speed_x * dt)
   end
   if love.keyboard.isDown("left") then
      player.ghost_position_x = player.ghost_position_x - (player.speed_x * dt)
   end
   if love.keyboard.isDown("up") then
      player.ghost_position_y = player.ghost_position_y - (player.speed_y * dt)
   end
   if love.keyboard.isDown("down") then
      player.ghost_position_y = player.ghost_position_y + (player.speed_y * dt)
   end   
end

function player.move()
   if player.no_obstacles then
      player.actual_move()
   else
      player.ghost_fallback()
   end
end

function player.actual_move()   
   player.position_x = player.ghost_position_x
   player.position_y = player.ghost_position_y
end

function player.ghost_fallback()
   player.ghost_position_x = player.position_x
   player.ghost_position_y = player.position_y
end

function player.draw()
   local segments_in_circle = 16
   local r, g, b, a = love.graphics.getColor()   
   love.graphics.setColor( 100, 0, 0, 100 )
   love.graphics.circle( 'fill',
			 player.position_x,
			 player.position_y,
			 player.radius,
			 segments_in_circle )
   love.graphics.setColor( 100, 0, 0, 100 )
   love.graphics.rectangle( 'line',
			    player.position_x - player.radius,
			    player.position_y - player.radius,
			    player.radius * 2,
			    player.radius * 2 )   
   love.graphics.setColor( r, g, b, a )
end

--Maze 
local maze = {}
maze.threshold = 150
maze.pixels = {}
maze.background = nil
maze.background_name = nil
maze.position_x = 50
maze.position_y = 50
maze.draw_pixels_flag = false
maze.entrance_top_left_x = nil
maze.entrance_top_left_y = nil
maze.exit_top_left_x = nil
maze.exit_top_left_y = nil
maze.entrance_exit_size = 10

function maze.construct_maze( background )
   maze.background_name = background
   maze.background = love.graphics.newImage( maze.background_name )
   maze.extract_pixels_from_background( background )
   maze.determine_entrance()
   maze.determine_exit()
end

function maze.extract_pixels_from_background()
   maze.clear_old_pixels()
   local image_data = maze.background:getData()
   local width, height = image_data:getDimensions()
   for x = 0, width - 1 do
      for y = 0, height - 1 do
	 local r, g, b, a = image_data:getPixel( x, y )
	 local intensity = ( r + g + a ) / 3
	 if maze.pixel_is_dark_enough( intensity ) then
	    maze.add_pixel_to_maze( x, y, intensity )	    
	 end
      end
   end
end

function maze.clear_old_pixels()
   for k, _ in ipairs( maze.pixels ) do
      maze.pixels[k] = nil
   end
end

function maze.pixel_is_dark_enough( intensity )
   return intensity < maze.threshold
end

function maze.add_pixel_to_maze( x, y, intensity )
   table.insert( maze.pixels, { x = x, y = y, I = intensity } )
end

function maze.determine_entrance()
   --currently not implemented
end

function maze.determine_exit()
   --currently not implemented
end

function maze.update( dt )   
end

function maze.draw()
   love.graphics.draw( maze.background,
		       maze.position_x,
		       maze.position_y )
   if maze.draw_pixels_flag then
      maze.draw_pixels()
   end
end

function maze.draw_pixels()
   local r, g, b, a = love.graphics.getColor()
   love.graphics.setColor( 0, 255, 0, 255 )
   for _, pix in ipairs( maze.pixels ) do
      if love.graphics.points then
	 love.graphics.points( maze.position_x + pix.x,
			       maze.position_y + pix.y )
      elseif love.graphics.point then
	 love.graphics.point( maze.position_x + pix.x,
			      maze.position_y + pix.y )
      end
   end
   love.graphics.setColor( r, g, b, a )
end


--Walls 
local walls = {}
walls.wall_thickness = 20
walls.current_level_walls = {}

function walls.new_wall( position_x, position_y, width, height )
   return( { position_x = position_x,
	     position_y = position_y,
	     width = width,
	     height = height } )
end

function walls.update_wall( single_wall )
end

function walls.draw_wall( single_wall )
   love.graphics.rectangle( 'line',
			    single_wall.position_x,
			    single_wall.position_y,
			    single_wall.width,
			    single_wall.height )
end

function walls.construct_walls()
   local left_wall = walls.new_wall(
      0,
      0,
      walls.wall_thickness,
      love.graphics.getHeight()
   )
   local right_wall = walls.new_wall(
      love.graphics.getWidth() - walls.wall_thickness,
      0,
      walls.wall_thickness,
      love.graphics.getHeight()
   )
   local top_wall = walls.new_wall(
      0,
      0,
      love.graphics.getWidth(),
      walls.wall_thickness
   )
   local bottom_wall = walls.new_wall(
      0,
      love.graphics.getHeight() - walls.wall_thickness,
      love.graphics.getWidth(),
      walls.wall_thickness
   ) 
   walls.current_level_walls["left"] = left_wall
   walls.current_level_walls["right"] = right_wall
   walls.current_level_walls["top"] = top_wall
   walls.current_level_walls["bottom"] = bottom_wall
end

function walls.update( dt )
   for _, wall in pairs( walls.current_level_walls ) do
      walls.update_wall( wall )
   end
end

function walls.draw()
   for _, wall in pairs( walls.current_level_walls ) do
      walls.draw_wall( wall )
   end
end

-- Collisions
local collisions = {}

function collisions.resolve_collisions()
   collisions.player_maze_collision( player, maze )
   collisions.player_walls_collision( player, walls )
   player.move()
   collisions.check_player_at_maze_entrance_exit( player, maze )
end

function collisions.check_rectangles_overlap( a, b )
   local overlap = false
   local shift_b_x, shift_b_y = 0, 0
   if not( a.x + a.width < b.x  or b.x + b.width < a.x  or
	   a.y + a.height < b.y or b.y + b.height < a.y ) then
      overlap = true
      if ( a.x + a.width / 2 ) < ( b.x + b.width / 2 ) then
	 shift_b_x = ( a.x + a.width ) - b.x
      else 
	 shift_b_x = a.x - ( b.x + b.width )
      end
      if ( a.y + a.height / 2 ) < ( b.y + b.height / 2 ) then
	 shift_b_y = ( a.y + a.height ) - b.y
      else
	 shift_b_y = a.y - ( b.y + b.height )      
      end      
   end
   return overlap, shift_b_x, shift_b_y
end

function collisions.point_inside_rectangle( x, y, rect )
   return ( rect.x <= x and x <= rect.x + rect.width and
	    rect.y <= y and y <= rect.y + rect.height )
end

function collisions.player_maze_collision( player, maze )
   local stuck_into = collisions.player_ghost_stuck_in_maze_wall( player, maze )   
   for _, pix in ipairs( stuck_into ) do
      print( "stuck into: " .. "x:" .. pix.x .. "y:".. pix.y )      
   end
   if #stuck_into > 0 then
      player.no_obstacles = player.no_obstacles and false
   else
      player.no_obstacles = player.no_obstacles and true
   end
end

function collisions.player_ghost_stuck_in_maze_wall( player, maze )
   local b = { x = player.ghost_position_x - player.radius,
	       y = player.ghost_position_y - player.radius,
	       width = player.radius * 2,
	       height = player.radius * 2 }
   local maze_pixels_stuck_into = {}
   --todo: optimize
   for _, pix in ipairs( maze.pixels ) do
      if collisions.point_inside_rectangle( maze.position_x + pix.x,
					    maze.position_y + pix.y,
					    b ) then
	 table.insert( maze_pixels_stuck_into, pix )
      end
   end
   return maze_pixels_stuck_into
end

function collisions.player_walls_collision()
   local overlap, shift_player_x, shift_player_y
   local b = { x = player.ghost_position_x - player.radius,
	       y = player.ghost_position_y - player.radius,
	       width = player.radius * 2,
	       height = player.radius * 2 }
   for _, wall in pairs( walls.current_level_walls ) do
      local a = { x = wall.position_x,
		  y = wall.position_y,
		  width = wall.width,
		  height = wall.height }
      overlap, shift_player_x, shift_player_y =
      	 collisions.check_rectangles_overlap( a, b )
      if overlap then
	 player.no_obstacles = player.no_obstacles and false
      else
	 player.no_obstacles = player.no_obstacles and true
      end
   end
end

function collisions.check_player_at_maze_entrance_exit( player, maze )
   -- not implemented
   -- player.at_entrance = check_rectanges_overlap( player, maze.entrance )
   -- player.at_exit = check_rectanges_overlap( player, maze.exit )
end

-- Levels
local levels = {}
levels.current_level = 1
levels.gamefinished = false
levels.sequence = { "test_maze.png", "test_maze_circular.png" }

function levels.switch_to_next_level()
   if levels.current_level == #levels.sequence then
      levels.current_level = 1
      maze.construct_maze( levels.sequence[levels.current_level] )
   else
      levels.current_level = levels.current_level + 1
      maze.construct_maze( levels.sequence[levels.current_level] )
   end
end

-- LOVE callbacks

local show_help = true

function love.load()
   local love_window_width = 1000
   local love_window_height = 800
   love.window.setMode( love_window_width,
                        love_window_height,
                        { fullscreen = false } )

   maze.construct_maze( levels.sequence[levels.current_level] )
   walls.construct_walls()
end
 
function love.update( dt )   
   player.update( dt )
   maze.update( dt )
   walls.update( dt )
   collisions.resolve_collisions()
end
 
function love.draw()
   love.graphics.setBackgroundColor( 255, 255, 255, 0)
   local r, g, b, a = love.graphics.getColor()
   maze.draw()
   love.graphics.setColor( 0, 0, 0, 255 )
   print_at_enter_at_exit()
   player.draw()
   walls.draw()
   if show_help then
      print_help()
   end
   love.graphics.setColor( r, g, b, a )
end

function love.keyreleased( key, code )
   if  key == 'escape' then
      love.event.quit()
   end    
end

function love.keyreleased( key, code )
   if key == 'n' then
      levels.switch_to_next_level()
   elseif key == 'p' then
      maze.draw_pixels_flag = not maze.draw_pixels_flag
   elseif key == '=' then
      maze.threshold = maze.threshold + 5
      maze.extract_pixels_from_background( background )
   elseif key == '-' then
      maze.threshold = maze.threshold - 5
      maze.extract_pixels_from_background( background )
   elseif key == 'h' then
      show_help = not show_help
   end
end

function print_help()
   local pos_x, pos_y = 30, 30
   love.graphics.printf( "'h': show/hide help",
			 pos_x, pos_y + 15, 200, "left" )
   love.graphics.printf( "'p': show extracted pixels",
			 pos_x, pos_y + 30, 200, "left" )
   love.graphics.printf( "'=': increase intensity threshold",
			 pos_x, pos_y + 45, 200, "left" )   
   love.graphics.printf( "'-': decrease intensity threshold",
			 pos_x, pos_y + 60, 200, "left" )
   love.graphics.printf( "maze pixel threshold = " .. maze.threshold,
			 pos_x, pos_y + 75, 200, "center" )
   love.graphics.printf( "'n': next level",
			 pos_x, pos_y + 90, 200, "left" )   
end

function print_at_enter_at_exit()
   local pos_x, pos_y = love.graphics.getWidth(), love.graphics.getHeight() 
   if player.at_maze_entrance then
      love.graphics.printf( "At maze entrance!",
			    pos_x, pos_y - 100, 200, "center" )
   elseif player.at_maze_exit then
      love.graphics.printf( "At maze exit!",
			    pos_x, pos_y - 100, 200, "center" )
   end
end


function love.quit()
  print("Thanks for playing! Come back soon!")
end


function sign( x )
   if x > 0 then
      return 1
   elseif x < 0 then
      return -1
   else
      return 0
   end
end

