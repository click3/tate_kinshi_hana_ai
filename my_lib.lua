

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


thread_list = {};
thread_param = {};
thread_num = 0;

function create_thread(proc, ...)
  if (proc == nil)then
    error("ArgumentError",2);
  end

  thread_list[thread_num] = coroutine.create(proc);
  thread_param[thread_num] = {...};
  thread_num = thread_num + 1;
end

function thread_call()
  local i = 0;
  while (i < thread_num) do
    local ret = coroutine.resume(thread_list[i], unpack(thread_param[i], 1));
    thread_param[i] = {};
    if (ret) then
      i = i + 1;
    else
      table.remove(thread_list, i);
      table.remove(thread_param, i);
      thread_num = thread_num - 1;
    end
  end
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


