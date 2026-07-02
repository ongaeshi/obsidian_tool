OBSIDIAN_CLI="obsidian.com"

arg = ARGV.join(" ")
time = Time.now.strftime("%H:%M")
text = <<EOS
---
#{time} #{arg}
EOS

system("#{OBSIDIAN_CLI} daily:append content=\"#{text}\"");