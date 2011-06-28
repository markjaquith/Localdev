#!/usr/bin/env ruby
require 'digest/md5'
class Localdev
	def initialize
		@debug = false
		@localdev = '/etc/hosts-localdev'
		@hosts = '/etc/hosts'
		@start = '#==LOCALDEV==#'
		@end = '#/==LOCALDEV==#'
		command = ARGV.shift
		command = command.to_sym unless command.nil?
		object = ARGV.shift
		case command
			when :on, :off, :status
				self.send command
			when :add, :remove
				object.nil? && self.exit_error_message("'localdev #{command}' requires you to provide a domain")
				File.open( @localdev, 'w' ) {|file| file.write('') } unless File.exists?( @localdev )
				self.send command, object
			when nil, '--help', '-h'
				self.exit_message "Usage: localdev [on|off|status]\n       localdev [add|remove] domain"
			else
				self.exit_error_message "Invalid command"
		end
	end

	def debug message
		puts message if @debug
	end

	def exit_message message
		puts message
		exit
	end

	def exit_error_message message
		self.exit_message '[ERROR] ' + message
	end

	def flush_dns
		%x{dscacheutil -flushcache}
	end

	def do_on
		self.do_off
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
		self.do_on
		self.flush_dns
		puts "Turning Localdev on"
	end

	def do_off
		hosts_content = []
		File.open( @hosts, 'r' ) do |file|
			started = false
			while line = file.gets
				started = true if line.include? @start
				hosts_content << line unless started
				started = false if line.include? @end
			end
			# debug hosts_content.join("")
		end
		while "\n" == hosts_content.last
			hosts_content.pop
		end
		File.open( @hosts, 'w' ) do |file|
			file.puts hosts_content
		end
	end

	def off
		self.do_off
		self.flush_dns
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

	def update_hosts
	end

	def add domain
		self.update_localdev {|domains| domains << domain unless domains.include? domain }
		self.do_on if :on == self.get_status
		puts "Added '#{domain}'"
		self.status
	end

	def remove domain
		self.update_localdev {|domains| domains = domains.delete domain }
		self.do_on if :on == self.get_status
		puts "Removed '#{domain}'"
		self.status
	end

	def get_status
		# do magic
		status = :off
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
		puts "Localdev is #{self.get_status}"
	end

end

Localdev.new
