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
results = []

daily_notes.sort.each do |note_path|
  basename = File.basename(note_path, ".md")
  date = Date.parse(basename) rescue nil
  next unless date
  
  day_str = days[date.wday]
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
  
  entries.each do |entry|
    if entry.include?("#tlog")
      cleaned_entry = entry.gsub(/#tlog\s*/, "").strip
      # 縦方向に伸びないように改行をスペースに変換して圧縮
      cleaned_entry = cleaned_entry.gsub(/\r?\n/, " ")
      
      results << "- [[#{basename}#つぶやき|#{day_str}]] #{cleaned_entry}"
    end
  end
end

if results.empty?
  puts "No #tlog found."
  exit 0
end

tlog_block = results.join("\n") + "\n\n"

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
puts "Added #{results.length} tlogs to #{weekly_note_path}"
