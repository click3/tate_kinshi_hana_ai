
--[[


AI名：縦移動禁止花AI@メディスン


縦移動を封印し、横移動だけに特化してそこそこ戦えるようにしたAI。
別になめプではなく、余裕こきすぎて24時間しか作業時間が取れなかったため、
実装内容を絞って時間対効率の最大化を図ったためこうなった。

アルゴリズムも最初考えていたものが処理速度上不可能と発覚したので即興。
その割には結構いい線いってるのではなかろうか。

@メディスンとあるが、別にメディスン用にカスタマイズされているわけでもなく、どのキャラでも動く。
単に作者がメディスン好きなだけである。
メディスンかわいいよメディスン。

一応LunaAI相手でもラウンド取れることもあるぐらいにはちゃんと戦える。
※ただし咲夜さんと映姫様除く。


仕組み：
自身のy座標一列分の配列(以下危険度マップ)を作り
弾や敵などに対し、そのy座標に到達するまでにかかる時間と、到達したときのx座標を算出。
その周囲を到達までの時間で埋めるを繰り返す。

すると、弾が到達するまでにかかる時間が長いx座標ほど安全という理屈により、
どの辺のx座標を目指せばいいかがなんとなくわかるので、
あとはそれを念頭に置いて移動したり色々するだけのAI。

一応軽いキャラ対策などは入れたが、後述の弱点のように問題点は多い。
それ以外にも、粒弾相手でも被弾してしまうようなコーナーケースのつぶしは足りないし、
長期的展望による回避行動もとらないし、C2の運用やコンボなど改善の余地はたくさんある。


弱点：
当然ながら縦には移動しない(というか後ろの弾がまったく見えていないので出来ない)ので、
咲夜さんのC2/C3は撃たれたら真横弾で落ちるのは確定。
映姫様の自機狙いレーザーの対策をとっていないので、されるとあっという間に死ぬ。
文さんのExは判定強いくせに早いので、ちょっと周囲の弾配置が悪いとすぐ詰む。
ルナサを相手にすると後ろから弾が飛んでくるため運ゲー化する。
チルノはパーフェクトフリーズで背後の弾がこっち向かってくると避ける手段がない。
ミスティアは未対策なので、チャージアタックの弾源に重なり落ちる光景がよく見られる。
てゐさんは中央からちょっと外れるとExの軌道に巻き込まれ、そのまま壁と挟まれて死ぬ。


ライセンス：
・本ライセンスにおいて、全ての条項は「変更の有無を問わず、明示暗示を問わず、商業慈善を問わず、
  個人法人を問わず、保持使用を問わず、有料無料を問わず、全体一部を問わず、コピー派生を問わず
  実行ファイルソースファイルを問わず、故意錯誤を問わず」と装飾されている物として扱う。
・著作権者は本ソフトウェアに関する一切の保障義務をもたない。
・上記条項唯一の例外として、本ライセンスに違反した場合を除いて著作権者から
  本ソフトウェアに関する一切の法的措置を受ける事が無い事のみ保証される。
・著作権者やその他保持者がこのライセンスの範囲で行う活動に支障が無い範囲であれば何を行っても構わない。
・上記条項の”何を行っても構わない”には本ソフトウェアの製作者を偽っての再配布も含まれる。
・全ての権利の行使において、著作権者への連絡、著作権者やライセンス条項の記載、
  適用ライセンスなどの制限は一切存在しない。
著作権者名：sweetie
メールアドレス：ｓｗｅｅｔｉｅ（あっと）ｃｌｉｃｋ３．ｏｒｇ


]]

-- trueだとprintがファイル出力になり、被弾したら実行が止まる
is_debug = false;

dofile("my_lib.lua");
dofile("ka_ai_duka_lib.lua");
dofile("key_manager.lua");

-- 定数
DISTANCE_MAX = 65536;
UNSAFE = 300;

-- 調整することもある定数
SAFE_MARGIN = 1.0;
SAFE_MARGIN_POINT = 2;
DEFAULT_Y_POSITION = 384;
CHARGE_TRIGGER_BULLET_COUNT = 100;
CHECK_DISTANCE_MAX = 50;

