require "ostruct"
require "time"
require "fileutils"
require "exif"

module PhotoOrganizer
	extend self

	attr_accessor :target_dir, :out_dir

	def run
		info "Organizing #{files.count} files ..."

		puts ""

		progress = 0
		print "#{progress}/#{files.count}"

		files.each do |f|
			copy_file(f)

			progress += 1
			print "\r#{progress}/#{files.count}"
		end

		puts "\n\n"
		info "Organizing complete"
	end

	private

	def copy_file(f)
		FileUtils.mkdir_p(out_dir)
		FileUtils.mkdir_p("#{out_dir}/#{f.year}/#{f.month}")
		FileUtils.mkdir_p("#{out_dir}/#{f.year}/#{f.month}")

		name = File.basename(f.name)
		out = "#{out_dir}/#{f.year}/#{f.month}/#{name}"

		FileUtils.cp(f.name, out)
	end

	def files
		@files ||= Dir.chdir(target_dir) do
			Dir
				.glob("**/*")
				.map {|path| File.expand_path(path) }
				.reject {|f| File.directory?(f) }
				.map do |f|
					data = Exif::Data.new(File.open(f))

					FileData.new(f, data.date_time)
				rescue Exif::NotReadable
					# Not an image/video file
					# Or the EXIF data has been stripped, can't do anything either way
					warn "Skipping file #{f} - could not read EXIF metadata"
					nil
				end
				.compact
		end
	end

	def warn(msg)
		log("WARNING:", :brown, msg)
	end

	def info(msg)
		log("INFO:", :blue, msg)
	end

	def log(level, color, msg)
		puts "#{level.underline.bold.public_send(color)} #{msg}"
	end

	class FileData
		attr_reader :name, :year, :month

		def initialize(file_name, date_time)
			date_parts = date_time.split(" ").first.split(":")

			@name = file_name
			@year = date_parts[0]
			@month = date_parts[1]
		end
	end
end

class String
	def brown;          "\e[33m#{self}\e[0m" end
	def blue;           "\e[34m#{self}\e[0m" end

	def bold;           "\e[1m#{self}\e[22m" end
	def underline;      "\e[4m#{self}\e[24m" end
end
