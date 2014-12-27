#!/usr/bin/ruby
=begin
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

require 'rubygems'
require 'json'
require "rexml/document"
include REXML
require 'awesome_print'

def usage (message = nil)
  if message
    puts "ERROR: #{message}"
  end
  puts """Usage: 1pass2keepass.rb 1pass.1pif

Convert a 1Password export file to XML suitable for import into KeepassX.
"""
  exit
end


input_file = ARGV[0]
unless ARGV[0]
  usage
end
unless File.exists?(input_file)
  usage "File '#{input_file}' does not exist" 
end

lines = File.open(input_file).readlines()
lines.reject! {|l| l =~ /^\*\*\*/}

groups = {}
username = password = nil
lines.each do |line|
  entry = JSON.parse(line)
  if entry['trashed']
    next
  end

  group_name = entry['typeName'].split('.')[-1]
  if not groups.has_key?(group_name)
    groups[group_name] = {}
  end
  title = entry['title']

  case group_name
    when 'Password','Database','UnixServer','Email','GenericAccount'
      groups[group_name][title] = {
        :url => nil,
        :username => entry['secureContents']['username'],
        :password => entry['secureContents']['password'],
        :creation => Time.at(entry['createdAt'].to_i).strftime("%Y-%m-%dT%H:%I:%S"),
        :lastmod => Time.at(entry['updatedAt'].to_i).strftime("%Y-%m-%dT%H:%I:%S"),
        :comment => entry['secureContents']['notesPlain'],
      } unless (groups[group_name].has_key?(title) and groups[group_name][title]['updatedAt'].to_i > entry['updatedAt'].to_i)
    when 'SecureNote'
      groups[group_name][title] = {
        :url => nil,
        :username => nil,
        :password => nil,
        :creation => Time.at(entry['createdAt'].to_i).strftime("%Y-%m-%dT%H:%I:%S"),
        :lastmod => Time.at(entry['updatedAt'].to_i).strftime("%Y-%m-%dT%H:%I:%S"),
        :comment => entry['secureContents']['notesPlain'],
      } unless (groups[group_name].has_key?(title) and groups[group_name][title]['updatedAt'].to_i > entry['updatedAt'].to_i)
    when 'CreditCard'
      groups[group_name][title] = {
        :url => nil,
        :username => entry['secureContents']['ccnum'],
        :password => entry['secureContents']['v'],
        :creation => Time.at(entry['createdAt'].to_i).strftime("%Y-%m-%dT%H:%I:%S"),
        :lastmod => Time.at(entry['updatedAt'].to_i).strftime("%Y-%m-%dT%H:%I:%S"),
        :comment => "#{entry['secureContents']['expiry_mm']}/#{entry['secureContents']['expiry_yy']}",
      } unless (groups[group_name].has_key?(title) and groups[group_name][title]['updatedAt'].to_i > entry['updatedAt'].to_i)
    when 'BankAccountUS'
      groups[group_name][title] = {
        :url => nil,
        :username => entry['secureContents']['accountNo'],
        :password => nil,
        :creation => Time.at(entry['createdAt'].to_i).strftime("%Y-%m-%dT%H:%I:%S"),
        :lastmod => Time.at(entry['updatedAt'].to_i).strftime("%Y-%m-%dT%H:%I:%S"),
        :comment => "Bank Name: #{entry['secureContents']['bankName']}\nAccount: #{entry['secureContents']['accountNo']}\nRouting: #{entry['secureContents']['routingNo']}\nType: #{entry['secureContents']['accountType']}\nBank Address: #{entry['secureContents']['branchAddress']}\nBank Phone: #{entry['secureContents']['branchPhone']}\n",
      } unless (groups[group_name].has_key?(title) and groups[group_name][title]['updatedAt'].to_i > entry['updatedAt'].to_i)
    when 'Regular', 'SavedSearch', 'Point'
      next
    when 'WebForm'
      entry['secureContents']['fields'].each do |field|
        case field['designation']
          when 'username'
            username = field['value']
          when 'password'
            password = field['value']
        end
      end

      groups[group_name][title] = {
        :url => entry['location'],
        :username => username,
        :password => password,
        :creation => Time.at(entry['createdAt'].to_i).strftime("%Y-%m-%dT%H:%I:%S"),
        :lastmod => Time.at(entry['updatedAt'].to_i).strftime("%Y-%m-%dT%H:%I:%S"),
        :comment => entry['secureContents']['notesPlain'],
      } unless (groups[group_name].has_key?(title) and groups[group_name][title]['updatedAt'].to_i > entry['updatedAt'].to_i)

      username = password = nil
    else
      STDERR.puts "Don't know how to handle records of type #{entry['typeName']} yet."
  end
end

doc = Document.new 
database = doc.add_element 'database'

groups.each do |group_name, entries|
  next if entries.empty?
  group = database.add_element 'group'
  case group_name
    when 'Password'
      group.add_element('title').text = 'Password'
      group.add_element('icon').text = '0'
    when 'BankAccountUS'
      group.add_element('title').text = 'Bank Account'
      group.add_element('icon').text = '66'
    when 'CreditCard'
      group.add_element('title').text = 'Credit Card'
      group.add_element('icon').text = '66'
    when 'SecureNote'
      group.add_element('title').text = 'Secure Note'
      group.add_element('icon').text = '54'
    when 'WebForm'
      group.add_element('title').text = 'Internet'
      group.add_element('icon').text = '1'
    when 'Email'
      group.add_element('title').text = 'Email'
      group.add_element('icon').text = '19'
    when 'Database'
      group.add_element('title').text = 'Database'
      group.add_element('icon').text = '6'
    when 'UnixServer'
      group.add_element('title').text = 'Unix Server'
      group.add_element('icon').text = '30'
    when 'GenericAccount'
      group.add_element('title').text = 'Generic Account'
      group.add_element('icon').text = '20'
  end

  entries.each do |title, entry|
    entry_node = group.add_element 'entry'
    ["username", "password", "comment", "title"].each do |field|
      if entry[field.to_sym]
        node = entry_node.add_element(field)
        node.text = ""
        entry[field.to_sym].gsub(/\r/, '').split("\n").each_with_index do |t,i|
          node.add_text t
          if i != (entry[field.to_sym].gsub(/\r/, '').split("\n").size - 1)
            node.add_element "br"
          end
        end
      end
    end
    entry_node.add_element('creation').text = entry[:creation]
    entry_node.add_element('lastmod').text = entry[:lastmod]
    entry_node.add_element('url').text = entry[:url]
  end
end

doc << XMLDecl.new
doc.write($stdout)
