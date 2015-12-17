require_relative 'lat_lng'
require_relative 'tiles/tile'
require_relative 'tiles/tile_factory'
require_relative 'providers/base'
require_relative 'providers/bing'
require_relative 'providers/open_street_map'
require_relative 'layer_handler'
require_relative 'scalebar_handler'
require_relative 'image_handler'
require_relative 'text_handler'
require_relative 'legend_handler'
require_relative 'geo_json_handler'

module MapPrint
  class Core
    attr_accessor :map, :images, :texts, :legend, :scalebar

    PROVIDERS = {
      'bing' => MapPrint::Providers::Bing,
      'osm'  => MapPrint::Providers::OpenStreetMap
    }

    def self.print(provider_name, south_west, north_east, zoom)
      provider_class = PROVIDERS[provider_name]
      provider = provider_class.new(south_west, north_east, zoom)
      provider.download
    end

    def self.get_layer(south_west, north_east, zoom)
      provider = MapPrint::Providers::OpenStreetMap.new(south_west, north_east, zoom)
      provider.download
    end

    def initialize(output_path, args)
      @format = args[:format]
      @pdf_options = args[:pdf_options]
      @map = args[:map]
      @images = args[:images]
      @texts = args[:texts]
      @legend = args[:legend]
      @scalebar = args[:scalebar]
      @output_path = output_path
    end

    def print
      if @format == 'pdf'
        print_pdf
      elsif @format == 'png'
        print_png
      else
        raise "Unsupported format: #{@format}"
      end
    end

    private
    def print_pdf
      pdf = init_pdf
      map_image = print_layers
      map_image = print_geojson(MiniMagick::Image.new(map_image.path))

      FileUtils.cp map_image.path, './map.png'

      pdf.image map_image.path, at: [@map[:position][:x], pdf.bounds.top - @map[:position][:y]]

      print_images_on_pdf(pdf)
      print_texts_on_pdf(pdf)
      print_legend_on_pdf(pdf)

      pdf.render_file(@output_path)
      @output_path
    end

    def print_png
    end

    def init_file
      @file = File.open @output_path, 'wb'
    end

    def init_pdf
      Prawn::Document.new @pdf_options || {}
    end

    def print_layers
      file = LayerHandler.new(@map[:layers], @map[:sw], @map[:ne], @map[:zoom]).process
      size = @map[:size]

      FileUtils.cp file.path, 'layers.png'

      if size
        image = MiniMagick::Image.new(file.path)
        size[:width] ||= image.width
        size[:height] ||= image.height
        puts "Fitting map image (#{image.width}x#{image.height}) in #{size[:width]}x#{size[:height]}"
        image.colorspace("RGB").resize("#{size[:width]}x#{size[:height]}\>").colorspace("sRGB").unsharp "0x0.75+0.75+0.008"
      end

      file
    end

    def print_geojson(map_image)
      geojson_image = GeoJSONHandler.new(@map[:geojson], @map[:sw], @map[:ne], map_image.width, map_image.height).process
      result = MiniMagick::Image.open(map_image.path).composite(geojson_image) do |c|
        c.compose "atop"
      end
      result.write map_image.path
      map_image
    end

    def print_images_on_pdf(pdf)
    end

    def print_texts_on_pdf(pdf)
    end

    def print_scalebar
    end

    def print_legend_on_pdf(pdf)
    end
  end
end
