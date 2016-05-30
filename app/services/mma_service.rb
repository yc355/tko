class MMAService
  SHERDOG_BASE_URL = "http://www.sherdog.com"
  SHERDOG_FIGHTFINDER_URL = "/stats/fightfinder?SearchTxt="

  def self.sherdog_fighter_link(query)
    url = URI.parse("#{SHERDOG_BASE_URL}#{SHERDOG_FIGHTFINDER_URL}#{query.strip.gsub('_', '+')}")
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    links = Nokogiri::HTML(res.body).css('.fightfinder_result a')
    if links.present?
      "#{SHERDOG_BASE_URL}#{Nokogiri::HTML(res.body).css('.fightfinder_result a')[0].attributes['href'].value}"
    else
      no_profile_found_message
    end
  end

  def self.fighter_search(query)
    if sherdog_fighter_link(query) != no_profile_found_message
      url = URI.parse(sherdog_fighter_link(query))
      req = Net::HTTP::Get.new(url.to_s)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }
      sherdog_page = Nokogiri::HTML(res.body)
    else
      return no_profile_found_message
    end

    fighter_hash = fighter_template
    fighter_hash[:link] = sherdog_fighter_link(query)
    fighter_hash[:img_url] = sherdog_page.css('.bio_fighter [itemprop="image"]').attr('src').to_s
    fighter_hash[:name] = sherdog_page.css('h1[itemprop="name"] .fn').text
    fighter_hash[:nickname] = sherdog_page.css('h1[itemprop="name"] .nickname').text.gsub(/"/, '')
    fighter_hash[:age] = sherdog_page.css('.item.birthday strong').text.gsub(/[^\d]/, '')
    fighter_hash[:birthday] = sherdog_page.css('span[itemprop="birthDate"]').text
    fighter_hash[:locality] = sherdog_page.css('span[itemprop="addressLocality"]').text
    fighter_hash[:nationality] = sherdog_page.css('strong[itemprop="nationality"]').text
    fighter_hash[:flag_url] = sherdog_page.css('.birthplace img').attr('src').to_s
    fighter_hash[:association] = sherdog_page.css('.item.association span[itemprop="name"]').text
    fighter_hash[:height] = sherdog_page.css('.item.height strong').text
    fighter_hash[:weight] = sherdog_page.css('.item.weight strong').text
    fighter_hash[:weight_class] = sherdog_page.css('.item.wclass strong').text

    record = sherdog_page.css('.record .count_history')
    wins = record.css('.left_side .bio_graph')[0]
    fighter_hash[:wins][:total] = wins.css('.counter').text
    fighter_hash[:wins][:knockouts] = wins.css('.graph_tag:nth-child(3)').text.to_i.to_s
    fighter_hash[:wins][:submissions] = wins.css('.graph_tag:nth-child(5)').text.to_i.to_s
    fighter_hash[:wins][:decisions] = wins.css('.graph_tag:nth-child(7)').text.to_i.to_s
    fighter_hash[:wins][:others] = wins.css('.graph_tag:nth-child(9)').text.to_i.to_s
    losses = record.css('.left_side .bio_graph')[1]
    fighter_hash[:losses][:total] = losses.css('.counter').text
    fighter_hash[:losses][:knockouts] = losses.css('.graph_tag:nth-child(3)').text.to_i.to_s
    fighter_hash[:losses][:submissions] = losses.css('.graph_tag:nth-child(5)').text.to_i.to_s
    fighter_hash[:losses][:decisions] = losses.css('.graph_tag:nth-child(7)').text.to_i.to_s
    fighter_hash[:losses][:others] = losses.css('.graph_tag:nth-child(9)').text.to_i.to_s

    if record.at('.right_side .bio_graph .card .result:contains("Draws") + span')
      fighter_hash[:draws] = record.at('.right_side .bio_graph .card .result:contains("Draws") + span').text
    end

    if record.at('.right_side .bio_graph .card .result:contains("N/C") + span')
      fighter_hash[:no_contests] = record.at('.right_side .bio_graph .card .result:contains("N/C") + span').text
    end

    fighter_hash[:fights] = build_fights(sherdog_page)

    return fighter_hash
  end

  private

    def self.no_profile_found_message
      "No fighter profile found"
    end

    def self.build_fights(sherdog_page)
      fights = []
      sherdog_page.css('.module.fight_history tr:not(.table_head)').each do |row|
        fight = fight_template

        fight[:event] = row.css('td:nth-child(3) a').text
        fight[:date] = row.css('td:nth-child(3) .sub_line').text
        fight[:opponent] = row.css('td:nth-child(2) a').text
        fight[:result] = row.css('td:nth-child(1) .final_result').text

        method = row.css('td:nth-child(4)').text
        if method.split[0].to_s.include? "Draw"
          fight[:method] = "Draw"
        elsif method.split[0].to_s.include? "DQ"
          fight[:method] = "DQ"
        else
          fight[:method] = method.include?('(') ? method.split[0] :
            row.css('td:nth-child(4)').children[0] ? row.css('td:nth-child(4)').children[0].text : ''
        end
        if method[/\(.*?\)/]
          fight[:method_details] = method[/\(.*?\)/][1..-2]
        end

        fight[:round] = row.css('td:nth-child(5)').text
        fight[:time] = row.css('td:nth-child(6)').text
        fight[:referee] = row.css('td:nth-child(4) .sub_line').text

        if fight[:event] != ""
          fights << fight
        end
      end
      fights
    end

    def self.fighter_template
      {
        link: "",
        img_url: "",
        name: "",
        nickname: "",
        age: "",
        birthday: "",
        locality: "",
        nationality: "",
        flag_url: "",
        association: "",
        height: "",
        weight: "",
        weight_class: "",
        wins: {
          total: 0,
          knockouts: 0,
          submissions: 0,
          decisions: 0,
          others: 0
        },
        losses: {
          total: 0,
          knockouts: 0,
          submissions: 0,
          decisions: 0,
          others: 0
        },
        draws: 0,
        no_contests: 0,
        fights: []
      }
    end

    def self.fight_template
      {
        event: "",
        date: "",
        opponent: "",
        result: "",
        method: "",
        method_details: "",
        round: "",
        time: "",
        referee: ""
      }
    end
end
