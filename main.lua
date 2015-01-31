
is_debug = true;

dofile("my_lib.lua");
dofile("ka_ai_duka_lib.lua");
dofile("key_manager.lua");

DISTANCE_MAX = 65536;
UNSAFE = 300;
SAFE_MARGIN = 1.0;

function clear_field(field)
  for x = 1, 300 do
    field[x] = DISTANCE_MAX;
  end
end

function get_distance_and_x_and_width(obj)
  local player = game_sides[player_side].player;
  local distance = (player.y - obj.y) / obj.vy;
  local body = obj.hitBody;
  local x = obj.x + (obj.vx * distance);
  local width = 0;
  if (body.type == HitType.Circle) then
    width = body.radius;
  else
    width = body.width/2;
  end
  return distance, x, width;
end

function update_field_single(field, player, obj)
  if ((not obj.hitBody) or obj.vy <= 0) then
    return;
  end
  local distance, x, width = get_distance_and_x_and_width(obj);
  width = width + player.hitBodyRect.width / 2;
  width = width * SAFE_MARGIN;
  if (distance + width < 0) then
    return;
  end
  distance = math.max(0, math.floor(distance - width));
  if (distance < 30) then
    local start_pos = math.max(-149, math.floor(x - width)) + 150;
    local end_pos = math.min(149, math.ceil(x + width)) + 150;
    local i = start_pos;
    while (i <= end_pos) do
      if (field[i] > distance) then
        field[i] = distance;
      end
      i = i + 1;
    end
  end
end

function update_field(field)
  local my_game_side = game_sides[player_side];
  local player = my_game_side.player;
  clear_field(field);
  for index, bullet in ipairs(my_game_side.bullets) do
    update_field_single(field, player, bullet);
  end
  for index, enemy in ipairs(my_game_side.enemies) do
    update_field_single(field, player, enemy);
  end
  for index, ex in ipairs(my_game_side.exAttacks) do
    update_field_single(field, player, ex);
  end
end

function get_safe_area_inner(field, x, distance, speed, step)
  if (distance == DISTANCE_MAX) then
    return 0;
  end
  for i = 1, 300 do
    local index = x + 150 + step * i;
    if (index < 1 or index > 300) then
      break;
    end
    if (field[index] > distance) then
      local is_success = true;
      for j = 1, speed do
        local index2 = index + step * j;
        if (index2 < 1 or index2 > 300) then
          break;
        end
        if (field[index2] < field[index]) then
          is_success = false;
          break;
        end
      end
      if (is_success) then
        return i;
      end
    end
  end
  return UNSAFE;
end

function get_safe_area(field)
  local player = game_sides[player_side].player;
  local x = math.ceil(player.x);
  local distance = field[x + 150];
  local speed = math.ceil(player.speedSlow);
  local left = get_safe_area_inner(field, x, distance, speed, -1);
  x = math.floor(player.x);
  local right = get_safe_area_inner(field, x, distance, speed, 1);
  return left, right;
end

function is_safe(field, step)
  local player = game_sides[player_side].player;
  local x = math.floor(player.x + 0.5);
  local border = field[x + 150];
  for i = 1, 10 do
    local index = x + 150 + (step * i);
    if (index < 1 or index > 300 or field[index] < border) then
      return false;
    end
  end
  return true;
end

function is_left_safe(field)
  return is_safe(field, -1);
end

function is_right_safe(field)
  return is_safe(field, 1);
end

function is_slow_safe(field, player, dir)
  local x = player.x;
  local fast = player.speedFast;
  local slow = player.speedSlow;
  local index_fast = math.max(1, math.min(300, math.floor(x + 150 + fast * dir + 0.5)));
  local index_slow = math.max(1, math.min(300, math.floor(x + 150 + slow * dir + 0.5)));
  return field[index_fast] > field[index_slow];
end

-- https://bitbucket.org/ide_an/ka_ai_duka/issue/6 ëŒçÙ
function fix_bug()
  local my_game_side = game_sides[player_side];
  local player = my_game_side.player;
  player.hitBodyRect.width = 3;
  player.hitBodyRect.height = 3;
end

function debug_assert(expression, field)
  if (not is_debug or expression) then
    return;
  end
  local my_game_side = game_sides[player_side];
  local player = my_game_side.player;
  print(string.format("%f:%f", player.x, player.y));
  print(my_game_side.bullets);
  local str = "";
  for i = 1, 300 do
    str = str .. string.format("%.0f, ", field[i]);
  end
  print(str);
  error("assert!", 2);
end

function monitoring(field)
  local my_game_side = game_sides[player_side];
  local player = my_game_side.player;
  print(my_game_side.bullets);
  local str = "";
  for i = -15, 15 do
    local index = math.floor(player.x + 0.5) + 150 + i;
    if (1 <= index and index <= 300) then
      str = str .. string.format("%.0f, ", field[index]);
    end
  end
  print(str);
  do return; end
  for i, bullet in ipairs(my_game_side.bullets) do
    if (not bullet.hitBody) then
      print(bullet);
    end
  end
end

frame_count = 0;

function count_frame_thread()
  while (true) do
    frame_count = frame_count + 1;
    yield();
  end
end

function shot_thread()
  while (true) do
    if ((frame_count % 2) == 0) then
      push_key(KEY_SHOT);
    end
    yield();
  end
end

function my_main()
  create_thread(count_frame_thread);
  create_thread(shot_thread);
  local life = 10.0;
  local field = {};
  clear_field(field);
  while true do
    fix_bug();
    local my_game_side = game_sides[player_side];
    local player = my_game_side.player;
    monitoring(field);
    debug_assert(life == player.life, field);
    if (-150 < player.x and player.x < 150 and 0 < player.y and player.y < 450) then
      update_field(field);
      local left, right = get_safe_area(field);
      local x = math.floor(player.x + 0.5);
      local distance = field[x + 150];
      print(string.format("%5.0f:%3.0f:%3.0f", distance, left, right));
      if (distance == DISTANCE_MAX) then
        if (x < 0) then
          if (is_right_safe(field)) then
            print("move right(center)");
            push_key(KEY_RIGHT);
          end
        elseif (x > 0) then
          if (is_left_safe(field)) then
            print("move left(center)");
            push_key(KEY_LEFT);
          end
        else
        end
      elseif (distance == 0) then
        debug_assert(false, field);
        push_key(KEY_BOMB);
      else
        if (left == UNSAFE and right == UNSAFE) then
          -- TODO
        elseif (left < right) then
          print("move left(safe)");
          push_key(KEY_LEFT);
          if (is_slow_safe(field, player, -1)) then
            push_key(KEY_SLOW);
          end
        else
          print("move right(safe)");
          push_key(KEY_RIGHT);
          if (is_slow_safe(field, player, 1)) then
            push_key(KEY_SLOW);
          end
        end
      end
    end
    yield();
  end
end


