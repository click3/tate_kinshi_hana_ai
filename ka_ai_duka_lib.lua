
print_log_fp = nil;

if (is_debug) then
  print_log_fp = io.open(os.date("%Y%m%d_" .. tostring(player_side) .. ".log"), "a");
  function print(obj)
    print_log_fp:write(my_to_string(obj, 0) .. "\n");
    print_log_fp:flush();
  end
else
  function print(obj)
  end
end

function error(message, level)
  if (level ~= 0) then
    level = level + 1;
  end
  print(create_error_string(message, level));
  assert(false, message);
end

is_initialized = false;

function main()
  if (not is_initialized) then
    create_thread(my_main);
    is_initialized = true;
  end
  thread_call();
end

