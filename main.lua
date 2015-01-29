
is_debug = true;

dofile("my_lib.lua");
dofile("ka_ai_duka_lib.lua");

function my_main()
  local i = 0;
  while true do
    print(i);
    i = i + 1;
    yield();
  end
end


