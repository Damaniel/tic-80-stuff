-- title:  Move It, Man!
-- author: Shaun Brandt
-- desc:   A small Sokoban clone
-- script: lua

--------------------------------------------------------------------------------
-- loadlevel
--
-- Loads and parses a level from the g_levs table.  Places the resulting data
-- into the g_state object so it can be used in other parts of the game.
-- See notes.txt for a list of the fields in g_state.
--
-- Note: The Lua 1-based tables make sorting out values difficult when most
-- languages used 0-based arrays.  This function uses a source string with
-- a 1-based index, and the destination tables will also be 1-based, but the
-- (x,y) coordinates saved will be 0-based.
--
-- 1-based:
--   g_levs
--   g_levs[5]
--   g_state.lv, g_state.bx, g_state.tg
-- 0-based:
--   x, y
--------------------------------------------------------------------------------
function loadlevel(l_num)
  g_state.l=l_num
  g_state.w=g_levs[l_num][1]
  g_state.h=g_levs[l_num][2]
  g_state.tt=g_levs[l_num][3]
  g_state.tm=g_levs[l_num][4]
  g_state.lv={}
  g_state.bx={}
  g_state.tg={}
  g_state.nt=0
  g_state.ot=0
  g_state.t=0
  g_state.et=0	
  g_state.pd=0
  -- Iterate through the string in row order
  for y=0, g_state.h-1 do
    for x=0, g_state.w-1 do
      -- Find the character in the string corresponding to the level position
      -- at (x,y)
      off=(y)*g_state.w+x+1
      c=string.sub(g_levs[l_num][5],off,off)
      if c=="@" then
        -- If the player position is found, initialize it and place an empty space
        -- in the level data
        g_state.p={x,y}
        table.insert(g_state.lv,' ')
      elseif c=="$" then
        -- If a box is found, add it to the list of boxes and place an empty space
        -- in the level data
        table.insert(g_state.bx,{x,y})
        table.insert(g_state.lv,' ')
      elseif c=="." then
        -- If a target square is found, add it to the list of targets and
        -- place the target in the level data
        table.insert(g_state.tg,{x,y})
        table.insert(g_state.lv,c)
        g_state.nt=g_state.nt+1
      elseif c=="*" then
        -- If a box on a target is found, add the box and target to their
        -- respective lists and place the target in the level data
        table.insert(g_state.bx,{x,y})
        table.insert(g_state.tg,{x,y})
        table.insert(g_state.lv,'.')
        g_state.ot=g_state.ot+1
        g_state.nt=g_state.nt+1
      else
        -- Otherwise, just keep the level data as-is
        table.insert(g_state.lv,c)
      end
    end
  end
end

--------------------------------------------------------------------------------
-- get_ul
--
-- Gets the position on the screen's tilemap that corresponds to where the
-- upper left corner of the level is.  The level is always (roughly) centered
-- on the screen.
--------------------------------------------------------------------------------
function get_ul()
  lv_x=10-math.floor(g_state.w/2)
  lv_y=8-math.floor(g_state.h/2)
  return lv_x, lv_y
end

