#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'

# submitted language to file extension
class Lang2lang
  @@transform_table = {
    'gnu_c' => 'c',
    'gnu_c++' => 'cpp',
    'gnu_c++0x' => 'cpp',
    'ms_c++' => 'cpp',
    'mono_c#' => 'cs',
    'ms_c#' => 'cs',
    'd' => 'd',
    'go' => 'go',
    'haskell' => 'hs',
    'java_6' => 'java',
    'java_7' => 'java',
    'java_8' => 'java',
    'ocaml' => 'ml',
    'delphi' => 'dpk',
    'fpc' => 'pp',
    'perl' => 'pl',
    'php' => 'php',
    'python_2' => 'py',
    'python_3' => 'py',
    'ruby' => 'rb',
    'scala' => 'scala',
    'javascript' => 'js'
  }
  class << self
    def file_extension key
      @@transform_table[key]
    end
    alias :'[]' :file_extension
  end
end

# program basic usage
def usage
  puts <<-END.gsub(/^\s*\|/, '')
    |Usage:
    |#{File.basename($0).to_s} username [file_ext] [limit]
    |  username: codeforces username
    |  file_ext: file extension, the language you want to grab, default is all
    |  limit   : grab at most limit submissions, default is unlimited
  END
end

# get pagination number of all the submissions
def  get_page_num url
  page = Nokogiri::HTML(open(url))
  page.css('span[class=page-index]')[-1]['pageindex'].to_i
end

# get submission url of specific user
def get_sub_url username
  'http://codeforces.com/submissions/' + username
end

# get url of specific pagination id
def get_sub_url_i username, page_id
  'http://codeforces.com/submissions/' + username + '/page/' + page_id
end

# get source url of specific submission id
def get_source_url sub_id, contest_id
  'http://codeforces.com/contest/' + contest_id + '/submission/' + sub_id
end

# get source code of submission id
def get_source_code sub_id, contest_id
  url = get_source_url sub_id, contest_id
  page = Nokogiri::HTML(open(url))
  source_code = page.css('div').css('pre[class="prettyprint"]').text
end

# get all submissions on a specific submissoin page
def get_all_subs url
  page = Nokogiri::HTML(open(url))
#  page = Nokogiri::HTML(File.open('out.html'))
  page.css('tr[data-submission-id]').each do |e|
    info = e.css('td')
    sub_id = info.css('a[class="view-source"]').text
    problem_name = info.css('td[class="status-small"]').css('a').text.split[0]
    contest_id = problem_name[0..-2]
    lang = info[4].text.strip.gsub(/\s+/, '_').downcase
    verdict = info.css('span[class="submissionVerdictWrapper"]')[0]['submissionverdict']
    yield sub_id, contest_id, problem_name, lang, verdict
  end
end

# get codeforces submitted source files
def get_source_file username, lang_op='all', limit=-1
  sub_url = get_sub_url username
  page_num = get_page_num sub_url
  tot_subs = 0
  page_num.times do |i|
    sub_url_i = get_sub_url_i username, (i + 1).to_s
    get_all_subs sub_url_i do |sub_id, contest_id, problem_name, lang, verdict|
      puts "#{tot_subs+1}: #{sub_id} #{contest_id} #{problem_name} #{lang} #{verdict}"
      tot_subs += 1
      if contest_id.length < 4 && verdict == 'OK'
        file_ext = Lang2lang[lang]
        file_name = problem_name + '.' + file_ext
        if !File.exist?(file_name) && (lang_op == 'all' || lang_op == file_ext)
          source_code = get_source_code sub_id, contest_id
          File.open(file_name, 'w') { |file| file.write(source_code) }
        end
      end
      return if limit != -1 && tot_subs >= limit
    end
  end
end

# simple parse args
if ARGV.empty?
  usage
else
  len = ARGV.length
  if len == 1
    get_source_file ARGV[0]
  elsif len == 2
    get_source_file ARGV[0], ARGV[1]
  elsif len == 3
    get_source_file ARGV[0], ARGV[1], ARGV[2].to_i
  else
    usage
  end
end

# vim:ts=2:sw=2:et
