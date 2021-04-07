# convert_levels.py
#
# Takes the level file from Move-it, Main! and converts it into a format
# suitable for the TIC-80 version
#
# It's ugly.  It's only meant to be used once.
import sys, os

# Takes the level file contents and outputs an array with each level.  
# The entries in this array are arrays.  The first element is an array with the
# level's metadata, and the second element is an array of arrays containing
# the level data itself
def extract_levels(file):
  levels = []
  num_levels = int(file.readline().strip())
  for _ in range(num_levels):
    # level_data - all the level data
    level_data = []
    # level_array - the actual level grid
    level_array = []

    _ = file.readline()     # throw the line away
    
    (width, height, target_time, target_moves) = file.readline().strip().split(' ')

    # Collect the metadata
    width = int(width)
    height = int(height)
    target_time = int(target_time)
    target_moves = int(target_moves)
    level_data.append([width, height, target_time, target_moves])

    # Collect each row
    for _ in range(height):
      row = file.readline().strip()
      row_data = []
      # Collect each column for this row
      for r in range(len(row)):
        row_data.append(row[r])
      level_array.append(row_data)

    # Append the grid data to the level data
    level_data.append(level_array)
    # Append the level data to the list of levels
    levels.append(level_data)
  return levels

def find_adjacent_walls(level, i, j):
  metadata = level[0]
  wall_data = level[1]

  # The ordering used is up, down, left, right.
  openings = [False, False, False, False]
  if j > 0 and wall_data[i][j-1] == '#':
    openings[2] = True
  if j < (metadata[0]-1) and wall_data[i][j+1] == '#':
    openings[3] = True
  if i > 0 and wall_data[i-1][j] == '#':
    openings[0] = True
  if i < (metadata[1]-1) and wall_data[i+1][j] == '#':
    openings[1] = True

  return openings

# Takes a single level (the array that contains the metadata and level data),
# processes the level data line by line, replacing wall tiles with the
# appropriate tile value, based on the surrounding wall tiles.  
# Returns a Lua table that contains a suitably formatted level entry.
def process_level(level):
  metadata = level[0]
  wall_data = level[1]

  # Omit levels that are too big.
  if metadata[0] > 20 or metadata[1] > 17:
    return ''

  level_string = '{' + str(metadata[0]) + ',' + str(metadata[1]) + ',' + str(metadata[2]) + ',' + str(metadata[3]) + ',"'

  for i in range(metadata[1]):
    for j in range(metadata[0]):
      char_to_print = wall_data[i][j]
      if wall_data[i][j] == '#':
        openings = find_adjacent_walls(level, i, j)
        if openings == [False, False, False, False]:
          char_to_print = 'a'
        if openings == [False, True, False, False]:
          char_to_print = 'b'
        if openings == [False, False, False, True]:
          char_to_print = 'c'
        if openings == [True, False, False, False]:
          char_to_print = 'd'
        if openings == [False, False, True, False]:
          char_to_print = 'e'
        if openings == [True, False, True, False]:
          char_to_print = 'f'
        if openings == [False, True, True, False]:
          char_to_print = 'g'
        if openings == [False, True, False, True]:
          char_to_print = 'h'
        if openings == [True, False, False, True]:
          char_to_print = 'i'
        if openings == [False, False, True, True]:
          char_to_print = 'j'
        if openings == [True, True, False, False]:
          char_to_print = 'k'
        if openings == [True, False, True, True]:
          char_to_print = 'l'
        if openings == [True, True, False, True]:
          char_to_print = 'm'
        if openings == [False, True, True, True]:
          char_to_print = 'n'
        if openings == [True, True, True, False]:
          char_to_print = 'o'
        if openings == [True, True, True, True]:
          char_to_print = 'p'
      level_string += char_to_print
  
  level_string += '"}'
  return level_string

def main():
  if len(sys.argv) < 3:
    print('Usage: convert_levels.py <input_file> <output_file>')
    sys.exit(1)

  input_file=sys.argv[1]
  output_file=sys.argv[2]
  processed_levels = []

  try:
    infile = open(input_file)
  except OSError:
    print('Unable to open source file!')
    sys.exit(1)

  level_data = extract_levels(infile)
  infile.close()

  for level in level_data:
    result = process_level(level)
    if result != '':
      processed_levels.append(result)

  try:
    outfile = open(output_file, 'w')
  except OSError:
    print('Unable to open output file!')
    sys.exit(1)

  outfile.write('{\n')
  for level in processed_levels:
    outfile.write('  ')
    outfile.write(level)
    outfile.write(',\n')
  outfile.write('}')
  outfile.close()

if __name__ == "__main__":
    main()