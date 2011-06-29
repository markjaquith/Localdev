#
# Localdev - Hosts file tool for local development
#
# Copyright 2011 by Mark Jaquith
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

class Localdev
	VERSION = '0.3'

	def initialize
		@debug = false
		@localdev = '/etc/hosts-localdev'
		@hosts = '/etc/hosts'
		@start = '#==LOCALDEV==#'
		@end = '#/==LOCALDEV==#'
		require_sudo if !ARGV.first.nil? && [:on, :off, :add, :remove].include?( ARGV.first.to_sym )
		command = ARGV.shift
		command = command.to_sym unless command.nil?
		object = ARGV.shift
		case command
			when :"--v", :"--version"
				info
			when :on, :off, :status
				send command
			when :add, :remove
				require_sudo
				object.nil? && exit_error_message("'localdev #{command}' requires you to provide a domain")
				File.open( @localdev, 'w' ) {|file| file.write('') } unless File.exists?( @localdev )
				send command, object
			when nil, '--help', '-h'
				exit_message "Usage: localdev [on|off|status]\n       localdev [add|remove] domain"
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
		puts message if @debug
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

	def enable
		disable
		domains = []
		File.open( @localdev, 'r' ) do |file|
			domains = file.read.split("\n").uniq
		end
		File.open( @hosts, 'a' ) do |file|
			file.puts "\n"
			file.puts @start
			file.puts "# The md5 dummy entries are here so that things like MAMP Pro don't"
			file.puts "# discourtiously remove our entries"
			domains.each do |domain|
				file.puts "127.0.0.1 #{Digest::MD5.hexdigest(domain)}.#{domain} #{domain}"
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
			domains = file.read.split("\n")
			debug domains.inspect
			yield domains
			debug domains.inspect
		end
		File.open( @localdev, 'w' ) do |file|
			file.puts domains
		end
	end

	def add domain
		update_localdev {|domains| domains << domain unless domains.include? domain }
		enable if :on == get_status
		puts "Added '#{domain}'"
		status
	end

	def remove domain
		update_localdev {|domains| domains = domains.delete domain }
		enable if :on == get_status
		puts "Removed '#{domain}'"
		status
	end

	def get_status
		# do magic
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

	def status
		puts "Localdev is #{get_status}"
	end

end
