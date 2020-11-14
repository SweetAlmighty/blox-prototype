local rows = 5
local grid = { }
local shapes = { }
local columns = 5
local new_shape = { }
local row_index = { }
local col_index = { }
local block_width = 53
local block_height = 53
local selected_shape = nil
local max_int = math.pow(2, 52)
local colors = {
    { r = 1, g = 0, b = 0 },
    { r = 0, g = 1, b = 0 },
    { r = 0, g = 0, b = 1 },
    { r = 1, g = 1, b = 0 },
    { r = 0, g = 1, b = 1 },
    { r = 1, g = 0, b = 1 },
    { r = 0, g = .3, b = 0 },
    { r = .3, g = 0, b = .3 },
    { r = .3, g = .3, b = .3 },
    { r = 0, g = .7, b = 0 },
    { r = .7, g = 0, b = .7 },
    { r = .7, g = .7, b = .7 },
}

function shuffle(list)
    local shuffled = { }
    for _, v in ipairs(list) do
        local pos = math.random(1, #shuffled+1)
        table.insert(shuffled, pos, v)
    end
    return shuffled
end

function find_next()
    for i=#new_shape, 1, -1 do
        local x, y = new_shape[i].row, new_shape[i].column
        local next = shuffle(grid[x][y].neighbors)
        for j=1, #next, 1 do
            if next[j].x ~= nil and next[j].y ~= nil then
                if not grid[next[j].x][next[j].y].checked then
                    return next[j].x, next[j].y
                end
            end
        end
    end
end

function create_grid()
    for i=1, rows, 1 do
        local row = { }
        for j=1, columns, 1 do
            row[#row + 1] = {
                row = i,
                column = j,
                checked = false,
                occupied = false,
                x = i * block_width,
                y = j * block_height,
                neighbors = {
                    { x = i, y = j - 1 > 0 and j - 1 or nil },
                    { x = i - 1 > 0 and i - 1 or nil, y = j },
                    { x = i + 1 <= rows and i + 1 or nil, y = j },
                    { x = i, y = j + 1 <= columns and j + 1 or nil }
                }
            }

            row[#row].midpoint = {
                x = row[#row].x + (block_width / 2),
                y = row[#row].y + (block_height / 2)
            }
        end

        grid[#grid + 1] = row
    end
end

function draw_grid()
    love.graphics.setColor(1, 1, 1)

    for i=1, #grid, 1 do
        for j=1, #grid[i], 1 do
            local g = grid[i][j]
            love.graphics.rectangle('fill', g.x, g.y, block_width-1, block_height-1)
        end
    end
end

function create_shapes()
    shapes = { }

    row_index = { }
    for i=1, rows, 1 do row_index[#row_index + 1] = i end
    row_index = shuffle(row_index)

    col_index = { }
    for i=1, columns, 1 do col_index[#col_index + 1] = i end
    col_index = shuffle(col_index)

    local amount = 0
    while amount < #row_index * #col_index do
        for i=1, #row_index, 1 do
            for j=1, #col_index, 1 do
                local x, y = row_index[i], col_index[j]
                if not grid[x][y].checked then
                    new_shape = { }
                    for _=1, 5, 1 do
                        if x ~= nil and y ~= nil then
                            grid[x][y].checked = true
                            new_shape[#new_shape + 1] = {
                                row = x,
                                column = y,
                                x = x * block_width,
                                y = y * block_height
                            }
                            x, y = find_next()
                        end
                    end
                    amount = amount + #new_shape
                    shapes[#shapes + 1] = new_shape
                end
            end
        end
    end

    for i=1, #grid, 1 do
        for j=1, #grid[i], 1 do
            grid[i][j].checked = false
        end
    end
end

function place_shapes()
    local randomized_shapes = shuffle(shapes)
    local width, height = love.graphics.getDimensions()

    for i=1, #randomized_shapes, 1 do
        local shape = randomized_shapes[i]

        local x = math.random(block_width, width - block_width) - shape[1].x
        local y = math.random(block_height * 6, height - block_height) - shape[1].y

        for j=1, #shape, 1 do
            shape[j].x = shape[j].x + x
            shape[j].y = shape[j].y + y
        end
    end
end

function draw_shapes()
    for i=1, #shapes, 1 do
        for j=1, #shapes[i], 1 do
            local c = colors[i]
            local shape = shapes[i][j]

            love.graphics.setColor(c.r, c.g, c.b)
            love.graphics.rectangle('fill', shape.x, shape.y, block_width-1, block_height-1)
        end
    end
end

function move_selected_shape(dx, dy)
    if selected_shape ~= nil then
        for i=1, #selected_shape, 1 do
            selected_shape[i].x = selected_shape[i].x + dx
            selected_shape[i].y = selected_shape[i].y + dy
        end
    end
end

function draw_reset_button()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('line', 50, 1, 100, 40)
    love.graphics.print('Reset', 51, 2)
end

function distance(x1,y1,x2,y2)
    local dx = x1 - x2
    local dy = y1 - y2
    local s = dx * dx + dy * dy
    return squared and s or math.sqrt(s)
end

function love.draw()
    draw_reset_button()
    draw_grid()
    draw_shapes()
end

function love.load(arg)
    math.randomseed((os.time()))

    create_grid()
    create_shapes()
    place_shapes()
end

function love.mousemoved(x, y, dx, dy, istouch)
    move_selected_shape(dx, dy)
end

function love.mousepressed(x, y, button, istouch, presses)
    if x > 1 and x < 100 and y > 1 and y < 40 then
        create_shapes()
        place_shapes()
    else
        for i=1, #shapes, 1 do
            for j=1, #shapes[i], 1 do
                local shape = shapes[i][j]
                if x >= shape.x and x < shape.x + block_width then
                    if y >= shape.y and y < shape.y + block_height then
                        selected_shape = shapes[i]

                        -- move shape away from finger
                        move_selected_shape(0, -100)
                        return
                    end
                end
            end
        end
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if selected_shape ~= nil then
        local corners = { }
        for i=1, #selected_shape, 1 do
            local min_dist = max_int
            local closest_gridspace = nil

            for j=1, #grid, 1 do
                for k=1, #grid[j], 1 do
                    local midpoint = {
                        x = selected_shape[i].x + (block_width / 2),
                        y = selected_shape[i].y + (block_height / 2)
                    }

                    local dist = distance(grid[j][k].midpoint.x, grid[j][k].midpoint.y, midpoint.x, midpoint.y)

                    if dist < block_height and dist < min_dist then
                        min_dist = dist
                        closest_gridspace = {
                            x = j,
                            y = k,
                        }
                    end
                end
            end

            if min_dist ~= max_int then
                local blah = false
                for j=1, #corners, 1 do
                    if not blah and corners[j].x == closest_gridspace.x and corners[j].y == closest_gridspace.y then
                        blah = true
                    end
                end

                if not blah then
                    corners[#corners + 1] = {
                        block = i,
                        x = closest_gridspace.x,
                        y = closest_gridspace.y
                    }
                end
            end
        end

        if #corners == #selected_shape then
            for i=1, #corners, 1 do
                selected_shape[corners[i].block].x = grid[corners[i].x][corners[i].y].x
                selected_shape[corners[i].block].y = grid[corners[i].x][corners[i].y].y
            end
        else
            -- move shape back towards finger
            move_selected_shape(0, 100)
        end

        selected_shape = nil
    end
end