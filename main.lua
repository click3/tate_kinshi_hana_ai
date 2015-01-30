
is_debug = true;

dofile("my_lib.lua");
dofile("ka_ai_duka_lib.lua");

function my_main()
  local frame_count = 0;
  while true do
    print(frame_count);
    frame_count = frame_count + 1;
    yield();
  end
end


