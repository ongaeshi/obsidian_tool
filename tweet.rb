require 'readline'
require 'open3'
require 'tempfile'

OBSIDIAN_CLI="obsidian.com"

def post_to_obsidian(arg)
  time = Time.now.strftime("%H:%M")
  text = <<EOS
---
#{time} #{arg}
EOS

  Tempfile.open('obsidian_out') do |f|
    success = system(OBSIDIAN_CLI, "daily:append", "content=#{text}", out: f.path, err: [:child, :out])
    if success
      # puts ">> 追記しました: #{arg}"
    else
      puts "エラーが発生しました:"
      f.rewind
      puts f.read
    end
  end
end

begin
  if ARGV.empty?
    puts "--- Obsidian 追記モード (Ctrl+D または exit で終了) ---"

    # 第二引数を true にすると自動で履歴(HISTORY)に蓄積される
    while line = Readline.readline("> ", true)
      break if line.downcase == "exit"
      next if line.strip.empty?

      post_to_obsidian(line)
    end
  else
    post_to_obsidian(ARGV.join(" "))
  end
rescue Interrupt
  puts "\n終了します。"
  exit 0
end