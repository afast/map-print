require 'test_helper'

class CoreTest < Minitest::Test
  DEBUG = true
  BASIC_MAP = {
    format: 'pdf',
    pdf_options: {
      page_size: 'A4', # A0-10, B0-10, C0-10
      page_layout: :portrait # :landscape
    },
    png_options: {
      width: 800,
      height: 1000,
      background_color: '#ffffff'
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
      position: { # on the PDF
        x: 50,
        y: 50
      },
      size: {
        width: 500,
        height: 800
      },
      layers: [{
        type: 'osm', # to understand variable substitution and stitching toghether the final image
        urls: ['http://a.tile.thunderforest.com/transport/${z}/${x}/${y}.png'],
        level: 1,
        opacity: 1.0 # in case you want the layer to have some transparency
      }],
      geojson: '{
        "type": "FeatureCollection",
        "features": [{
          "type":"Feature",
          "geometry":{"type":"Point", "coordinates":[-32.026862,-55.425003]},
          "properties":{"image": "./marker.png"}
        }, {
          "type": "Feature",
          "geometry": {"type": "LineString", "coordinates": [ [-32.026862,-55.425003], [-31.026862,-55.425003], [-31.026862,-54.425003], [-32.026862,-54.425003] ] },
          "properties": {"color": "#000000"}
        }, {
          "type": "Feature",
          "geometry": {"type": "Polygon", "coordinates": [ [-32.126862,-55.825003], [-31.426862,-55.225003], [-31.326862,-54.825003], [-32.146862,-54.835003] ] },
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
        path: 'https://pixabay.com/static/uploads/photo/2014/04/03/10/03/google-309741_960_720.png',
        position: {x: 100, y: 10 },
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
        position: {x: 50, y: 0 },
        box_size: {width: 50, height: 50},
        options: {}
      }
    ],
    legend: {
      position: {x: 50, y: 50},
      size: {width: 50, height: 50},
      columns: 5,
      rows: 5,
      elements: [{
        image: './file.png',
        text: 'text'
      }]
    },
    scalebar: {
      unit: 'meters', # meters, km, miles, feet
      position: {x: 50, y: 50},
      size: {width: 50, height: 50}
    }
  }

  def test_print_returns_file_path
    map_print = MapPrint::Core.new(BASIC_MAP)
    assert_equal './map.pdf', map_print.print('./map.pdf')
  end

  def test_assert_printed_file_exists
    File.delete './map.pdf' if File.exist?('./map.pdf')
    MapPrint::Core.new(BASIC_MAP).print('./map.pdf')
    assert File.exist?('./map.pdf')
  end

  def test_assert_printed_png
    File.delete './map.png' if File.exist?('./map.png')
    MapPrint::Core.new(BASIC_MAP.merge(format: 'png')).print('./map.png')
    assert File.exist?('./map.png')
  end

  def teardown
    File.delete('./map.png') if File.exist?('./map.png')
  end
end
