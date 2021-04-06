# strip_comments.py
#
# A script that takes a TIC-80 Lua file and strips all of the comments from
# it, other than the required header lines and data.  This allows the original 
# source to be fully annotated while removing the excess characters from the 
# version that gets sent to the TIC-80 cart directory.
import sys, os

if len(sys.argv) < 3:
    print('Usage: strip_comments.py <input_script> <output_script>')
    sys.exit(1)

input_file=sys.argv[1]
output_file=sys.argv[2]
do_strip = True

try:
  infile = open(input_file)
except OSError:
  print('Unable to open source file!')
  sys.exit(1)

lines = infile.readlines()
infile.close()

outlines = []

for line in lines:
  # do a little bit of end of line whitespace stripping
  line.rstrip()

  # Check for the key header lines and pass them through.
  if line.startswith('-- title:') or line.startswith('-- author:') or line.startswith('-- desc:') or line.startswith('-- script:'):
    outlines.append(line)

  # Check for a complete comment line (which may have leading whitespace)
  if line.lstrip().startswith('--'):    
    if do_strip == False:
      # If we're allowing comments through, do it
      outlines.append(line)
    if line.startswith('-- <TILES>'):
      # If we run into the first line of the media data, stop stripping further.
      # Note that this line needs to be written to the file too.
      do_strip = False
      outlines.append(line)
    # Do nothing if neither of the above are true.
  else:
    # Check for any inline comments in the line and remove them
    # Rather than use find, we use rpartition so we can get the last instance
    # of '--' and strip everything including and past it.  This is to catch
    # any stray '--'s there might be in a trace command on a line with 
    # an inline comment.
    (pre, sep, post) = line.rpartition('--')
    if pre == '' and sep == '':
      line = post
    else:
      line = pre + '\n'
    # Take the resulting line and put it in the file.
    outlines.append(line)

try:
  outfile=open(output_file, 'w')
  outfile.writelines(outlines)
  outfile.close()  
except OSError:
  print('Unable to open output file!')
  outfile.close()
  sys.exit(1)
