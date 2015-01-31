

-- tableŠÖŒW


function table.contains(table, value)
  if (type(table) ~= "table") then
    error("ArgumentError", 2);
  end
  for table_key, table_value in pairs(table) do
    if (value == table_value) then
      return true;
    end
  end
  return false;
end


-- printŠÖŒW


function create_indent_string(indent_width)
  local result = "";
  for index = 0, indent_width - 1 do
    result = result .. "  ";
  end
  return result;
end

function table_to_string(table, indent_width)
  if (type(table) ~= "table") then
    error("ArgumentError", 2);
  end

  local result = "{\n";
  for key, value in pairs(table) do
    result =
      result
      .. create_indent_string(indent_width + 1)
      .. string.format("%s: %s,\n", my_to_string(key), my_to_string(value, indent_width + 1));
  end
  return result .. create_indent_string(indent_width) .. "}";
end

function my_to_string(obj, indent_width)
  if (type(obj) == "table") then
    return table_to_string(obj, indent_width);
  end
  if (table.contains({"number", "boolean"}, type(obj))) then
    return tostring(obj);
  end
  if (type(obj) == "string") then
    return string.format("\"%s\"", obj);
  end
  return tostring(obj);
end

function my_print(obj)
  print(my_to_string(obj, 0));
end


-- errorŠÖŒW


function create_error_string(message, level)
  assert(type(level) == "number");
  assert(type(message) == "string");
  local result = string.format("abort!!\nmessage: %s\n", message);
  if (level == 0) then
    return result;
  end
  result = result .. "stack_traceback:\n";
  local cur_level = level + 1;
  while true do
    local info = debug.getinfo(cur_level);
    my_print(cur_level);
    my_print(info);
    if (info == nil) then
      break;
    end
    result = result .. create_indent_string(1);
    local source = info["source"];
    local line_no = info["currentline"];
    local what = info["what"];
    local name = info["name"];
    result = result .. source;
    if (line_no ~= -1) then
      result = result .. string.format("(%d)", line_no);
    end
    result = result .. string.format(": %s", what);
    if (name ~= nil) then
      result = result .. string.format(":%s", name);
    end
    result = result .. "\n";
    cur_level = cur_level + 1;
  end
  return result;
end

function my_error(message, level)
  if (level ~= 0) then
    level = level + 1;
  end
  print(create_error_string(message, level));
  assert(false, message);
end


-- micro_threadŠÖŒW


head_thread_list = {};
head_thread_param = {};
head_thread_num = 0;
thread_list = {};
thread_param = {};
thread_num = 0;
tail_thread_list = {};
tail_thread_param = {};
tail_thread_num = 0;

function create_head_thread(proc, ...)
  if (proc == nil)then
    error("ArgumentError",2);
  end

  head_thread_list[head_thread_num] = coroutine.create(proc);
  head_thread_param[head_thread_num] = {...};
  head_thread_num = head_thread_num + 1;
end

function create_thread(proc, ...)
  if (proc == nil)then
    error("ArgumentError",2);
  end

  thread_list[thread_num] = coroutine.create(proc);
  thread_param[thread_num] = {...};
  thread_num = thread_num + 1;
end

function create_tail_thread(proc, ...)
  if (proc == nil)then
    error("ArgumentError",2);
  end

  tail_thread_list[tail_thread_num] = coroutine.create(proc);
  tail_thread_param[tail_thread_num] = {...};
  tail_thread_num = tail_thread_num + 1;
end

THREAD_TYPE_HEAD = 1;
THREAD_TYPE_NORMAL = 2;
THREAD_TYPE_TAIL = 3;

function thread_call_inner(list, param, num, thread_type)
  local i = 0;
  while (i < num) do
    local ret, message = coroutine.resume(list[i], unpack(param[i], 1));
    param[i] = {};
    if (thread_type == THREAD_TYPE_HEAD) then
      num = head_thread_num;
    elseif (thread_type == THREAD_TYPE_NORMAL) then
      num = thread_num;
    else
      num = tail_thread_num;
    end
    if (not ret) then
      error(message, 1);
    end
    local is_alive = (coroutine.status(list[i]) ~= "dead");
    if (is_alive) then
      i = i + 1;
    else
      table.remove(list, i);
      table.remove(param, i);
      num = num - 1;
      if (thread_type == THREAD_TYPE_HEAD) then
        head_thread_num = num;
      elseif (thread_type == THREAD_TYPE_NORMAL) then
        thread_num = num;
      else
        tail_thread_num = num;
      end
    end
  end
  return num;
end

function thread_call()
  head_thread_num = thread_call_inner(head_thread_list, head_thread_param, head_thread_num, THREAD_TYPE_HEAD);
  thread_num = thread_call_inner(thread_list, thread_param, thread_num, THREAD_TYPE_NORMAL);
  tail_thread_num = thread_call_inner(tail_thread_list, tail_thread_param, tail_thread_num, THREAD_TYPE_TAIL);
end

function yield()
  coroutine.yield();
end

function wait(n)
  if (n == nil) then
    error("ArgumentError",2);
  end
  while (n > 0) do
    yield();
    n = n-1
  end
end


