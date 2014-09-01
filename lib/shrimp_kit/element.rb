module ShrimpKit
  class Element

    attr_accessor :styles, :parent, :children, :text, :type, :node

    def initialize(node:, type:, parent:, text: nil, styles: {}, bullet: nil)
      @type = type.to_sym
      @node = node
      raise "Unsupported html tag »#{@type}«" unless DEFAULT_STYLES.has_key? @type
      @text = text
      @parent = parent
      @parent.children << self if @parent
      @children = []
      @bullet = bullet
      # binding.pry
      @styles = DEFAULT_STYLES[@type].merge(styles)
    end

    def inspect
      "<SKElement #{@type}: #{@text} #{@styles}>"
    end
    alias_method :to_s, :inspect

    def empty?() children.present? end

    def block_element?()
      @_block_element = (full_styles[:display] == :block)
    end

    def all_styles()
      @_all_styles ||= (parent.try(:all_styles) || {}).merge(styles)
    end

    def full_styles
      @_full_styles ||= DEFAULT_STYLES['*'].merge all_styles
    end

    def prawn_styles
      as = full_styles
      {
        styles: [as[:font_style], as[:font_weight]].reject{|s| s==:normal}.compact,
        color: as[:text_color],
        size: as[:font_size]
      }
    end

    def render(pdf)
      l = render_private(pdf, list: [])
    end

    def render_private(pdf, list:)
      if block_element?
        render_private_block pdf, list: list
      else
        render_private_inline pdf, list: list
      end
    end

    def render_private_block(pdf, list:)
      as = full_styles
      pdf.formatted_text(list) if list.present?
      pdf.move_down as[:margin_top]
      if @bullet.present?
        c = pdf.cursor
        pdf.text @bullet
        pdf.move_up c - pdf.cursor
      end
      pdf.indent @styles[:margin_left] || 0 do
        l = children.inject([]) do |a, e|
          e.render_private(pdf, list: a)
        end
        pdf.formatted_text l if l.present?
      end
      pdf.move_down as[:margin_bottom]
      []
    end

    def render_private_inline(pdf, list:)
      as = full_styles
      list << for_formatted_text if text
      children.inject(list) do |a,e|
        e.render_private(pdf, list: a)
      end
    end

    def for_formatted_text
      prawn_styles.merge text: text
    end
  end # Element
end # ShrimpKit
