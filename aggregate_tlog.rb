require 'date'

if ARGV.length != 1
  puts "Usage: ruby aggregate_tlog.rb <path_to_weekly_note>"
  exit 1
end

weekly_note_path = ARGV[0]
unless File.exist?(weekly_note_path)
  puts "Error: File not found - #{weekly_note_path}"
  exit 1
end

dir = File.dirname(weekly_note_path).gsub('\\', '/')
daily_notes = Dir.glob(File.join(dir, "*.md")).select do |f|
  File.basename(f) =~ /^\d{4}-\d{2}-\d{2}\.md$/
end

days = %w(日 月 火 水 木 金 土)
results_by_date = {}

daily_notes.sort.each do |note_path|
  basename = File.basename(note_path, ".md")
  date = Date.parse(basename) rescue nil
  next unless date
  
  day_str = "#{date.month}/#{date.day}(#{days[date.wday]})"
  content = File.read(note_path, encoding: 'bom|utf-8')
  
  in_tsubuyaki = false
  tsubuyaki_text = ""
  
  content.each_line do |line|
    if line =~ /^\#{1,2}\s+つぶやき\s*$/
      in_tsubuyaki = true
      next
    elsif in_tsubuyaki && line =~ /^\#+\s+/
      in_tsubuyaki = false
      break
    end
    
    tsubuyaki_text << line if in_tsubuyaki
  end
  
  entries = tsubuyaki_text.split(/^---+$/)
  day_results = []
  
  entries.each do |entry|
    if entry.include?("#tlog")
      cleaned_entry = entry.gsub(/#tlog\s*/, "")
      # 行頭にあるかもしれない時刻(例: "- 12:34" や "12:34")を削除
      cleaned_entry = cleaned_entry.sub(/^\s*[-*]?\s*\[?\d{1,2}:\d{2}\]?\s*/, "")
      cleaned_entry = cleaned_entry.strip
      
      day_results << cleaned_entry unless cleaned_entry.empty?
    end
  end
  
  unless day_results.empty?
    results_by_date[[basename, day_str]] = day_results
  end
end

if results_by_date.empty?
  puts "No #tlog found."
  exit 0
end

tlog_block = "## tlog\n\n"
results_by_date.each do |(basename, day_str), entries|
  tlog_block << "- [[#{basename}#つぶやき|#{day_str}]]\n"
  entries.each do |entry|
    lines = entry.lines.map(&:rstrip)
    if lines.any?
      tlog_block << "  - #{lines.first}\n"
      lines[1..-1].each do |line|
        if line.empty?
          tlog_block << "\n"
        else
          tlog_block << "    #{line}\n"
        end
      end
    end
  end
end
tlog_block << "\n"

weekly_content = File.read(weekly_note_path, encoding: 'bom|utf-8')
lines = weekly_content.lines
new_lines = []
inserted = false

# フロントマターをスキップして挿入
if !lines.empty? && lines.first.chomp == "---"
  new_lines << lines.shift
  while (line = lines.shift)
    new_lines << line
    if line.chomp == "---"
      new_lines << "\n" + tlog_block
      inserted = true
      break
    end
  end
end

unless inserted
  new_lines.unshift(tlog_block)
end

new_lines.concat(lines)

File.write(weekly_note_path, new_lines.join, encoding: 'UTF-8')
total_tlogs = results_by_date.values.map(&:size).sum
puts "Added #{total_tlogs} tlogs to #{weekly_note_path}"