-- 危険度マップを初期化
function clear_field(field)
  for x = 1, 300 do
    field[x] = DISTANCE_MAX;
  end
end

-- playerのy座標まで到達するのにかかるフレーム数と、その際のx座標やあたり判定の大きさを返す
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
  width = width * SAFE_MARGIN + SAFE_MARGIN_POINT;
  if (distance + width < 0) then
    return;
  end
  distance = math.max(0, math.floor(distance - width));
  width = width + (width / obj.vy) * obj.vx;
  if (distance < CHECK_DISTANCE_MAX) then
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

-- 相手側のGameSideを取得する
function get_enemy_game_side()
  local index = 1;
  if (player_side == 1) then
    index = 2;
  end
  return game_sides[index];
end

-- 危険度配列を更新する
function update_field(field)
  local my_game_side = game_sides[player_side];
  local player = my_game_side.player;
  clear_field(field);
  for index, bullet in ipairs(my_game_side.bullets) do
    update_field_single(field, player, bullet);
  end
  for index, enemy in ipairs(my_game_side.enemies) do
    if (enemy.isPseudoEnemy) then
      local enemy_player = get_enemy_game_side().player;
      if (enemy_player.character == CharacterType.Marisa) then
        local width = 25;
        enemy.vx = 0;
        enemy.vy = 1;
        enemy.y = DEFAULT_Y_POSITION - enemy.vy * 10 - width;
        enemy.hitBody = {
          x = enemy.x;
          y = enemy.y;
          type = HitType.Rect;
          width = width;
        };
      end
    end
    update_field_single(field, player, enemy);
  end
  for index, ex in ipairs(my_game_side.exAttacks) do
    if (ex.hitBody and ex.type == ExAttackType.Reimu) then
      ex.hitBody.radius = 21;
    elseif (not ex.hitBody) then
      if (ex.type == ExAttackType.Youmu) then
        ex.vx = 4;
        ex.vy = 4;
        ex.hitBody = {
          x = ex.x;
          y = ex.y;
          type = HitType.Circle;
          radius = 14;
        };
      end
    end
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
    local target_field = field[index];
    if (target_field <= (i + 1) / speed) then
      break;
    end
    if (target_field > distance) then
      local is_success = true;
      for j = 1, speed do
        local index2 = index + step * j;
        if (index2 < 1 or index2 > 300) then
          break;
        end
        if (field[index2] < target_field) then
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

-- 左右それぞれで安全な場所までどれぐらい距離があるかを返す
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

-- 左方向がある程度安全かを調べる
function is_left_safe(field)
  return is_safe(field, -1);
end

-- 右方向がある程度安全かを調べる
function is_right_safe(field)
  return is_safe(field, 1);
end

-- 低速の方が安全な場合にtrue
-- 数ピクセルだけの安全地帯に滑り込む用
function is_slow_safe(field, player, dir)
  local x = player.x;
  local fast = math.ceil(player.speedFast + 1); -- 誤判定が多いので余分目に
  local slow = player.speedSlow;
  local index_fast = math.max(1, math.min(300, math.floor(x + 150 + fast * dir + 0.5)));
  local index_slow = math.max(1, math.min(300, math.floor(x + 150 + slow * dir + 0.5)));
  return field[index_fast] > field[index_slow];
end

-- https://bitbucket.org/ide_an/ka_ai_duka/issue/6 対策
function fix_bug()
  local my_game_side = game_sides[player_side];
  local player = my_game_side.player;
  player.hitBodyRect.width = 3;
  player.hitBodyRect.height = 3;
end

-- デバッグ用
function create_field_string(field, start_index, end_index)
  if (not is_debug) then
    return "";
  end
  local str = "";
  for index = start_index, end_index do
    if (1 <= index and index <= 300) then
      str = str .. string.format("%.0f, ", field[index]);
    end
  end
  return str;
end

-- デバッグ用
function debug_assert(expression, field)
  if (not is_debug or expression) then
    return;
  end
  local my_game_side = game_sides[player_side];
  local player = my_game_side.player;
  print(string.format("%f:%f", player.x, player.y));
  print(my_game_side.bullets);
  print(my_game_side.enemies);
  print(my_game_side.exAttacks);
  print(create_field_string(field, 1, 300));
  error("assert!", 2);