--------------------------------------------------------------------------------
-- render_level
--
-- Updates the tile map to place the static elements of the level into the
-- tile map, and then draws the appropriate region to the screen.
--------------------------------------------------------------------------------
function render_level()
  -- Put the background tile into the correct regions of the screen
  for x=0,19 do
    for y=0,16 do
      mset(x,y,4)
    end
  end

  -- Find the center of the area designated for the level.  The area is 20x17,
  -- so things won't be 100% centered, but any level up to 20x17 should fit.
  lv_x,lv_y=get_ul()
				
  -- Iterate through the level data
  for y=0,g_state.h-1 do
    for x=0,g_state.w-1 do
      -- Find the offset into the string.  Get the ASCII value of the character
      off=y*g_state.w+x+1
      b=string.byte(g_state.lv[off])						
      if b>=97 and b<=112 then
        -- If the character falls between a and p (97 and 112), subtract 97 and
        -- use the remainder as an index into the tilemap for the appropriate
        -- wall tile (they're held in indices 16-31)
        mset(lv_x+x,lv_y+y,16+(b-97))
      elseif b==32 then
        -- If the character is a space, set a floor tile
        mset(lv_x+x,lv_y+y,3)
      elseif b==46 then
        -- If the characeter is a target square, set a target tile.
        mset(lv_x+x,lv_y+y,2)
      end
    end
  end
  -- render the appropriate part of the tile map to the screen
  map(0,0,30,17)		 
end

--------------------------------------------------------------------------------
-- render_sprites
--
-- Draws the non-static elements of the screen - this includes the player
-- and boxes.
--------------------------------------------------------------------------------
function render_sprites()
  -- Find the center of the area designated for the level.  The area is 20x17,
  -- so things won't be 100% centered, but any level up to 20x17 should fit.
  lv_x,lv_y=get_ul()

  for x=1,#g_state.bx do
    spr(256,8*(lv_x+g_state.bx[x][1]),8*(lv_y+g_state.bx[x][2]),0)
  end		
  -- Draw the player.  Uses g_state.pd to draw the appropriate direction of
  -- the player sprite.
  spr(257+g_state.pd,8*(lv_x+g_state.p[1]),8*(lv_y+g_state.p[2]),0)
end

--------------------------------------------------------------------------------
-- is_wall
--
-- Determines whether the specified location is a wall or not.
--------------------------------------------------------------------------------
function is_wall(x,y)
  -- Get the upper left position of the level
  lv_x, lv_y=get_ul()

  -- get the tile at (x,y) relative to the upper left
  tile=mget(lv_x+x,lv_y+y)
  -- The tiles with indices 16-31 are the wall tiles
  if tile>=16 and tile <=31 then
    return true
  end
  return false
end

--------------------------------------------------------------------------------
-- is_target
--
-- Determines whether the specified location is a target square
--------------------------------------------------------------------------------
function is_target(x,y)
  for i=1,#g_state.tg do
    if g_state.tg[i][1]==x and g_state.tg[i][2]==y then
      return true
    end
  end
  return false
end

--------------------------------------------------------------------------------
-- is_box
--
-- Determines whether the specified location contains a box or not
--------------------------------------------------------------------------------
function is_box(x,y)
  for i=1,#g_state.bx do
    if g_state.bx[i][1]==x and g_state.bx[i][2]==y then
      return true
    end
  end
  return false
end

--------------------------------------------------------------------------------
-- move_box
--
-- Moves a box from (sx,sy) to (dx,dy).  Updates the box structure with the
-- new box location, and updates the number of boxes placed on targets.
--------------------------------------------------------------------------------
function move_box(sx, sy, dx, dy)
  for i=1,#g_state.bx do
    if g_state.bx[i][1]==sx and g_state.bx[i][2]==sy then
      -- If the box is currently on a target, reduce the target count by 1
      if is_target(sx,sy)==true then
        g_state.ot=g_state.ot-1
      end
      g_state.bx[i][1]=dx
      g_state.bx[i][2]=dy
      -- If the box is now on a target, increase the target count by 1
      if is_target(dx,dy)==true then
        g_state.ot=g_state.ot+1
      end
      moved=true
    end
  end
end

--------------------------------------------------------------------------------
-- process_input
--
-- Handles input.
--------------------------------------------------------------------------------
function process_input()
  -- c_x and c_y are the candidate movement location for the player based on
  -- the button they pressed
  -- b_x and b_y are the position beyond that in the same direction.  This
  -- will be used if a player pushes into a box that may or may not itself move
  -- depending on what's behind it.
  --
  -- Algorithm for movement key processing:
  --  - get the keypress
  --  - If a movement key was pressed:
  --    - set the candidate location to the adjacent spot in that direction
  --    - set the beyond location to one additional spot beyond that
  --    - If the candidate location is a wall, don't move.
  --    - If the candidate location has a box, then check the beyond space.
  --      - If the space beyond is empty, move the player and the box
  --      - If the space beyond is a wall or another box, don't move
  --    - If the candidate location is empty, move the player.
  c_x=g_state.p[1]
  c_y=g_state.p[2]
  b_x=g_state.p[1]
  b_y=g_state.p[2]
  movekey = false

  if keyp(58) then      -- Up key
    c_y=c_y-1
    b_y=c_y-1
    g_state.pd=3
    movekey=true
  elseif keyp(59) then  -- Down key
    c_y=c_y+1
    b_y=c_y+1
    g_state.pd=1
    movekey=true
  elseif keyp(60) then  -- Left key
    c_x=c_x-1
    b_x=c_x-1
    g_state.pd=2
    movekey=true
  elseif keyp(61) then  -- Right key
    c_x=c_x+1
    b_x=c_x+1
    g_state.pd=0
    movekey=true
  elseif keyp(24) then 
    level_num=level_num+1
    loadlevel(level_num)
  elseif keyp(26) then
    level_num=level_num-1
    loadlevel(level_num)
  end

  if movekey==true then    
    if is_wall(c_x,c_y)==false then
      if is_box(c_x,c_y)==true then
        if is_wall(b_x,b_y)==false and is_box(b_x,b_y)==false then
          move_box(c_x,c_y,b_x,b_y)      
          g_state.p[1]=c_x
          g_state.p[2]=c_y
          level_done()
        end
      else
        g_state.p[1]=c_x
        g_state.p[2]=c_y
      end
    end
  end
end

function level_done()
  if g_state.nt == g_state.ot then
    trace("Done!")
    return true
  end
  return false
end

function TIC()
  render_level()
  render_sprites()		
  process_input()
end

level_num=1
loadlevel(level_num)

--==============================================================================
-- Explicit globals go here
--==============================================================================

-- Contains the state for a single level (player position, box positions, etc)
g_state={}

-- Contains all of the level data.  See notes.txt for details about the format.
g_levs = {
  {9,9,30,120,"hjjjgXXXXk@  kXXXXk $$kXhjgk $ kXk.king ijf.kXmf    .kXk   b  kXk   mjjfXijjjfXXX"},
  {10,9,90,150,"hjjjjjjjjgk..      kk..$  b  kk  a$cf hfk $     kXijnje a kXXXk $ @ kXXXk     kXXXijjjjjfX"},
  {6,8,30,50,"XhjjgXhf  kXk@$ kXmg$ igmf $ kk.$  kk..*.kijjjjf"},
  {8,8,40,80,"XhjjngXXXk@ ilgXXk $  kXhlg b igk.d d  kk.$  a kk.   $ kijjjjjjf"},
  {10,7,60,150,"XhjjjjjgXXXk     ijghf$cje   kk @ $  $ kk ..b $ hfig..k   kXXijjljjjfX"},
  {11,13,180,180,"XXXXXXXhjjgXXXXXXXk@ kXXXhjjjf  khjjf      kk   .cje hok b a    iok k $ $a. kk d  *  b kk .a$ $ k kig    a d kXk cje.   kXk     hjjfXijjjjjfXXX"},
  {10,8,120,140,"XXXhjjnjjgXXhf  k @kXXk   d  kXXk$ $ $ kXXk $cg  khjf $ d hfk.....  kXijjjjjjjfX"},
  {10,7,80,90,"XXXhjjjjgXXhjf    kXhf. $ce igk..$ $  @kk.. $ $ hfijjjg   kXXXXXijjjfX"},
  {11,9,180,260,"XhjjnnjjjgXXk  if   kXXk   $   kXXk$ cje $kXXk b...b kXhf d...d igk $  $  $ kk     b @ kijjjjjljjjf"},
  {8,7,45,60,"XXhjjjjgXXk    khjf$$$ kk@ $.. kk $...hfijjg  kXXXXijjfX"},
  {12,6,45,90,"XhjjgXXhjjjghf  kXXk   kk $ ijjf$  kk  $.... $ kig    b @ hfXijjjjljjjfX"},
  {20,11,180,330,"XXXXhjjjgXXXXXXXXXXXXXXXk   kXXXXXXXXXXXXXXXk$  kXXXXXXXXXXXXXhjf  $ijgXXXXXXXXXXXk  $  $ kXXXXXXXXXhjf b hng kXXXhjjjjgk   d ilf ijjjf  ..kk $  $           ..kijjjg cjje b@hg  ..kXXXXk      mjlljjjjfXXXXijjjjjjfXXXXXXXX"},
  {8,7,50,50,"XXhjjjgXhjf  @kXk  $. igk  .$. kijg *$ kXXk   hfXXijjjfX"},
  {20,9,240,500,"hjjjjgXXXXXXXXXXXXXXk    ijgXXXXXhjjjjgXk b  $ kXXhjno  ..kXk d  $ ijjf@if  ..igk  $$$   $      ...kijg  $  $hjjjg  ..hfXXk$ $ $ kXXXk  ..kXXXk      kXXXijjjjfXXXijjjjjjfXXXXXXXXXX"},
  {10,8,90,100,"XXhjjgXXXXXXk..kXXXXXhf .igXXXXk  $.kXXXhf $  igXXk  a$$ kXXk  @   kXXijjjjjjfXX"},
  {20,13,240,1000,"XXXXXXXXXXXXXXhjjjjgXXXXXXXXXXXXXXk  ..kXXXhjjjjnjjjjjf  ..kXXXk    k  $ $   ..kXXXk $$$d$  $ b  ..kXXXk  $     $ k....kXXXk $$ b$ $ $k....khjjf  $ k     k....kk   a cjpnjjjjljjjjfk    $  ioXXXXXXXXXXk $$b$$ @kXXXXXXXXXXk   k   hfXXXXXXXXXXijjjljjjfXXXXXXXXXXX"},
  {10,9,80,160,"XXhjjjjgXXXXk    ijgXXk $    khjf $ ce kk... $   kk...$b$ coijjg d $ kXXXk  @  kXXXijjjjjf"},
  {10,9,100,150,"XXhjjjnjjgXXk   d. kXhf  $...kXk  $ b*.khf ce$d cok   $  $ kk   b    kijjjljg@ kXXXXXXijjf"},
  {9,7,75,100,"hjjjjgXXXk    kXXXk $$$igXXk  a..ijgig  ..$ kXk @    kXijjjjjjf"},
  {8,7,50,75,"hjjnjjjgk  d   kk $..$ kk@$.* cok $..$ kk  b   kijjljjjf"},
  {10,8,150,190,"XhjjjjjgXXXk.... kXXhle...$ijgk  $a$ $ kk $$  a$ kk    a   kijjg @ hjfXXXijjjfXX"},
  {16,13,210,530,"XXXXXXXhjjjjjjjgXXXXXXXk       kXXXXXXXk a a b kXXXXXXXk  $ $d kXXXXXXXk   $   kXXXXXXXig $ $a kXhjgXXXXk $ $  khf.ijjnjf cjnjjfk...  d $ $ kXXXme..     $  kXXXk...  b  @hjfXXXig.hjjo  hfXXXXXXijfXXijjfXXXXXX"},
  {7,8,70,90,"hjjjjjgk..$..kk..a..kk $$$ kk  $  kk $$$ kk  b@ kijjljjf"},
  {16,12,160,420,"XXXXXXXhjnnjjjjghjjjjjjf@if  ..kk      $     ..kk $ b$ a$hg  ..kig cf    mljg..kXk $ $he kXXijjfXk he d  kXXXXXXhf d    hfXXXXXXk  $   hfXXXXXXXk  hg$ kXXXXXXXXk  mo  kXXXXXXXXijjlljjfXXXXXXXX"},
  {8,11,80,160,"XXXhjjjgXXXk   khjjf$  kk.. $  kk..$  hfk..b $kXk .k$ igijnf $ kXXk $  kXXk  @ kXXijjjjf"},
  {17,13,240,600,"XXXXXXXXhjjjjjjgXXXXXXXXXk      kXXXXXXXXXk  $ $ kXXhjjjjjno $ $  kXhf...  ilje hg kXk....       mo kXig...  hg $$if igXijjjjnpo $    @kXXXXXXmlf cjje hfXXXXXXk $ $    kXXXXXXXk  $ hjjjfXXXXXXXig   kXXXXXXXXXXXXijjjfXXXXX"},
  {9,9,70,105,"hjjjjjjgXk      kXk a$$  kXk ...a kXig...$ igXk ce $ kXk$  $  kXk  b  @kXijjljjjf"},
  {10,8,75,120,"XXhjjjgXXXhjf   ijjgk   $ $  kk $   $ @kijg$$cjnjfXXk  ..kXXXXk....kXXXXijjjjfXX"},
  {10,12,150,220,"XXXhjjjjjgXhjf     khf   a a kk  a.$$$ kk a.*b hjfk  ..d kXXijg..$ igXXXk.b $ kXXhf d a@kXXk $  $ kXXk     hfXXijjjjjfXX"},
  {19,15,330,1200,"XXXXXhjjgXXXXXXXXXXhjjjjf  kXXXXXXXXXXk    $  mnjjnjjjjjgk ce $  if  k ....kk $ $  $    k ....kk a  $$ cng k ....kk @$$    mf k ....kijjg  b  k  ie hjjfXXXk $ijno     kXXXXXXk$ $ mljg$b kXXXXXhf a  d  d d kXXXXXk  $$$       kXXXXXk     hjjjg  kXXXXXk  hjjfXXXijjfXXXXXijjfXXXXXXXXXXXXX"},
  {14,10,210,650,"hjjjjnjjjjjgXXk..  k     ijgk..  k $  $  kk..  d$cjng  kk..    @ if  kk..  b b  $ coijnjjf ie$ $ kXXk $  $ $ $ kXXk    b     kXXijjjjljjjjjf"},
  {14,13,140,550,"XXXXXXXhjjgXXXhjjjnnjf  ijjgk   if.....  kk  $  cg...b kig  $  ine d kXk a $  d    kXk  a $  a   kXk   a $  b  kXk    a $ d hfXijjg  a $  kXXXXXig  b $ kXXXXXXig@k   kXXXXXXXijljjjfX"},
  {17,10,140,500,"XXXXXXXXhjjjjjjgXXXXXXXXXk     @kXXXXXXXXXk $a$ hfXXXXXXXXXk $  $kXXXXXXXXXXme$ $ kXXhjjjjjjno $ a ijgk....  if $  $  kme...    $  $   kk....  hjjjjjjjjfijjjjjjfXXXXXXXXX"},
  {15,9,130,450,"XXhjjjgXXXXXXXXXXk   ijjjjjjjgXXk $ $       khjljg  $ a$$  kk   d cg    hjfk...   ie  $kXXk...b$$  $  kXXk...k  @b  hfXXijjjljjjljjfXXX"},
  {12,11,130,450,"hjjjjgXXhjgXk..  kXhf@igk..  ijf   kk..     $$ kk..  b b $ kk..hjf k $ kijjo $ k$  kXXXk  $d $ kXXXk $  $  kXXXk  hg   kXXXijjlljjjf"},
  {19,11,240,900,"XXXXXXXXhjjnjjgXXXXXXXXhjjjo  d  ijjgXXXXXk   d   $    kXXhjjf a$$ he hg  kXhf      b d  if clgk  cje $k$  $  $  kk...    d cg  b   kk...b    @ d cle cok...k  hjg  $  $  kijjjljjfXig   b   kXXXXXXXXXXijjjljjjf"},
  {16,14,400,1450,"XhjjjjjgXhjjjjgXXk     mjf    kXXk  ce d  $$a igXk$ $ $ $ $    kXk $ $ b   b   khf  $$ mjjjpe.cok $    k   k...kk@a$$ co   k...kk  $   k   k...kig  b$ k   k...kXk$$d  ijjjf...kXk     $    ...kXijjjjjjjjjg   kXXXXXXXXXXXijjjf"},
  {12,15,360,1200,"hnjjjjjnnjjgmo     if  kmo   $   $ kmlje cg $$ kk   $ k    kk $$$ k cjnok   a k $ iok  b  k  $ kk $d $k    kk   ..d cnjomjje.. $ k@kk.....b $d kmg....k  $ kmpg..ho    killjjlljjjjf"},
  {14,10,130,270,"hjjgXXXXXXhjjgk..ijjjjjjf..kk*.*.....*.*.kk $ $ $ $ $ $kk$ $ $@$ $ $ kk $ $ $ $ $ $kk$ $ $ $ $ $ kk.*.*.....*.*kk..hjjjjjjg..kijjfXXXXXXijjf"},
  {14,15,420,1000,"XhjjjjjjjgXXXXXk....   dXXXXXk.a.a  $ cgXXhf....b a @igXk ....k  b  igk     d$ ie$ kig cje  $    kXk$  $ $ $b  kXk a  $ $ me kXk  cjg  ho  kXk    me if hfXk  $ d  $  kXXijg$ $   hjfXXXXk  hjjjfXXXXXXijjfXXXXXXX"},
  {15,14,240,950,"hjjjgXXXXXXhjjgk@  ijjjjjjf  kig $       $  kXk a a  hnng  kXk  $   illf$hfXk$ ce b $ $ kXhf $  $d     kXk   b      b kXk   mjjjg$clnfXijjjo   d   kXXXXXXk...  $ kXXXXXXk....b  kXXXXXXk....mjjfXXXXXXijjjjfXXXXX"},
  {19,13,540,1500,"XXXXXXXXhjjnjgXXXXXXXXXXXXXk  d mjjjjgXXhjjjgXk  $ k....kXhf   dXk  b k....kXk $ $ hf$co k....kXk  a  d   k k....kXk$ $  $@$ k ig  hfXk $a  he ho  k  kXhf   $$k  ile d  kXk  $   k $$      kXk $  $ k  hjjg  hfXk    hjljjfXXijjfXXijjjjfXXXXXXXXXXXXX"},
  {13,15,360,650,"XXXXXXhjjgXXXXXhjjjf  kXXXXhf     $kXXXhf $  he ijgXk@$ $ k $  kXinje co   $kXXk....k$ $ kXXk....d   $kXXk....  $$ igXk... b $   kXijjjjo$ $  kXXXXXXk   hnfXXXXXXk$ hlfXXXXXXXk  kXXXXXXXXXijjfXXX"},
  {17,12,240,525,"XXhjjjjjjgXXXXXXXXXk      kXXXXXXXXXk  $   ijjjgXXXXXmjjg   $   kXXXXXk  ie$b $  kXXXXXk    @d a cljjgXhf cg $ $ $$   kXk   k  b   b   khf   mjjljjjljjjfk....kXXXXXXXXXXXk....kXXXXXXXXXXXijjjjfXXXXXXXXXXX"},
  {17,13,480,1150,"XXXXXhjjjgXXXXXXXXXXXXk@  ijjjjjgXXXXhjle $  $   kXXhjf   $$ $ $  kXXk   b  $a cjjjoXXk$cjle  $   $ kXXk $  $  $   $ kXXk  $  hje$cjg ighf  ce k.....d  kk  $ $ d.....   kk $   $ .....hjjfijjjjjjg.....kXXXXXXXXXXijjjjjfXXX"},
  {18,16,420,1050,"XXhjjgXXXXXXXXXXXXXXk  mnjjnjjjgXXXXXhf  mf @d   kXXXXXk  $d $ $   mjjgXXk$  $  b $ $d  ighf  $cg k$ $     kk  a  d d   $$$  kk $    $  $he hjjfk $ $ b$a  k  kXXXig  hjf  cjf$ kXXXXk  k....     kXXXXijnf......hjjfXXXXXXk....hjjfXXXXXXXXXk...hfXXXXXXXXXXXXk...kXXXXXXXXXXXXXijjjfXXXXXXXXXX"},
  {9,12,180,250,"XhjjgXXXXXk  ijjgXXk$ @  kXhf  cg$igk *a.d  kk ..*$$ kk .a.b  kig   d coXijg $  kXXXk a  kXXXk   hfXXXijjjfX"},
  {15,12,300,750,"XhjjnjjgXXXXXXXXk  k  mjjjgXXXhf  k  k...ijgXk  $k  d...  kXk $ k$$ ...  kXk  $k  b... .kXk   d $ijjjjjlgmg$       $ $ kio  b  $$ b   kXijjljg  cf$$@kXXXXXXk      hfXXXXXXijjjjjjfX"},
  {17,13,240,850,"XXXXhjjjjjjjgXXXXXXXXk       kXXXXXXXXk$$ $$a mjjgXhjjnf  b  $ d  kXk..k  cf $  $  kXk..k $$     b  kXk..k  hg$cjjo hfXk..ie io    k kXXk...   ie cjf ijgk   hg   $      kijjjlo@b   hg a kXXXXXijljjjlo   kXXXXXXXXXXXXijjjf"},
  {20,14,240,950,"XXXXXXXXXXXhjjgXXXXXXXhjjjnjjjno@ kXXXXXhjf   k   if$ mjjjjgk  $$ k     $ d  ..kk b   k   cg$    ..kk k   k $$ k  b  ..kk k cnpg b injo ...kk k$ mlf d  kXijjjjfk d  d    b kXXXXXXXk     $   k kXXXXXXXk b  hje cf kXXXXXXXk ijjf      kXXXXXXXk      hjjjjfXXXXXXXijjjjjjfXXXXXXXXXXXX"},
  {11,10,150,350,"XXXXXhjjjjgXhjjnf.   kXk  d..ce kXk  $..   kXk  b .b cohle ie$d  kk $    $$ kk a$b  b  kk@  mjjljjfijjjfXXXXXX"},
  {15,15,240,550,"hjjjjjjjgXXXXXXk       kXXXXXXk       mjjgXXXmg hjng d  kXXXmf d@if    kXXXk $$$ $  $$kXXXk  b hg $  kXXXk  k if  $ mjjginjf  $$$ $d  kXk   ce   ....kXk a   b b.. .kXk   b d ig...kXijjjo $  k...kXXXXXig   mjjjfXXXXXXijjjfXXXX"},
  {20,16,300,850,"XhjjgXXXXXXXXXXXXXXXhf  ijgXXXXXXXXXXXXXk@$   kXXXXXXXXXXXXXine $ kXXXXXXXXXXXXXXk  cjljjjgXXXXXXXXXXk  $ ....ijjgXXXXXXXk  hne...   mjjjjgXXme mo ...b  k    igXk $if ...k ho  $  kXk    cnjno mle b$ kXk  b  d io k   d  kXijjlg    d d$ a $ kXXXXXig b     $ $  kXXXXXXijo   b$ $ $ kXXXXXXXXijjjo   b  kXXXXXXXXXXXXijjjljjf"},
  {18,15,240,750,"XXXXXXhjjjjjnjjjgXXXXXXXk     d   igXXXXXXk $      ..kXXXXXXk     b$a..kXXhjjjljjjjjf  ..kXXk      $     ..kXXk a b $ce b a..kXXk   d$    k  ..kXhf$a $ hjjjlne  khf   $  kXXXXk $ kk   $a  kXXXXk   kk  $   hfXXXXijjjfk $hjjjfXXXXXXXXXXk @kXXXXXXXXXXXXXXijjfXXXXXXXXXXXXXX"},
  {18,14,420,1300,"hjjjjjjgXXXXXXXXXXk...   ijjjjjjgXXXk....     $   igXXk.....he $ a$  kXXk.....k  b  $  kXXinjjjjf$ ig  $ ijgXk        ine $  kXk  $ b $  d  $  kXk  hjf ce  b cjnfXk  k  $  $ k   kXXinjf a$a  cf$  kXXXk@$    $   $  kXXXijjjg   hjjjjjfXXXXXXXijjjfXXXXXXX"},
  {16,15,300,850,"XXXXhjjjjgXXXXXXXXXXk    kXXXXXXXXhjf ce kXXXXXXhjf  $  $mjjjjjgk   $ $  k  ...kk b$ b  $d  ...kk k  k$     ...kk k$ k   b  ...kk k $k $$k  ...kk k@ d$  mjjjjjfk k $ $ hfXXXXXXk k  $  kXXXXXXXk ije hjfXXXXXXXk     kXXXXXXXXXijjjjjfXXXXXXXXX"},
  {15,14,420,900,"hjjgXXXXXXXXXXXk  ijgXXXXXXXXXk $  ijgXXXXXXXk $ $  ijgXXXXXk $ $ $  ijgXXXk $ $ $    kXXXk $ $  a   igXXk $  hg $$$ kXXk@ hjpf     igXig kXk.$$$$$.kXXk ijf.......igXk   .*******.kXijjg.........kXXXXijjjjjjjjjf"},
  {15,17,60,100,"XXXXXhjjnjjgXXXXXXXXk@ d  kXXXXXXXXk $   kXXXXXXXhle cg kXXXXhjjf $  k igXXXk       k  igXXk $ $hjjo $ kXXk $$ d  k  $kXXk$  $   d$  kXhf  $$b   $$ igk $$  k  b  $ kk     mjjo $  kk  a$hf..ig   kijg .d....innjfXXk .......ioXXXXk....   ..kXXXXijjjjjjjjjfXX"},
  {16,14,60,100,"XXXhjjjjnjjjgXXXXXXk..  d   kXXXXXXk..      kXXXXXXk..  b  hljgXXXhljjjjf  d  igXXk            kXXk  b  cg  b  khjle ig  mnjo cok  $  ijjlo d  kk a $  $  k $  kk @$  $   k   hfijjg ce hjljjjfXXXXk    kXXXXXXXXXXijjjjfXXXXXXX"},
  {19,15,60,100,"XXXXXXXXXXhjjgXXXXXXXXXXhjjg k  kXXXXXXXXhjf  ijf$ kXXXXXXXhf   @  $  kXXXXXXhf  $ $$ce coXXXXXXk  a$ce     kXXXXXXk a $ $$ b clgXXXXXk   $ a  d $ mjjjghpng    a  $$ d   kmllf cg $         kk.    mjg  hjjjjjjfk.. ..kXijjfXXXXXXXk...a.kXXXXXXXXXXXXk.....kXXXXXXXXXXXXijjjjjfXXXXXXXXXXXX"},
  {16,15,60,100,"XXXXXXXhjjgXXXXXXXXXXXXk  igXXXXXXXXXXXk   igXXXXXXXXXXk $$ igXXXXXXXhjf$  $ igXXXhjjo    $   kXhjf  k hjjje  kXk    d d....$ kXk a   $ ....b kXk  $ b b.*..k kXijg  mjle cno kXXXijjo @$  if$igXXXXXijg $     kXXXXXXXk  hg   kXXXXXXXijjlljjjf"},
  {18,8,60,100,"hjjjjjjjjjnnjnjjjgk         if k...kk $ $$b    $ k...kk $   d$ce$$ d...kk $$a$       @...kk $ $ $a$ cjje  .kk   hg       $...kijjjlljjjjjjjjjjjf"},
  {17,13,60,100,"XXXXXXXXhjjjnjjjgXXXXXXhjf   d   kXXXXXXk@$  $ $$ khjgXhjljng      kk.ijf   if  ce$ kk.....*.  he $  kk *cg  a$ d  $  kk   k  $  ......kig $ig  hjjjjjjjfXk $ ijnfXXXXXXXXXk $ $ kXXXXXXXXXXk     kXXXXXXXXXXijjjjjfXXXXXXXXX"},
  {20,15,60,100,"XXXXXXXXXXXhjjjgXXXXXXXXXXXXXXhf   igXXXXXXXXXXXXhf     kXXXXXXXXXXXhf  $$  kXXXXXXXXXXhf $$  $ kXXXXXXXXXXk $    $ kXXXhjjgXXXk   $$ cjljgXk  ijjjljje ce    kXk..           $$$@kXk.b hnnnnng cg   hoXk.d illlllf. k$ $ilgk........... k   $ kijjjjjjjjjjjjo  $  kXXXXXXXXXXXXXig  hjfXXXXXXXXXXXXXXijjfXX"},
  {14,13,60,100,"hjjjnnjjjjjjjgk   mo ......kk  hlf ..b.a kk $k  ..hf. .kme d $a d    kk $  $    b cok $b b $cjo$ kk@ k k $  k  kk $d ig$a d$ kk $   k      kijg   k ce$ hfXXijjjo     kXXXXXXXijjjjjfX"},
  {17,13,60,100,"hjjjjjjjjjjjjjjgXk              kXk b cjjjje     kXk k  $ $ $ $b  kXk k   $@$   me igk k a$ $ $cno...kk k   $ $  mo...kk ije$$$ $ mo...kk     a hg mo...kijjjg   mf if...kXXXXijjjo     hjfXXXXXXXXk     kXXXXXXXXXXijjjjjfXX"},
  {18,16,60,100,"XXXXXXXhjjjjjgXXXXXhjjjjjo     kXXXXXk     d $@$ kXXXXXk$$ b   cjjnpjjjgXk cjf......mo   kXk   $......if a kXk cjg......     khf   ijjg cje b$hfk  a$   d  $  k kXk  $ $$$  b $co kXk   $ $ cjf$$ k kXijjjg     $   k kXXXXXijg cje   d kXXXXXXXk     b   kXXXXXXXijjjjjlg  kXXXXXXXXXXXXXXijjfX"},
  {20,13,60,100,"XXXXXXXhjjgXXXXXXXXXhjjjjjjf  mjjjgXXXXXk         d   kXXXXXk    a ce  a  ijjgXXig  a     b      ijgXk   ce   d $$$a   kXk         b   $ $ kXk  b  a a k$a @a hfXinjf  $ $ d   $  kXXXk $ cjjje cje $hfXXXk  ........... kXXXXijg  hjjjjjg  hfXXXXXXijjfXXXXXijjfXXX"},
  {11,10,60,100,"XXXhjjjgXXXXhjf   ijgXhf @ $ $ kXk  cg ce igk $.k.$   kk a.d*a   kk $...  hjfijg$a hjfXXXXk   kXXXXXXijjjfXXXX"},
  {19,16,60,100,"XhjjjjgXXXXhjjgXXXXXk    ijjjjf  kXXXXXk@b $        igXXXhljle$ $ hjje  igXXk    $   k      igXk  $$ a cf$cne$$ kXk     $*.*..k    kXijjjjjg....*k $  kXXXXXXXk*..*.d a$coXXXXXXXk....* $   kXXXXXXXk.....b $$$kXXXXXXXijjjg k a  igXXXXXXXXXXk d $ $ kXXXXXXXXXXk  $    kXXXXXXXXXXk  hjg  kXXXXXXXXXXijjfXijjf"},
  {19,17,60,100,"XXXXXXhjjjgXXXXXXXXXXXXXhf   igXXXXXXXXXXXhf  *  igXXXXXXXXXhf  * *  igXXXXXXXhf  * * *  igXXXXXhf  * * * *  injgXhf  * * * * *  d igk  * * * * * *    kk * * * . * * *@$ kk  * * * * * *    kig  * * * * *  b hfXig  * * * *  hljfXXXig  * * *  hfXXXXXXXig  * *  hfXXXXXXXXXig  *  hfXXXXXXXXXXXig   hfXXXXXXXXXXXXXijjjfXXXXXXXX"},
  {10,9,60,100,"XhjjgXXXXXXk  mnjjgXhf$ if  kXk  $@$  kXk   hg$ kXine.if clgXk...$ $ kXig..    kXXijjjjjjf"},
  {14,15,60,100,"hjjjgXXXXXXXXXk   igXXXXXXXXk    kXXhjjgXXk $  ijjf  kXXk  $$ $   $kXXine@ b$    igXXk  cf  $ $ igXk $  hg ce .kXk  a$if$  b.kXine   $..cf.kXXk    b.*...kXXk $$ k.....kXXk  hjljjjjjfXXk  kXXXXXXXXXXijjfXXXXXXXX"},
  {16,14,60,100,"hjjjgXhjjgXXXXXXk...kXk  ijjgXXXk...ino  $  kXXXk....io $  $ijgXmg....ig   $  kXmlg... ig $ $ kXk ig    k  $  kXk  ig b ije cjlgk $ d d$  $    kk  $ @ $    $  kk   b $ $$ $ hjfk  hljjjg  hjfXXk hfXXXXijjfXXXXijfXXXXXXXXXXXXX"},
  {11,11,60,100,"XXXXXXhjjgXhjjjjjf @kXk     $  kXk   $ce $kXig$a...a kXXk $...  kXXk a. .b igXk   a d$ kXk$  $    kXk  hjjjjjfXijjfXXXXXX"},
  {20,13,60,100,"XXXXhjjjnnjjgXXXXXXXXXhjf   io  mjjjgXXXhjf      k  k   ijjgk  $$ b$ k  k  ... kk a  $k@$ig d a.a. kk  he d$  k    ... kk $d    $ k a a.a. kk    he  hf$ $ ... kk $ cf   d  a$a.a. kig $$  $   $  $... kXk$  hjjjjg    hg  kXk   kXXXXijjjjlljjfXijjjfXXXXXXXXXXXXXX"},
  {9,12,60,100,"hjjgXhjjgk  ijf  kk    $  kk  b b  kme k k$cok  d.d  kk  *.* @kk  b.a hfijjo   kXXXXk a$kXXXXk   kXXXXijjjfX"},
  {17,17,60,100,"XXXXXXXhjjgXXXXXXXXXXhjjo  kXXXXXXXXXhf  d  kXXXXXXXXXk  $ $ kXXXXXXXhjf a$   ijjgXXXXk  $  ce$   kXXXXk  b @ $ a $kXXXXk  k      $ ijjgXme mjje$cg     kXk $d.....d b   kXk  $...*. $d hjfhf  b.....b   kXXk   ijg cnljjjfXXk $$  d  kXXXXXXXk  b     kXXXXXXXijjljg   kXXXXXXXXXXXXijjjfXXXXXXX"},
  {12,12,60,100,"XXXXXXXhjjjgXXhjjjjf   khjf    . $ kk $  a$.b$cok  b  @.d  kig ijjg.   kXk $  k*cjnfXk ce d.  kXXk     .a kXXijg$     kXXXXk  hjjjfXXXXijjfXXXXX"},
  {19,15,60,100,"XhjjjgXXXXXXXXXXXXXXk   kXXXXXXXXXXXXXXk a ijjjjgXXXXXXXXXk      $@mnjjjgXXXXk $ hg$ clf   kXXXXk hnpo $    $ kXXXXk ipppg b  a$ ijjghf  mllf ig$      kk  $d  $  k he cg kk         k d...d kijjjjg  hjo  ...  kXXXXXijjfXk b...b kXXXXXXXXXXk ije d kXXXXXXXXXXk       kXXXXXXXXXXijjjjjjjf"},
  {13,10,60,100,"hjjjjgXXhjjjgk    ijjf   kk $   $   a kig  a hng $ kXk$$  ilf$a khf   a  ... kk  b $  $...kk  mjjjg..hjfk @kXXXijjfXXijjfXXXXXXXXX"},
  {20,14,60,100,"XXXXXXXhjjgXhjjgXXXXXXXXXhjf  kXk  kXXXXXXhjjf  $ ijf $kXXXXXXk $   $      kXXXXhjf  ce $  $  $kXXXXk       a $ ce kXXXXk a$$$$a $$ $  kXXXXk    $ $$ cnne ijjjginje    $ @mo .....kXk  $$he cjpo ....hoXk $  d....mo ..hjlfXk b  $....mljjjfXXXXijlg  ....kXXXXXXXXXXXXijjjjjjfXXXXXXXX"},
  {10,10,60,100,"hjjjnnjjgXk   if  kXk a $ $ kXk  *.a  kXmg b.@.hoXmf$ije*ilgk        kk   hg a kijjjlo   kXXXXXijjjf"},
  {12,15,60,100,"hjjjjjgXXXXXk ....kXXXXXk ....kXXXXXk ....kXXXXXme$cjjljjjjgk $ $      kk   b $$ $ kijg k   a$ kXXk k $$   kXXk k a $$ kXXk k  $ hjfXXk ije  kXXXXk    a@kXXXXijjg   kXXXXXXXijjjfXX"},
  {20,9,60,100,"XXhjjjjjjjnnjjjnjjjgXXk       mo...d   kXXk a$a$a ile... $ kXXk  @$  $   ..a $ khjlje$a$b b  ..  hnfk   $ $ k ijjjje ioXk a a a k         kXk       mjjjjjg   kXijjjjjjjfXXXXXijjjfX"},
  {9,12,60,100,"XhjjgXXXXXk  kXXXXXk$ ijgXXXk   @kXXhf b. ijgk  d*.$ kk $$..a kig ce.  kXk $  hjfXk  hjfXXXk  kXXXXXijjfXXXX"},
  {18,13,60,100,"XXXXXhjjjjjjjgXXXXXXXXXk    ...kXXXXXXXXXk b  ...kXXXXXXXXXk ie  ..kXXXXhjjjjf $ $ hjfXXXXk...$ $ $@hoXXXXXXk..a $ $ $iljjjjjgk...a $ $        kk... $ $  a$a$he kk  hjjg $ $ $ d  kk  kXXk  $   $   kijjfXXig   hjjjjjfXXXXXXXijjjfXXXXXX"},
  {11,10,60,100,"XhjjjgXXXXXXk @ ijjjjgXk a..*   kXk ...a   khf$cg $ $ kk   d$cjnjfk   $   kXXijjjg a kXXXXXXk   kXXXXXXijjjfXX"},
  {14,13,60,100,"XXXXXhjjjjgXXXXXXhjf    igXXXXXk   ce  kXXXhjf$ce  b kXXhf     ..k kXXk  $a$b*.k kXXk $$@ k.*k ijgk  $$ k..d   kig    k..$   kXijg$co. a hjfXXXk  ije  kXXXXXig     hfXXXXXXijjjjjfXXX"},
  {20,16,60,100,"hjjjnjjjjnjgXXhjjjjgk   d    d@ijjf....kk   $$b       .....kk   b mng   ce ....kig cf ilf  b   ....kXk $ $     k ce cjjoXk  $ $cg  k       khljg b  ijno hg ce kk  d d$   mo mo    kk $  $  a io mljjjjfk a $ $    k kXXXXXXk  $ ce ce d kXXXXXXk $$     $$  kXXXXXXig ce hjg $  kXXXXXXXk    kXk    kXXXXXXXijjjjfXijjjjfXXXXXX"},
  {14,16,60,100,"hjjjjjjjjgXXXXk        mjjgXk hjjjje d  igk d $ $ $  $ kk       b$   kijg$  $$k  hnfXXk  he d $ioXXXig$d   $ @kXXXXk  $ $ cjoXXXXk b   $  kXXXXk ig   b kXXXhf  ijjjf kXXXk         kXXXk.......hjfXXXk.......kXXXXXijjjjjjjfXXX"},
  {17,16,60,100,"XXXXhjjjjjjjjjjgXXXXXk          igXXXXk  b b$$ $  kXXXXk$ k$k  cg @kXXXhf cf k $ k hfXXXk   $ d$  k kXXXXk   a $   k kXXXXme $ $   cf kXXXXk  a  he  $ kXXXXk    cf $$a kXhjjljg$$   b   kXk....d  hjjljjjfXk.a... coXXXXXXXXk....   kXXXXXXXXk....   kXXXXXXXXijjjjjjjfXXXXXXXX"},
  {18,11,60,100,"XXXXXXXXXhjjgXXXXXXhjjjjjjjf  igXXXXhf  $      $ mjjjgk   ce ce   ho...kk b$$ $ $$b$if...kk d    @  d   ...kk  $a cje$$   ...kk $  $$  $ hg....kijg$       mljjjjfXXk  hjjjjjfXXXXXXXXijjfXXXXXXXXXXXX"},
  {13,12,60,100,"hjjjjjjjjjjjgk  $ $ $.*..kk $ $ $ *...kk  $ $ $.*..kk $ $ $ *...kk  $ $ $.*..kk $ $ $ *...kk  $ $ $.*..kk $ $ $ *...kk  $ $ $.*..kk@$ $ $ *...kijjjjjjjjjjjf"},
  {20,14,60,100,"XXXXXXXXhjjjnjjjjjgXXXXXXXXXk   d     kXXhjjjgXXk     $ $ kXXk   mnjle $hg a coXXk $ if   b mo $  kXXk $  @$$ k mo$$$ kXXmg hje   k mo    kXXmo k   cjf ipjje$kXhlf k     $  k....kXk   ije cg $ k....igk $$   $ k   k.. . kk   hg $ k  ho.... kijjjlo   mjjllg...hfXXXXXijjjfXXXXijjjfX"},
  {19,16,60,100,"XXXXXXhjjjjjjnjjjgXXXXXXhf..    d   kXXXXXhf..* $    $ kXXXXhf..*.a a a$ coXXXXk..*.a b a $  kXhjjo...a  d    a kXk  ie a          kXk @$ $ cje  b a hfXk $   $   b k   kXXijg$$   a k k b kXXXXk   $   k d ijljgXXk $a hjjlg      kXXk$   kXXXk   a  kXXk  hjfXXXig     kXXk  kXXXXXXk    hfXXijjfXXXXXXijjjjfX"},
  {19,13,60,100,"hjjjgXXXXXXXXXXXXXXk   igXXXXXXXXXXXXXk $  mjjjjjjjgXXXXXmg b d       injjjgmf k   $a$a@  d   kk  k      $ b   $ kk  mne cjjjjljjg hok  mo ..*..... k mome mo *.*..*.* k iok $iljjjjjjje cf$ kk  $   $  $    $  kk  b   b   b   b  kijjljjjljjjljjjljjf"},
  {12,13,60,100,"XhjjgXXXXXXXXk  ijjjjgXXXk     $@kXXhf he.cg$kXXk  d . k ijgk   *..d   kmg b . $ a kmf mg.b  $ kk  if.k cnjfk $$ $d  kXXk  b     kXXijjljjg  kXXXXXXXXijjfXX"},
  {11,9,60,100,"XhjjjnjjjgXXk   d   kXXk $$$$$ kXhf $ $ $ kXk $  @   kXk $ cjje igk  a..... kig  ..... kXijjjjjjjjf"},
  {14,16,60,100,"XXXXXXhjgXXXXXXhjjjjf@ijjjgXXk..........kXhf.********.igk..*......*..kk..*.****.*..kinjjje..cjjjnfXk          kXXk $ $$$$ $ kXXk$$$    $$$kXXk   $$$$   kXXk$ $    $ $kXhf   $$$$   igk $$$    $$$ kk     b      kijjjjjljjjjjjf"},
  {10,6,60,100,"hjjjjjjjgXk $ ..  kXk@$$.. $igk $ .. $ kijjjjg   kXXXXXijjjf"},
}

-- <TILES>
-- 002:bbbbbbbbbbbbbbbbbb0bb0bbbbb00bbbbbb00bbbbb0bb0bbbbbbbbbbbbbbbbbb
-- 003:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 004:2020202002020202202020200202020220202020020202022020202002020202
-- 005:0220022020022002200220020220022002200220200220022002200202200220
-- 006:6666666666666666666666666666666666666666666666666666666666666666
-- 016:333333333aaaaaa33a7777a33a7777a33a7777a33a7777a33aaaaaa333333333
-- 017:333333333aaaaaa33a7777a33a7777a33a7777a33a7777a33a7777a33a7777a3
-- 018:333333333aaaaaaa3a7777773a7777773a7777773a7777773aaaaaaa33333333
-- 019:3a7777a33a7777a33a7777a33a7777a33a7777a33a7777a33aaaaaa333333333
-- 020:33333333aaaaaaa3777777a3777777a3777777a3777777a3aaaaaaa333333333
-- 021:3a7777a3aa7777a3777777a3777777a3777777a3777777a3aaaaaaa333333333
-- 022:33333333aaaaaaa3777777a3777777a3777777a3777777a3aa7777a33a7777a3
-- 023:333333333aaaaaaa3a7777773a7777773a7777773a7777773a7777aa3a7777a3
-- 024:3a7777a33a7777aa3a7777773a7777773a7777773a7777773aaaaaaa33333333
-- 025:33333333aaaaaaaa77777777777777777777777777777777aaaaaaaa33333333
-- 026:3a7777a33a7777a33a7777a33a7777a33a7777a33a7777a33a7777a33a7777a3
-- 027:3a7777a3aa7777aa77777777777777777777777777777777aaaaaaaa33333333
-- 028:3a7777a33a7777aa3a7777773a7777773a7777773a7777773a7777aa3a7777a3
-- 029:33333333aaaaaaaa77777777777777777777777777777777aa7777aa3a7777a3
-- 030:3a7777a3aa7777a3777777a3777777a3777777a3777777a3aa7777a33a7777a3
-- 031:3a7777a3aa7777aa77777777777777777777777777777777aa7777aa3a7777a3
-- 032:0055555505bbbbbb5bbbbbbb5bbb55555bb500005bb500005bb500005bb50000
-- 033:5bb500005bb500005bb500005bb500005bb500005bb500005bb500005bb50000
-- 034:5bb500005bb500005bb500005bb500005bbb55555bbbbbbb05bbbbbb00555555
-- 035:55555500bbbbbb50bbbbbbb55555bbb500005bb500005bb500005bb500005bb5
-- 036:00005bb500005bb500005bb500005bb500005bb500005bb500005bb500005bb5
-- 037:00005bb500005bb500005bb500005bb55555bbb5bbbbbbb5bbbbbb5055555500
-- 038:55555555bbbbbbbbbbbbbbbb5555555500000000000000000000000000000000
-- 039:0000000000000000000000000000000055555555bbbbbbbbbbbbbbbb55555555
-- </TILES>

-- <SPRITES>
-- 000:011111101494494119c99c91149449411494494119c99c911494494101111110
-- 001:000cc000000cc00000444400044444f0044444f000444400000cc000000cc000
-- 002:000000000004400000444400cc4444cccc4444cc00444400000ff00000000000
-- 003:000cc000000cc000004444000f4444400f44444000444400000cc000000cc000
-- 004:00000000000ff00000444400cc4444cccc4444cc004444000004400000000000
-- </SPRITES>

-- <MAP>
-- 000:606060606060606060606060606060606060606002626262626262626232000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:606060606060606060606060606060606060606012000000000000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:606060606060606060606060606060606060606012000000000000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:606060606060606060606060606060606060606012000000000000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:606060606060606060606060606060606060606012000000000000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:606060606060606060606060606060606060606012000000000000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:606060606060606060606060606060606060606012000000000000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:606060606060606060606060606060606060606012000000000000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:606060606060606060606060606060606060606012000000000000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:606060606060606060606060606060606060606012000000000000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:606060606060606060606060606060606060606012000000000000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:606060606060606060606060606060606060606012000000000000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:606060606060606060606060606060606060606012000000000000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:606060606060606060606060606060606060606012000000000000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:606060606060606060606060606060606060606012000000000000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:606060606060606060606060606060606060606012000000000000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:606060606060606060606060606060606060606022727272727272727252000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <PALETTE>
-- 000:140c1c44243430346d4e4a4e854c30346524d04648757161597dced27d2c8595a16dae2cd2aa996dc2cadad45edeeeda
-- </PALETTE>

