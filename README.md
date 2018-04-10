# MapPrint

[![Gem Version](https://badge.fury.io/rb/map_print.svg)](https://badge.fury.io/rb/map_print)
[![Build Status](https://travis-ci.org/afast/map_print.svg)](https://travis-ci.org/afast/map_print)
[![Code Climate](https://codeclimate.com/github/afast/map_print/badges/gpa.svg)](https://codeclimate.com/github/afast/map_print)
[![Test Coverage](https://codeclimate.com/github/afast/map_print/badges/coverage.svg)](https://codeclimate.com/github/afast/map_print/coverage)

MapPrint allows for exporting many map sources and GeoJSON to a pdf file. Allowing to specify map element, text/image elements as well as printing a legend with the reference and a scale bar.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'map_print'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install map_print

## Usage

### Executable 

`map_print print --south-west="-35.026862,-58.425003" --north-east="-29.980172,-52.959305" --width=500 --height=800 --zoom="10" --output="output.png"`

Indicating southwest and northeast to determine the bounding box. Set the zoom at which the tiles should be requested.

In addition set the `output` path to which the resulting image will be written.

This is intended to be more of a testing method as it doesn't support all the options available and always returns a png. In the future we might provide more functionality depending on feature request.

### In ruby code

The most common usage will be creating a new instance with the map configuration and then call `print` with the output path. MapPrint will take the map configuration, generate the map and write the output to the output path. In the example below `./map.png`.

```ruby
MapPrint::Core.new(map_configuration).print('./map.png')
```

`map_configuration` is a hash which contains all the necessary fields to print a map.
For detailed information about what `map_print` expects in a hash please look at the [wiki](https://github.com/afast/map_print/wiki).

The minimum hash to generate a PNG:

```ruby
map_configuration = {
  png_options: {
    width: 800,
    height: 1000
  },
  map: {
    sw: {
      lat: -35.026862,
      lng: -58.425003
    },
    ne: {
      lat: -29.980172,
      lng: -52.959305
    },
    zoom: 9,
    layers: [{type: 'osm'}]
  }
}
```

The minimum hash to generate a PDF:

```ruby
map_configuration = {
  format: 'pdf',
  map: {
    sw: {
      lat: -35.026862,
      lng: -58.425003
    },
    ne: {
      lat: -29.980172,
      lng: -52.959305
    },
    zoom: 9,
    layers: [{type: 'osm'}]
  }
}
```

A full example showing all the available options:

```ruby
map_configuration = {
    format: 'pdf', # pdf or png
    pdf_options: {
      page_size: 'A4', # A0-10, B0-10, C0-10
      page_layout: :portrait # :portrait, :landscape
    },
    png_options: {
      width: 800,
      height: 1000,
      background_color: '#ffffff'
    },
    map: {
      sw: { # required
        lat: -35.026862,
        lng: -58.425003
      },
      ne: { # required
        lat: -29.980172,
        lng: -52.959305
      },
      zoom: 9, # whatever is supported by the source, typically between 1-15
      position: { # x,y position on the PDF (as prawn determines it)
        x: 50,
        y: 50
      },
      size: { # Resize the map image, typically used to print the map on pdf
        width: 500,
        height: 800
      },
      layers: [{ # Whatever layers you want to include. Currently only OSM and Bing are supported
        type: 'osm', # (osm, bing) to understand variable substitution and stitching toghether the final image
        urls: ['http://a.tile.thunderforest.com/transport/${z}/${x}/${y}.png'], # currently only one is being used, in the future it will load balance
        level: 1, # used to order the layer appearance
        opacity: 1.0 # in case you want the layer to have some transparency
      }], # see GeoJSON specification for feature/object support. See http://leafletjs.com/reference.html#path-options for formatting options, the following attributes under properties are supported: `stroke, color, weight, opacity, fill, fillColor, fillOpacity, fillRule, dashArray, lineCap, lineJoin`
      geojson: '{
        "type": "FeatureCollection",
        "features": [{
          "type":"Feature",
          "geometry":{"type":"Point", "coordinates":[-55.425003,-32.026862]},
          "properties":{"image": "./marker.png"}
        }, {
          "type": "Feature",
          "geometry": {"type": "LineString", "coordinates": [ [-55.425003,-32.026862], [-55.425003,-31.026862], [-54.425003,-31.026862], [-54.425003,-32.026862] ] },
          "properties": {"color": "#000000"}
        }, {
          "type": "Feature",
          "geometry": {"type": "Polygon", "coordinates": [ [-55.825003,-32.126862], [-55.225003,-31.426862], [-54.825003,-31.326862], [-54.835003,-32.146862] ] },
          "properties": {
            "stroke": true,
            "color": "#000000",
            "weight": 2,
            "opacity": 1,
            "fill": true,
            "fillColor": "#ffffff",
            "fillOpacity": 1,
            "fillRule": "evenodd",
            "dashArray": "5,2,3",
            "lineCap": "round",
            "lineJoin": "round"
          }
        }]
      }'
    },
    images: [
      {
        path: './file.png',
        position: {x: 50, y: 50 },
        options: {
          fit: {
            width: 25,
            height: 25
          }
        }
      }
    ],
    texts: [
      {
        text: "some text",
        position: {x: 50, y: 50 },
        box_size: {width: 50, height: 50},
        options: {
          fill_color: '#ffffff',
          color: '#000000',
          font: 'Arial',
          pointsize: '16',
          gravity: 'NorthWest',
        }
      }
    ],
    legend: {
      position: {x: 50, y: 50},
      size: {width: 50, height: 50},
      image_size: {width: 16, height: 16},
      textbox_size: {width: 40, height: 16},
      textbox_style: {
        fill_color: '#ffffff',
        color: '#000000',
        font: 'Arial',
        pointsize: '16',
        gravity: 'NorthWest',
      },
      orientation: 'horizontal', # horizontal, vertical
      overflow: 'hidden', # expand, hidden, compact
      columns: 5,
      rows: 5,
      elements: [{
        image: './file.png',
        text: 'text'
      }]
    },
    scalebar: {
      unit: 'meters', # meters, km, miles, feet
      position: {x: 500, y: 550},
      size: {width: 200, height: 40},
      padding: {top: 5, right: 5, bottom: 5, left: 5},
      bar_height: 10,
      background_color: 'black',
      background_opacity: 0.4,
      text_style: {
        fill_color: '#ffffff',
        color: '#000000',
        font: 'Arial',
        pointsize: '16',
        gravity: 'NorthWest'
      }
    }
  }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/afast/map_print.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