end

-- デバッグ用
function monitoring(field)
  local my_game_side = game_sides[player_side];
  local player = my_game_side.player;
  local x = math.floor(player.x + 0.5);
  print(create_field_string(field, x + 150 - 15, x + 150));
  print(create_field_string(field, x + 150, x + 150 + 15));
  do return; end
  for i, bullet in ipairs(my_game_side.bullets) do
    if (not bullet.hitBody) then
      print(bullet);
    end
  end
end

-- 経過フレーム数をカウントする
frame_count = 0;
function count_frame_thread()
  while (true) do
    frame_count = frame_count + 1;
    yield();
  end
end

-- 射撃を打ち続ける
-- メディスンの毒霧で敵の動作不良を狙いたいのでコンボ切りはしない
-- が、雑魚敵を追ったりはせずコンボは途切れやすいのであまり意味はない
function shot_thread()
  while (true) do
    if ((frame_count % 2) == 0) then
      push_key(KEY_SHOT);
    end
    yield();
  end
end

-- y座標を指定値に維持する
-- ぶっちゃけ最下段のほうがいいのだが、見栄えがいいので初期y座標を維持させている
function keep_y_position()
  while (true) do
    local player = game_sides[player_side].player;
    local s = DEFAULT_Y_POSITION;
    local e = DEFAULT_Y_POSITION + player.speedFast;
    if (player.y < s) then
      push_key(KEY_DOWN);
    elseif (player.y > e) then
      push_key(KEY_UP);
    end
    yield();
  end
end

-- 被弾監視
is_damage = false;
function check_damage()
  local life = 10.0;
  while (true) do
    local player = game_sides[player_side].player;
    if (life ~= player.life) then
      life = player.life;
      is_damage = true;
    else
      is_damage = false;
    end
    yield();
  end
end

-- C2～C4を使ったかを監視している
-- キー入力時にフラグ立ててもいいけど、こうやって独立させた方が見通しは良い
is_charge_attack = false;
function check_charge_attack()
  local prev = 100;
  while (true) do
    local player = game_sides[player_side].player;
    local cur = player.currentChargeMax;
    if (prev > cur) then
      is_charge_attack = true;
    else
      is_charge_attack = false;
    end
    prev = cur;
    yield();
  end
end

-- 無敵チェック
-- 無敵時間とか数値はおざなり
is_invincible = false;
function check_invincible()
  local invincible_frame_count = 0;
  while (true) do
    if (invincible_frame_count > 0) then
      invincible_frame_count = invincible_frame_count - 1;
    else
      is_invincible = false;
    end
    if (is_damage or is_charge_attack) then
      invincible_frame_count = 90;
      is_invincible = true;
    end
    yield();
  end
end

-- ゲージが3本以上あって弾が多いならC2を試みる
function try_charge()
  while (true) do
    local my_game_side = game_sides[player_side];
    local player = my_game_side.player;
    if (player.currentCharge > 0) then
      if (player.currentCharge >= 200) then
        -- ショットボタンを押さない
      else
        push_key(KEY_SHOT);
      end
    elseif (player.currentChargeMax >= 300) then
      if (my_game_side.bullets[CHARGE_TRIGGER_BULLET_COUNT]) then
        push_key(KEY_SHOT);
      end
    end
    yield();
  end
end

-- エントリーポイント
-- mainさんはマイクロスレッド内部で使用されている
function my_main()
  print("ai initialize");
  create_head_thread(check_damage);
  create_thread(count_frame_thread);
  create_thread(shot_thread);
  create_thread(keep_y_position);
  create_thread(check_invincible);
  create_thread(try_charge);
  local field = {};
  clear_field(field);
  while true do
    print("\nrun");
    fix_bug();
    local my_game_side = game_sides[player_side];
    local player = my_game_side.player;
    monitoring(field);
    debug_assert(not is_damage, field);
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
        if (not is_invincible) then
          debug_assert(false, field);
          push_key(KEY_BOMB);
        end
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


