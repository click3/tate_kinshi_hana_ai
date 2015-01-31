
KEY_SHOT = 1;
KEY_BOMB = 2;
KEY_SLOW = 3;
KEY_UP = 4;
KEY_DOWN = 5;
KEY_LEFT = 6;
KEY_RIGHT = 7;

key_list = {};

function push_key(key_type)
  key_list[key_type] = true;
end

function clear_key()
  key_list = {};
end

function flush_key()
  local list = {
    {KEY_SHOT, 1},
    {KEY_BOMB, 2},
    {KEY_SLOW, 4},
    {KEY_UP, 16},
    {KEY_DOWN, 32},
    {KEY_LEFT, 64},
    {KEY_RIGHT, 128},
  };
  local key = 0;
  for i, item in ipairs(list) do
    if (key_list[item[1]]) then
      key = key + item[2];
    end
  end
  sendKeys(key);
end

function key_thread()
  while (true) do
    flush_key();
    clear_key();
    yield();
  end
end

create_tail_thread(key_thread);

