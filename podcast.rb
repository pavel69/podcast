#!/usr/bin/ruby
# https://github.com/boncey/ruby-podcast

require 'uri'
require 'yaml'
require 'rss'

class Podcast
  attr :author, :title, :subtitle, :pattern, :base_url, :content_type, :image, :description, :podcast_outfile, :language, :categories, :name

  @podcast_yaml = 'podcast.yaml'

  def files
    Dir.glob(@pattern).sort

    #{ arr.sort_by { |h| h.scan(/(\d+)\.txt/).flatten[0].to_i } }
    #{ arr.sort_by { |path| File.basename(path, '.txt').to_i } }

  end

  def self.load
    obj = YAML::load(File.open(@podcast_yaml))
    obj.set_defaults
    obj
  end

  def set_defaults
    re = /(.+?)(\.[^.]*$|$)/
    ir = '#{$1}'

    @language ||= 'ru-ru'
    @podcast_outfile ||= 'podcast.rss'
    @image ||= 'podcast.png'

    if @name.nil?
      @name ||= { regexp: re, interpolate: ir }
    else
      @name[:regexp] = re unless @name.key?(:regexp)
      @name[:interpolate] = ir unless @name.key?(:interpolate)
    end
  end


  def create_categories(categories, items)

    if items.kind_of?(Array)

      items.each do |item|

        category = categories.new_category
        category.text = item[:category]

        if item.key?(:categories)
          create_categories(category, item[:categories])
        end
      end

    end
  end


  def rss

    img = URI::join(@base_url, @image)

    rss = RSS::Maker.make('2.0') do |maker|
      maker.channel.itunes_author = @author
      maker.channel.title = @title
      maker.channel.itunes_subtitle = @subtitle
      maker.channel.itunes_summary = @description
      maker.channel.itunes_image = img
      maker.channel.language = @language

      create_categories(maker.channel.itunes_categories, @categories)

      maker.channel.link = URI::join(@base_url, @podcast_outfile)
      maker.channel.description = @description

      re = @name[:regexp]

      i = 0

      files.each do |f|
        maker.items.new_item do |item|
          i += 1
          link = URI::join(@base_url, URI::escape(f) )
          item.link = link
          re.match(f)
          item.title = eval(%Q["#{@name[:interpolate]}"])
          item.guid.content = link

          #item.enclosure.url = link
          #item.enclosure.length = 0
          #item.enclosure.type = @content_type
        end
      end

    end

    #puts rss

    File.open(@podcast_outfile, "w") { |f| f.write(contents) }

  end

  def self.rss2yaml(file_name)
    x = RSS::Parser.parse(file_name)
    File.open("#{file_name}.yaml", 'w') {|f| f.write(YAML.dump(x)) }
  end

end
