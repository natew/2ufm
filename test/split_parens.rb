strings = [
  "test",
  "test two",
  "three (in)",
  "four (in) out",
  "five (in) out (in)",
  "six (in) out out out (in)",
  "(in)",
  "eight [in in] out [in] out (in)"
]

def split_parens(string, in_parens=false)
  open_parens = /\(\[/
  close_parens = /\)\]/
  match_parens = /#{open_parens}\d+#{close_parens}/
  return [string, in_parens] unless string =~ open_parens
end

strings.each do |string|
  puts split_parens(string).to_s
end