#!/usr/bin/env ruby
# -*- Mode: Ruby; -*-

### Bootstrap ruby libs

STDOUT.sync = true
STDERR.sync = true

prev = start = Time.now.to_f

STDIN.each_line{|line|
  now = Time.now.to_f
  total_elapsed = now - start
  delta = now - prev
  prev = now
  puts sprintf("[line_elapsed=%7.2f] [tot_elapsed=%7.2f] |> %s", delta, total_elapsed, line)
}
exit 0
