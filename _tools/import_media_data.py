# import_media_data.py
#
# Given a source and destination TIC-80 Lua script, takes the graphics and
# sound data (everything from <TILES> forward) from the source file and
# uses it to replace the data in the destination file.  
import sys, os

if len(sys.argv) < 3:
    print('Usage: import_media_data.py <input_script> <output_script>')
    sys.exit(1)

input_file=sys.argv[1]
output_file=sys.argv[2]

try:
  sourcefile = open(input_file)
except OSError:
  print('Unable to open source file!')
  sys.exit(1)
in_lines = sourcefile.readlines()
sourcefile.close()

try:
  destfile = open(output_file)
except OSError:
  print('Unable to open destination file!')
  sys.exit(1)
dest_lines = destfile.readlines()
destfile.close()

out_lines = []

# Copy all of the lines from the destination until we get to the media part,
# then stop copying
copy_line = True
for line in dest_lines:
  if line.startswith('-- <TILES>'):
    copy_line = False
  if copy_line == True:
    out_lines.append(line)

# Iterate through the source file until we get to the media part, then start
# copying
copy_line = False
for line in in_lines:
  if line.startswith('-- <TILES>'):
    copy_line = True
  if copy_line == True:
    out_lines.append(line)

# Now save the output to the destination file
try:
  outfile = open(output_file, 'w')
except OSError:
  print('Unable to open destination file!')
  sys.exit(1)
outfile.writelines(out_lines)
outfile.close()
