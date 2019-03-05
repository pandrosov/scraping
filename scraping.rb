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
  block = html.xpath(@block_product)


  for x in 0...block.size
    prod_url = html.xpath(@product_url.gsub('prod_block', (x+1).to_s)).map {|link| link['href'] }[0]
    unless @prod_url.include?(prod_url)
      @prod_url.push prod_url
      html_product = @prod_url[@counter].gsub(@site_domain, '')
      @counter += 1
      html_local_products = "#{dir_product}/#{html_product}"
      download_url(prod_url, html_local_products)
      get_products_data(html_local_products)
    else
      parsing_end = 1
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

  if(blocks.size == 0)
    cost = html.xpath('//*[@id="our_price_display"]').text
    product_data = {
        name: "#{title_product}",
        cost: cost,
        image_source: image_product
    }
    @products_data << product_data
  end

  for index in 0..blocks.size-1
    block = blocks[index]
    cost = block.xpath(@cost)[index].text
    weight = block.xpath(@weight)[index].text
    unless(title_product == "")
      product_data = {
          name: "#{title_product} - #{weight}",
          cost: cost,
          image_source: image_product
      }
      @products_data << product_data
      puts "Собираем информацию с сайта"
      puts product_data[:name]
      puts product_data[:cost]
      puts product_data[:image_source]


    end
  end

end



def download_url(url, html_local)

  flag = true

  unless File.exists?(html_local)
    c = Curl::Easy.perform(url)
    page = c.body_str
    unless (page == "")
      file_save = File.open(html_local, 'w')
      file_save.puts page
      file_save.close
    else
      flag = false
    end
  end
  flag
end

def main2
  @site_domain = "https://www.petsonic.com/"

  puts "Передайте ссылку на категорию"
  url = get.chomp


  puts "Введите имя файла в формате csv"
  file_name = get.chomp

  name_page_file = url.gsub(@site_domain, '').chomp("/")
  dir_result = "#{File.dirname(__FILE__)}/result/"
  FileUtils.mkdir(dir_result) unless File.exists?(dir_result)

  @products_data = Array.new
  @prod_url = []
  @title = '//h1'
  @counter = 0
  @block = '//*[@class="attribute_radio_list"]/li'
  @cost = '//*[@class="price_comb"]'
  @weight = '//*[@class="radio_label"]'
  @image  = '//*[@id="bigpic"]'
  #block with all products
  @block_product = '//*[@id="product_list"]/li'
  #url of products
  @product_url = "#{@block_product}[prod_block]/div/div/div[1]/a"
  exist_products = 1
  page_number = 1
  while exist_products == 1

    unless (page_number != 1)
      url_cur = url
      html_local = "#{dir_result}#{name_page_file}.html"
    else
      url_cur = "#{url}?p=#{page_number}"
      html_local = "#{dir_result}#{name_page_file}-page_#{page_number}.html"
    end
    page_number += 1

    if (download_url(url_cur, html_local))
      parsing_end = get_page_data(html_local)
    else
      parsing_end = 1
    end

    break if parsing_end == 1
  end

  dir_result = "#{File.dirname(__FILE__)}/result/"

  CSV.open("#{dir_result}#{file_name}", "wb", write_headers: true, headers: @products_data.first.keys) do |row|
    @products_data.each_with_index do |item|
      row << item.values
    end
  end
  puts "Данные записаны в файл #{file_name}"

end


main2

