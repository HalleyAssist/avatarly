require 'vips'
require 'pathname'

class Avatarly
  BACKGROUND_COLORS = [
      "#ff4040", "#7f2020", "#cc5c33", "#734939", "#bf9c8f", "#995200",
      "#4c2900", "#f2a200", "#ffd580", "#332b1a", "#4c3d00", "#ffee00",
      "#b0b386", "#64664d", "#6c8020", "#c3d96c", "#143300", "#19bf00",
      "#53a669", "#bfffd9", "#40ffbf", "#1a332e", "#00b3a7", "#165955",
      "#00b8e6", "#69818c", "#005ce6", "#6086bf", "#000e66", "#202440",
      "#393973", "#4700b3", "#2b0d33", "#aa86b3", "#ee00ff", "#bf60b9",
      "#4d3949", "#ff00aa", "#7f0044", "#f20061", "#330007", "#d96c7b"
    ].freeze

  class << self
    def generate_avatar(text, opts={})
      opts = parse_options(opts)

      # Convert text to initials
      text = initials(text.to_s.strip.gsub(/[^\w@ ]/,''), opts)
      text = text.upcase if opts[:upcase]
      
      # Create image with initials
      image = generate_image(text, opts)
      image.write_to_buffer ".#{opts[:format]}[Q=#{opts[:quality]}]"
    end

    def root
      File.expand_path '../..', __FILE__
    end

    def lib
      File.join root, 'lib'
    end

    private

    def fonts
      File.join root, 'assets/fonts'
    end

    def generate_image(text, opts)
      # Create background with solid colour
      background_image = Vips::Image.black(opts[:size], opts[:size]).colourspace(:srgb)
      background_image = background_image.new_from_image(hex_to_rgb(opts[:background_color]))

      # Write text
      draw_text(background_image, text, opts)
    end

    def draw_text(canvas, text, opts)
      # Create centred text
      text_mask = Vips::Image.text(text,
                                   font: 'Roboto',
                                   fontfile: "#{fonts}/Roboto.ttf",
                                   height: opts[:size],
                                   dpi: opts[:size]*3
                                  )
      text_mask = text_mask.gravity :centre, opts[:size], opts[:size]
      text_mask = text_mask.embed 0, text_mask.height/50, opts[:size], opts[:size]
      
      # Write text in font colour
      text_colour = hex_to_rgb(opts[:font_color])
      text_image = (text_mask.new_from_image text_colour).copy interpretation: :srgb
      text_image = text_image.bandjoin text_mask

      # Write on background image
      canvas.composite(text_image, :over)
    end

    def initials(text, opts)
      if opts[:separator]
        initials_for_separator(text, opts[:separator])
      elsif text.include?(" ")
        initials_for_separator(text, " ")
      else
        initials_for_separator(text, ".")
      end
    end

    def initials_for_separator(text, separator)
      if text.include?(separator)
        text.split(separator).compact.map { |part| part[0] }.first(3).join
      else
        text[0] || ''
      end
    end

    def default_options
      { background_color: BACKGROUND_COLORS.sample,
        font_color: '#FFFFFF',
        size: 32,
        upcase: true,
        quality: 90,
        format: "png" }
    end

    def parse_options(opts)
      opts = default_options.merge(opts)
      opts[:size] = opts[:size].to_i
      opts[:quality] = opts[:quality].to_i
      opts
    end

    # Splits RGB colour code into Vips compatible array
    def hex_to_rgb(hex_color)
      hex_color = hex_color.gsub("#", "")
      r = hex_color[0..1].to_i(16)
      g = hex_color[2..3].to_i(16)
      b = hex_color[4..5].to_i(16)
      [r, g, b]
    end
  end
end
