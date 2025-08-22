require_relative 'lib/simple_talk_renderer'

renderer = SimpleTalkRenderer.new
talk = {
  'title' => 'Test Talk',
  'speaker' => 'Test Speaker', 
  'conference' => 'Test Conference',
  'date' => '2024-03-15',
  'status' => 'completed'
  # No description to test default
}

html = renderer.generate_talk_page(talk)
puts "=== Generated HTML ==="
puts html[0..2000]  # First 2000 chars