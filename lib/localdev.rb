#
# Localdev - Hosts file tool for local development
#
# Copyright 2011-2015 by Mark Jaquith
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

require 'digest/md5'
require 'yaml'

class Localdev
	VERSION = '0.4.0'

	def initialize
		@debugMode = false
		@localdev = '/etc/hosts-localdev'
		@hosts = '/etc/hosts'
		@start = '#==LOCALDEV==#'
		@end = '#/==LOCALDEV==#'
		if !ARGV.first.nil? && [:on, :off, :add, :remove, :clear].include?( ARGV.first.to_sym )
			require_sudo
			ensure_localdev_exists
		end
		command = ARGV.shift
		command = command.to_sym unless command.nil?
		object = ARGV.shift
		case command
			when :"--v", :"--version"
				info
			when :on, :off, :status, :list, :clear
				send command
			when :add, :remove
				require_sudo
				object.nil? && exit_error_message("'localdev #{command}' requires you to provide a domain")
				ensure_localdev_exists
				if ARGV.first.nil?
					send command, object
				else
					send command, object, ARGV.first
				end
			when nil, '--help', '-h'
				exit_message "Usage: localdev [on|off|status|list|clear]\n       localdev [add|remove] domain [ip-address]"
			else
				exit_error_message "Invalid command"
		end
	end

	def require_sudo
		if ENV["USER"] != "root"
			exec("sudo #{ENV['_']} #{ARGV.join(' ')}")
		end
	end

	def info
		puts "Localdev #{self.class::VERSION}"
	end

	def debug message
		puts message if @debugMode
	end

	def exit_message message
		puts message
		exit
	end

	def exit_error_message message
		exit_message '[ERROR] ' + message
	end

	def flush_dns
		%x{dscacheutil -flushcache}
	end

	def ensure_localdev_exists
		File.open( @localdev, 'w' ) {|file| file.write('') } unless File.exists?( @localdev )
	end

	def enable
		disable
		domains = []
		File.open( @localdev, 'r' ) do |file|
			domains = YAML::load file.read
			domains = [] unless domains.respond_to? 'each'
		end
		File.open( @hosts, 'a' ) do |file|
			file.puts "\n"
			file.puts @start
			file.puts "# The md5 dummy entries are here so that things like MAMP Pro don't"
			file.puts "# discourtiously remove our entries"
			domains.each do |domain|
				# puts domain.inspect
				file.puts "#{domain['ip']} #{Digest::MD5.hexdigest(domain['domain'])}.#{domain['domain']} #{domain['domain']}"
			end
			file.puts @end
		end
	end

	def on
		enable
		flush_dns
		puts "Turning Localdev on"
	end

	def disable
		hosts_content = []
		File.open( @hosts, 'r' ) do |file|
			started = false
			while line = file.gets
				started = true if line.include? @start
				hosts_content << line unless started
				started = false if line.include? @end
			end
		end
		while "\n" == hosts_content.last
			hosts_content.pop
		end
		File.open( @hosts, 'w' ) do |file|
			file.puts hosts_content
		end
	end

	def off
		disable
		flush_dns
		puts "Turning Localdev off"
	end

	def update_localdev
		domains = []
		File.open( @localdev, 'r' ) do |file|
			domains = YAML::load file.read
			domains = [] unless domains.respond_to? 'each'
			debug domains.inspect
			yield domains
			debug domains.inspect
		end
		File.open( @localdev, 'w' ) do |file|
			file.puts YAML::dump domains
		end
	end

	def add domain, ip='127.0.0.1'
		domain = {
			'domain' => domain,
			'ip' => ip
		}

		_remove domain['domain']
		update_localdev {|domains| domains << domain }
		enable if :on == get_status
		puts "Added #{domain['domain']} => #{domain['ip']}"
		status
	end

	def remove domain
		_remove domain
		enable if :on == get_status
		puts "Removed #{domain}"
		status
	end

	def _remove domain
		update_localdev {|domains| domains = domains.delete_if{|item| item['domain'] == domain } }
	end

	def clear
		update_localdev {|domains| domains.clear }
		enable if :on == get_status
		puts "Removed all domains"
		status
	end

	def get_status
		status = :off
		return status unless File.readable? @hosts
		File.open( @hosts, 'r' ) do |file|
			while line = file.gets
				if line.include? @start
					status = :on
					break
				end
			end
		end
		return status
	end

	def list
		File.open( @localdev, 'r' ) do |file|
			domains = YAML::load file.read
			domains.each do |domain|
				puts "#{domain['domain']} => #{domain['ip']}"
			end
		end
	end

	def status
		puts "Localdev is #{get_status}"
	end

end
