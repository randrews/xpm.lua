# xpm.lua

### Ross Andrews ( ross.andrews@gmail.com )

----------------------------------------------------------------------

### Purpose:

This makes an easy way to manipulate image data in Lua. The Gimp can
export XPM files, the format is fairly trivial to parse, so this makes
it easy to write quick scripts to (for example) convert image data into
declarations to embed into other programs, or something.

----------------------------------------------------------------------

### Usage:

- To create a new XPM object (which also parses the file): `img = Xpm.new('filename.xpm')`

- To read pixel data from the bitmap: `img.pixels[row][column]` or `img:xy(xCoord, yCoord)`

The first method (array subscripts) puts the Y coordinate first and uses 1-based indices.
The second method puts the X coordinate first and uses 0-based indices. Either is fine,
use whichever one fits your use case (are you talking to Lua or something else?)
