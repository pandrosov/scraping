require 'fileutils'
require 'nokogiri'
require 'open-uri'
require 'curl'
require 'byebug'
require 'csv'


def get_page_data(html_local)

  dir_product = "#{File.dirname(__FILE__)}/result/products"
  FileUtils.mkdir(dir_product ) unless File.exists?(dir_product )
  parsing_end = 0
  html = Nokogiri::HTML.parse(open html_local)
  block = html.xpath(@mark_block_product)
  if(block.size == 0)
    parsing_end = 1
  else
    for x in 0...block.size
      prod_url = html.xpath(@mark_product_url.gsub('prod_block', (x+1).to_s)).map {|link| link['href'] }[0]
      unless @prod_url.include?(prod_url)
        @prod_url.push prod_url
        html_product = @prod_url[x].gsub(@site_domain, '')
        html_local_products = "#{dir_product}/#{html_product}"
        download_url(prod_url, html_local_products)
        get_products_data(html_local_products)
      else
        parsing_end = 1
      end
      if(parsing_end ==1)
        break
      end
    end
  end

  parsing_end

end


def get_products_data(product_page)

  html = Nokogiri::HTML.parse(open (product_page))
  title_product = html.xpath(@title).text
  blocks = html.xpath(@block)
  image = html.xpath(@image)

  title_product = title_product.strip
  image_product = image[0].attributes['src'].value

  blocks.each_with_index do |block, index|
    cost = block.xpath(@cost)[index].text
    weight = block.xpath(@weight)[index].text
    unless(title_product == "")
      product_data = {
          name: "#{title_product} - #{weight}",
          cost: cost,
          image_source: image_product
      }
      puts "Собираем информацию с сайта"

      puts product_data[:name]
      puts product_data[:cost]
      puts product_data[:image_source]
      @products_data << product_data
    end
  end

end



def download_url(url, html_local)

    unless File.exists?(html_local)
      file_save = File.open(html_local, 'w')
      c = Curl::Easy.perform("https://www.petsonic.com/huesos-para-perro/")
      page = c.body_str
      file_save.puts page

      file_save.close
      byebug
    end

end

def main2
  @site_domain = "https://www.petsonic.com/"


  url = "https://www.petsonic.com/huesos-para-perro/"


  puts "Введите имя файла в формате csv"
  file_name = gets.chomp

  name_page_file = url.gsub(@site_domain, '').chomp("/")
  dir_result = "#{File.dirname(__FILE__)}/result/"
  FileUtils.mkdir(dir_result) unless File.exists?(dir_result)

  @products_data = Array.new
  @count = 1
  @prod_url = []
  @title = '//*[@id="center_column"]/div/div/div[2]/div[2]/h1/text()'
  @block = '//*[@class="attribute_radio_list"]/li'
  @cost = '//*[@class="price_comb"]'
  @weight = '//*[@class="radio_label"]'
  @image  = '//*[@id="front-image"]'
  #block with all products
  @mark_block_product = '//*[@id="product_list"]/li'
  #url of products
  @mark_product_url = "#{@mark_block_product}[prod_block]/div/div/div[1]/a"



  exist_products = 1
  page_number = 0
  while exist_products == 1
    page_number += 1
    url_cur = "#{url}?p=#{page_number}"
    html_local = "#{dir_result}#{name_page_file}-page_#{page_number}.html"
    download_url(url_cur, html_local)
    parsing_end = get_page_data(html_local)
    break if parsing_end == 1
    byebug
  end


  dir_result = "#{File.dirname(__FILE__)}/result/"
  CSV.open("#{dir_result}#{file_name}", "wb") do |row|
    @products_data.each_with_index do |item, index|
      row << [@products_data[index][:name], @products_data[index][:cost], @products_data[index][:image_source]]
    end
  end
  puts "Данные записаны в файл #{file_name}"

end


main2
