#!/usr/bin/env python
import sys
import os
import argparse

import mapnik

# Set up projections
# spherical mercator (most common target map projection of osm data imported with osm2pgsql)
merc = mapnik.Projection('+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs +over')

# long/lat in degrees, aka ESPG:4326 and "WGS 84" 
longlat = mapnik.Projection('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs')
# can also be constructed as:
#longlat = mapnik.Projection('+init=epsg:4326')

def parser():
  parser = argparse.ArgumentParser()
  aa = parser.add_argument
  aa('--bbox', nargs=4, default=[110.5, -39.6, 158.2, -10.3], type=float,
     help="Bounding box, in degrees, W,S,E,N order")
  aa('--map', default='osm.xml')
  aa('--output', '-o', default='/output/image.png')
  aa('--size', nargs=2, default=[5000, 5000], help="Size in pixels (w x h)")
  return parser

def main(args=None):
  args = parser().parse_args(args)

  m = mapnik.Map(args.size[0],args.size[0])
  mapnik.load_map(m,args.map)

  m.srs = merc.params()
  # ensure the target map projection is mercator

  if hasattr(mapnik,'Box2d'):
    bbox = mapnik.Box2d(*args.bbox)
  else:
    bbox = mapnik.Envelope(*args.bbox)

  # Our bounds above are in long/lat, but our map
  # is in spherical mercator, so we need to transform
  # the bounding box to mercator to properly position
  # the Map when we call `zoom_to_box()`
  transform = mapnik.ProjTransform(longlat,merc)
  merc_bbox = transform.forward(bbox)

  # Mapnik internally will fix the aspect ratio of the bounding box
  # to match the aspect ratio of the target image width and height
  # This behavior is controlled by setting the `m.aspect_fix_mode`
  # and defaults to GROW_BBOX, but you can also change it to alter
  # the target image size by setting aspect_fix_mode to GROW_CANVAS
  #m.aspect_fix_mode = mapnik.GROW_CANVAS
  # Note: aspect_fix_mode is only available in Mapnik >= 0.6.0
  m.zoom_to_box(merc_bbox)

  # render the map to an image
  im = mapnik.Image(args.size[0], args.size[1])
  mapnik.render(m, im)
  im.save(args.output,'png')
    
  # Note: instead of creating an image, rendering to it, and then 
  # saving, we can also do this in one step like:
  # mapnik.render_to_file(m, map_uri,'png')
  
  # And in Mapnik >= 0.7.0 you can also use `render_to_file()` to output
  # to Cairo supported formats if you have Mapnik built with Cairo support
  # For example, to render to pdf or svg do:
  # mapnik.render_to_file(m, "image.pdf")
  #mapnik.render_to_file(m, "image.svg")

if __name__ == "__main__":
  main()
