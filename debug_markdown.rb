require 'kramdown'

content = <<~MARKDOWN
## Talk Abstract

This is a test talk about **important topics**.

### Key Points

- First point
- Second point with [link](https://example.com)

Code example:

    function example() {
      return "Hello World";
    }

Special characters: <script>alert('xss')</script>
MARKDOWN

puts "Input:"
puts content
puts "\nOutput:"

doc = Kramdown::Document.new(content, {
  syntax_highlighter: 'rouge',
  syntax_highlighter_opts: {
    css_class: 'highlight'  
  },
  auto_ids: false,
  parse_block_html: true,
  coderay_line_numbers: nil
})
html = doc.to_html

puts html