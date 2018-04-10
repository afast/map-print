require 'json'

module MapPrint
  class GeoJSONHandler
    def initialize(geojson, sw, ne, width, height)
      @top_lat = ne[:lat]
      @total_lat = (ne[:lat] - sw[:lat])
      @left_lng = sw[:lng]
      @total_lng = (ne[:lng] - sw[:lng])
      @height = height
      @width = width
      @geojson = JSON[geojson]
    rescue JSON::GeneratorError, JSON::ParserError
      raise InvalidGeoJSON.new("Invalid GeoJSON: #{geojson.inspect}")
    end

    def process
      tempfile = Tempfile.new ['geojson', '.png']
      `convert -density 300 -size #{@width}x#{@height} xc:transparent #{tempfile.path}`
      @image = MiniMagick::Image.new tempfile.path

      draw_geojson

      @image.write(tempfile.path)
      MiniMagick::Image.open(tempfile.path)
    ensure
      tempfile.close
    end

    private
    def draw_geojson
      if @geojson['type'] == 'Feature'
        feature(@geojson['geometry'], @geojson['properties'])
      elsif @geojson['type'] == 'FeatureCollection'
        feature_collection(@geojson['features'])
      else
        Logger.warn "Warning, expected type Feature with #{@geojson['type'].inspect} inside geometry and drawing properties, like: {'type': 'Feature', 'geometry':#{@geojson.to_json}, 'properties':{'image': 'path/or/url/to/image'}}"
      end
    end

    def validate_feature(geometry, properties)
      raise NoGeometryPresent.new("No geometry present for this feature") if geometry.nil?
      case geometry['type']
      when 'Point'
        if properties.nil? || properties['image'].nil?
          raise NoPointImage.new("Missing image in point geometry")
        end
      when 'MultiPoint', 'MultiLineString', 'MultiPolygon', 'GeometryCollection'
        raise FeatureNotImplemented.new("Please consider contributing!")
      else
        Logger.warn "Feature type '#{geometry['type']}' not implemented!"
      end
    end

    def feature(geometry, properties={})
      validate_feature(geometry, properties)
      case geometry['type']
      when 'Feature'
        feature(geometry['geometry'], geometry['properties'])
      when 'FeatureCollection'
        feature_collection(geometry['features'])
      when 'Point'
        point(geometry, properties['image'])
      when 'LineString'
        line_string(geometry, properties)
      when 'Polygon'
        polygon(geometry, properties)
      end
    rescue GeoJSONHandlerError => ex
      Logger.warn ex
    end

    def feature_collection(features)
      features.each do |object|
        feature(object['geometry'], object['properties'])
      end
    end

    def point(point, image_path)
      x = get_x(point['coordinates'][0])
      y = get_y(point['coordinates'][1])

      if point_inside_map?(x, y)
        point_image = MiniMagick::Image.open(image_path)
        x -= point_image.width / 2
        y -= point_image.height / 2

        @image.composite(point_image) do |c|
          c.density 300
          c.geometry("+#{x}+#{y}")
        end.write @image.path
      else
        Logger.warn "Point #{image_path} is outside the map's boundaries!\n#{point.inspect}"
      end
    end

    def line_string(geometry, properties)
      points = generate_drawable_points(geometry, properties)

      draw_command = (0..(points.length - 2)).map do |i|
        "line #{points[i]} #{points[i+1]}"
      end.join(' ')

      @image.combine_options do |c|
        c.density 300
        c.draw "#{draw_options(properties)} #{draw_command}"
      end
    end

    def polygon(geometry, properties)
      points = generate_drawable_points(geometry, properties)

      @image.combine_options do |c|
        c.density 300
        c.draw "#{draw_options(properties, false)} polygon #{points.join(' ')}"
      end
    end

    def stroke_options(properties)
      options = ''
      if properties['stroke'] || properties['stroke'].nil?
        options += "stroke #{properties['color'] || '#0033ff'} "
        options += "stroke-width #{properties['weight'] || 5} "
        options += "stroke-opacity #{properties['opacity'] || 0.5} "
      end
      options
    end

    def fill_options(properties, line)
      options = ''
      if properties['fill'] != false || !line
        options += "fill #{properties['fillColor'] || '#0033ff'} "
        options += "fill-opacity #{properties['fillOpacity'] || 0.2} "
        options += "fill-rule #{properties['fillRule'] || 'evenodd'} "
      end
      options
    end

    def draw_options(properties, line=true)
      options = stroke_options(properties)
      options += fill_options(properties, line)
      options += "stroke-dasharray #{properties['dashArray']} " if properties['dashArray']
      options += "stroke-linecap #{properties['lineCap']} " if properties['lineCap']
      options += "stroke-linejoin #{properties['lineJoin']} " if properties['lineJoin']
      options
    end

    def get_x(lng)
      @width * (lng - @left_lng) / @total_lng;
    end

    def get_y(lat)
      @height * (@top_lat - lat) / @total_lat;
    end

    def point_inside_map?(x, y)
      0 <= x && x <= @width && 0 <= y && y <= @height
    end

    def consider_outside_boundaries(x, y, geometry, properties)
      if !point_inside_map?(x, y)
        Logger.warn "Coordinate outside map's boundaries!\ngeometry: #{geometry.inspect}\nproperties: #{properties.inspect}"
      end
    end

    def generate_drawable_points(geometry, properties)
      properties ||= {}
      coords = geometry['coordinates']
      coords = coords.first if coords.first.first.is_a?(Array)
      coords.map do |coord|
        x = get_x(coord[0])
        y = get_y(coord[1])
        consider_outside_boundaries(x, y, geometry, properties)
        "#{x},#{y}"
      end
    end
  end
end
