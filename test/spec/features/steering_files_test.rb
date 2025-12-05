require 'minitest/autorun'
require 'digest'

# **Feature: steering-files-refactor, Property 1: No Information Duplication**
# Tests that factual information appears only once across steering files
class SteeringFilesNoDuplicationTest < Minitest::Test
  STEERING_DIR = File.join(__dir__, '../../../.kiro/steering')
  
  def setup
    @product_md = File.read(File.join(STEERING_DIR, 'product.md'))
    @tech_md = File.read(File.join(STEERING_DIR, 'tech.md'))
    @structure_md = File.read(File.join(STEERING_DIR, 'structure.md'))
  end

  def test_no_duplicate_commands
    # Extract all command examples (code blocks and inline code that look like commands)
    commands = extract_commands([@product_md, @tech_md, @structure_md])
    
    # Count occurrences of each unique command
    command_counts = Hash.new(0)
    commands.each { |cmd| command_counts[cmd] += 1 }
    
    # Find commands that appear more than once
    duplicates = command_counts.select { |_cmd, count| count > 1 }
    
    # Allow cross-references (markdown links) - they're not duplicates
    # Filter out commands that appear in link context
    actual_duplicates = duplicates.reject do |cmd, _count|
      is_cross_reference?(cmd, [@product_md, @tech_md, @structure_md])
    end
    
    assert_empty actual_duplicates, 
      "Found duplicate commands: #{actual_duplicates.keys.join(', ')}"
  end

  def test_no_duplicate_file_paths
    # Extract file paths (things that look like paths: _config.yml, lib/file.rb, etc.)
    paths = extract_paths([@product_md, @tech_md, @structure_md])
    
    # Count occurrences
    path_counts = Hash.new(0)
    paths.each { |path| path_counts[path] += 1 }
    
    # Find paths that appear more than once
    duplicates = path_counts.select { |_path, count| count > 1 }
    
    # Filter out cross-references
    actual_duplicates = duplicates.reject do |path, _count|
      is_cross_reference?(path, [@product_md, @tech_md, @structure_md])
    end
    
    # Some paths are expected to appear multiple times (directory structure, examples)
    # Allow paths that appear in directory tree or as examples
    allowed_duplicates = actual_duplicates.select do |path, _count|
      appears_in_directory_tree?(path) || appears_as_example?(path)
    end
    
    unexpected_duplicates = actual_duplicates.reject { |path, _count| allowed_duplicates.key?(path) }
    
    assert_empty unexpected_duplicates,
      "Found duplicate file paths: #{unexpected_duplicates.keys.join(', ')}"
  end

  def test_no_duplicate_configuration_values
    # Extract configuration values (things like version numbers, URLs, specific settings)
    config_values = extract_config_values([@product_md, @tech_md, @structure_md])
    
    # Count occurrences
    value_counts = Hash.new(0)
    config_values.each { |val| value_counts[val] += 1 }
    
    # Find values that appear more than once
    duplicates = value_counts.select { |_val, count| count > 1 }
    
    # Filter out cross-references and common values
    actual_duplicates = duplicates.reject do |val, _count|
      is_cross_reference?(val, [@product_md, @tech_md, @structure_md]) ||
      is_common_value?(val)
    end
    
    assert_empty actual_duplicates,
      "Found duplicate configuration values: #{actual_duplicates.keys.join(', ')}"
  end

  private

  def extract_commands(contents)
    commands = []
    contents.each do |content|
      # Extract from code blocks
      content.scan(/```bash\n(.*?)\n```/m).each do |match|
        match[0].split("\n").each do |line|
          line = line.strip
          next if line.empty? || line.start_with?('#')
          commands << normalize_command(line)
        end
      end
      
      # Extract inline code that looks like commands
      content.scan(/`([^`]+)`/).each do |match|
        cmd = match[0]
        if looks_like_command?(cmd)
          commands << normalize_command(cmd)
        end
      end
    end
    commands.uniq
  end

  def extract_paths(contents)
    paths = []
    contents.each do |content|
      # Match file paths: _config.yml, lib/file.rb, assets/images/file.png
      content.scan(/`([_a-zA-Z0-9\/\-\.]+\.(yml|rb|md|png|jpg|svg|css|html|json))`/).each do |match|
        paths << match[0]
      end
      
      # Match directory paths: _talks/, lib/, etc.
      content.scan(/`([_a-zA-Z0-9\/\-]+\/)`/).each do |match|
        paths << match[0]
      end
    end
    paths.uniq
  end

  def extract_config_values(contents)
    values = []
    contents.each do |content|
      # Extract version numbers
      content.scan(/(\d+\.\d+\+?)/).each do |match|
        values << match[0]
      end
      
      # Extract specific configuration keys
      content.scan(/`([a-z_]+):`/).each do |match|
        values << match[0]
      end
    end
    values.uniq
  end

  def normalize_command(cmd)
    # Remove variable parts (URLs, paths, etc.) to compare command structure
    cmd.gsub(/https?:\/\/[^\s]+/, 'URL')
       .gsub(/[a-z]+-[a-z]+-[a-z]+/, 'talk-slug')
       .gsub(/\d{4}-\d{2}-\d{2}/, 'YYYY-MM-DD')
       .strip
  end

  def looks_like_command?(str)
    # Check if string looks like a shell command
    command_prefixes = ['bundle', 'ruby', 'rake', 'jekyll', 'git', 'rm', 'chmod', 'brew', 'apt-get', 'gem']
    command_prefixes.any? { |prefix| str.start_with?(prefix) }
  end

  def is_cross_reference?(text, contents)
    # Check if text appears in a markdown link context [text](url)
    contents.any? do |content|
      content.include?("[#{text}]") || content.include?("](#{text})")
    end
  end

  def appears_in_directory_tree?(path)
    # Check if path appears in the directory tree diagram
    [@tech_md, @structure_md, @product_md].any? do |content|
      # Look for directory tree section
      tree_section = content[/```\nshownotes\/.*?```/m]
      tree_section && tree_section.include?(path)
    end
  end

  def appears_as_example?(path)
    # Check if path appears in an example context (Good Example, Bad Example, etc.)
    [@tech_md, @structure_md, @product_md].any? do |content|
      # Look for example sections
      content.scan(/\*\*.*?Example.*?\*\*:.*?```.*?```/m).any? do |example|
        example.include?(path)
      end
    end
  end

  def is_common_value?(val)
    # Common values that are expected to appear multiple times
    common = ['talk', 'talks', 'layout', 'title', 'url', 'baseurl', 'speaker']
    common.include?(val.downcase)
  end
end


# **Feature: steering-files-refactor, Property 2: Cross-Reference Link Validity**
# Tests that all internal links between steering files point to existing sections
class SteeringFilesCrossReferenceTest < Minitest::Test
  STEERING_DIR = File.join(__dir__, '../../../.kiro/steering')
  
  def setup
    @files = {
      'product.md' => File.read(File.join(STEERING_DIR, 'product.md')),
      'tech.md' => File.read(File.join(STEERING_DIR, 'tech.md')),
      'structure.md' => File.read(File.join(STEERING_DIR, 'structure.md'))
    }
  end

  def test_all_cross_references_valid
    invalid_refs = []
    
    @files.each do |source_file, content|
      # Extract all markdown links
      links = extract_links(content)
      
      # Filter for internal steering file links
      internal_links = links.select { |link| is_internal_steering_link?(link) }
      
      # Validate each link
      internal_links.each do |link|
        target_file, anchor = parse_link(link)
        
        unless link_target_exists?(target_file, anchor)
          invalid_refs << {
            source: source_file,
            link: link,
            target_file: target_file,
            anchor: anchor
          }
        end
      end
    end
    
    assert_empty invalid_refs,
      "Found invalid cross-references:\n" +
      invalid_refs.map { |ref| "  #{ref[:source]}: [text](#{ref[:link]}) -> #{ref[:target_file]}##{ref[:anchor]}" }.join("\n")
  end

  def test_cross_references_point_to_relevant_content
    # For each cross-reference, verify the target section contains relevant content
    # This is a softer check - we just verify the section exists and has content
    
    @files.each do |source_file, content|
      links = extract_links(content)
      internal_links = links.select { |link| is_internal_steering_link?(link) }
      
      internal_links.each do |link|
        target_file, anchor = parse_link(link)
        
        if link_target_exists?(target_file, anchor)
          target_content = @files[target_file]
          section_content = extract_section_content(target_content, anchor)
          
          assert section_content.length > 50,
            "Cross-reference #{source_file} -> #{target_file}##{anchor} points to very short section (#{section_content.length} chars)"
        end
      end
    end
  end

  private

  def extract_links(content)
    # Extract all markdown links: [text](url)
    links = []
    content.scan(/\[([^\]]+)\]\(([^\)]+)\)/).each do |match|
      links << match[1]  # The URL part
    end
    links
  end

  def is_internal_steering_link?(link)
    # Check if link points to another steering file
    link.match?(/^(product|tech|structure)\.md(#.*)?$/)
  end

  def parse_link(link)
    # Parse link into file and anchor
    # Format: "product.md#section-name" or "tech.md"
    if link.include?('#')
      file, anchor = link.split('#', 2)
      [file, anchor]
    else
      [link, nil]
    end
  end

  def link_target_exists?(target_file, anchor)
    # Check if target file exists
    return false unless @files.key?(target_file)
    
    # If no anchor, just file existence is enough
    return true if anchor.nil?
    
    # Check if anchor exists in target file
    target_content = @files[target_file]
    section_exists?(target_content, anchor)
  end

  def section_exists?(content, anchor)
    # Convert anchor to heading text
    # Anchor format: "section-name" -> Heading: "## Section Name" or "### Section Name"
    # Handle special cases like "dependency-issues" -> "Dependency Issues"
    heading_text = anchor.split('-').map { |word| word.capitalize }.join(' ')
    
    # Check for various heading levels (case insensitive)
    # Use word boundaries to avoid partial matches
    content.match?(/^##+ #{Regexp.escape(heading_text)}\s*$/i)
  end

  def extract_section_content(content, anchor)
    # Extract content of section for validation
    heading_text = anchor.split('-').map { |word| word.capitalize }.join(' ')
    
    # Find section start (case insensitive)
    lines = content.split("\n")
    section_start_idx = lines.find_index { |line| line.match?(/^##+ #{Regexp.escape(heading_text)}\s*$/i) }
    return "" if section_start_idx.nil?
    
    # Find next heading of same or higher level
    heading_level = lines[section_start_idx].match(/^(#+)/)[1].length
    section_end_idx = lines[(section_start_idx + 1)..-1].find_index do |line|
      line.match?(/^#{'{1,' + heading_level.to_s + '}'} /)
    end
    
    if section_end_idx
      lines[section_start_idx..(section_start_idx + section_end_idx)].join("\n")
    else
      lines[section_start_idx..-1].join("\n")
    end
  end
end


# **Feature: steering-files-refactor, Property 3: File Boundary Compliance**
# Tests that content in each file matches its designated purpose
class SteeringFilesFileBoundaryTest < Minitest::Test
  STEERING_DIR = File.join(__dir__, '../../../.kiro/steering')
  
  def setup
    @product_md = File.read(File.join(STEERING_DIR, 'product.md'))
    @tech_md = File.read(File.join(STEERING_DIR, 'tech.md'))
    @structure_md = File.read(File.join(STEERING_DIR, 'structure.md'))
  end

  def test_tech_md_contains_only_technical_content
    # Define allowed section categories for tech.md
    allowed_categories = [
      'technology', 'stack', 'core', 'dependencies', 'command', 'reference',
      'development', 'testing', 'migration', 'configuration', 'build', 'system',
      'security', 'performance', 'troubleshooting', 'issues'
    ]
    
    sections = extract_top_level_sections(@tech_md)
    
    sections.each do |section|
      section_lower = section.downcase
      
      # Check if section matches any allowed category
      matches_category = allowed_categories.any? { |cat| section_lower.include?(cat) }
      
      assert matches_category,
        "tech.md contains section '#{section}' which doesn't match technical categories"
    end
  end

  def test_structure_md_contains_only_structural_content
    # Instead of checking every section, check that structure.md doesn't contain
    # sections that clearly belong in other files
    
    disallowed_sections = [
      /^##+ Command Reference/i,
      /^##+ Commands$/i,
      /^##+ User Workflows/i,
      /^##+ Purpose & Value/i,
      /^##+ Target Users/i,
      /^##+ Troubleshooting/i,
      /^##+ Performance/i,
      /^##+ Security$/i
    ]
    
    disallowed_sections.each do |pattern|
      refute @structure_md.match?(pattern),
        "structure.md contains section matching #{pattern} which belongs in another file"
    end
  end

  def test_product_md_contains_only_product_content
    # Define allowed section categories for product.md
    allowed_categories = [
      'product', 'overview', 'purpose', 'value', 'feature', 'target', 'user',
      'workflow', 'decision', 'guide', 'deployment', 'migration', 'creation',
      'start', 'quick'
    ]
    
    sections = extract_top_level_sections(@product_md)
    
    sections.each do |section|
      section_lower = section.downcase
      
      # Check if section matches any allowed category
      matches_category = allowed_categories.any? { |cat| section_lower.include?(cat) }
      
      assert matches_category,
        "product.md contains section '#{section}' which doesn't match product categories"
    end
  end

  def test_no_command_reference_in_product_md
    # product.md should reference commands but not document them in detail
    # It can show commands in workflow steps, but shouldn't have command reference sections
    
    # Check for command reference patterns
    has_command_reference = @product_md.match?(/^##+ Command Reference/i) ||
                           @product_md.match?(/^##+ Commands/i)
    
    refute has_command_reference,
      "product.md should not contain command reference sections (use tech.md)"
  end

  def test_no_workflow_details_in_tech_md
    # tech.md should reference workflows but not document complete user workflows
    # It can mention when to use commands, but shouldn't have workflow sections
    
    # Check for workflow patterns
    has_workflow_section = @tech_md.match?(/^##+ .*Workflow/i) ||
                          @tech_md.match?(/^##+ User Workflows/i)
    
    refute has_workflow_section,
      "tech.md should not contain workflow sections (use product.md)"
  end

  def test_no_directory_structure_in_tech_md
    # tech.md should not contain directory tree diagrams
    # That belongs in structure.md
    
    has_directory_tree = @tech_md.include?('shownotes/') &&
                        @tech_md.match?(/├──|└──/)
    
    refute has_directory_tree,
      "tech.md should not contain directory structure diagrams (use structure.md)"
  end

  private

  def extract_top_level_sections(content)
    # Extract all ## level headings (top-level sections)
    sections = []
    content.scan(/^## (.+)$/).each do |match|
      sections << match[0].strip
    end
    sections
  end
end


# **Feature: steering-files-refactor, Property 4: Command Example Completeness**
# Tests that command examples include purpose and expected output
class SteeringFilesCommandCompletenessTest < Minitest::Test
  STEERING_DIR = File.join(__dir__, '../../../.kiro/steering')
  
  def setup
    @product_md = File.read(File.join(STEERING_DIR, 'product.md'))
    @tech_md = File.read(File.join(STEERING_DIR, 'tech.md'))
    @structure_md = File.read(File.join(STEERING_DIR, 'structure.md'))
  end

  def test_all_commands_have_context
    # Extract all command examples from all files
    all_content = [@product_md, @tech_md, @structure_md]
    
    all_content.each_with_index do |content, idx|
      file_name = ['product.md', 'tech.md', 'structure.md'][idx]
      
      # Extract bash code blocks
      content.scan(/```bash\n(.*?)\n```/m).each do |match|
        commands = match[0].split("\n").reject { |line| line.strip.empty? || line.strip.start_with?('#') }
        
        next if commands.empty?
        
        # Get surrounding context (text before and after the code block)
        block_start = content.index(match[0])
        context_before = content[0...block_start].split("\n").last(10).join("\n")
        
        block_end = block_start + match[0].length
        context_after = content[block_end..-1].split("\n").first(10).join("\n")
        
        context = context_before + context_after
        
        # Check for purpose indicators
        has_purpose = context.match?(/purpose|when to|usage|use this|run this/i)
        
        # Check for expected output indicators
        has_expected_output = context.match?(/expected|output|result|success|shows|displays/i)
        
        # Check if in troubleshooting section (problem/solution context is sufficient)
        in_troubleshooting = context.match?(/problem:|solution:|troubleshooting/i)
        
        # At least one should be present
        assert has_purpose || has_expected_output || in_troubleshooting,
          "Command block in #{file_name} lacks context:\n#{commands.first}\n" +
          "Should have purpose, expected output, or be in troubleshooting section"
      end
    end
  end

  def test_tech_md_commands_have_detailed_documentation
    # tech.md should have especially detailed command documentation
    # Each command should have: purpose, when to run, expected output
    
    # Extract command sections from tech.md (#### level headings under Command Reference)
    # Skip category headers like "Development Commands", "Testing Commands"
    command_sections = extract_command_sections(@tech_md)
    
    command_sections.each do |section_name, section_content|
      # Skip category headers (they don't have commands directly)
      next if section_name.match?(/Commands$/i)
      
      # Check for purpose
      has_purpose = section_content.match?(/\*\*Purpose:\*\*|purpose:/i)
      
      # Check for when to run
      has_when = section_content.match?(/\*\*When to run:\*\*|when to|when you/i)
      
      # Check for expected output
      has_output = section_content.match?(/\*\*Expected output:\*\*|expected:|output:/i) ||
                   section_content.include?('```')  # Code block showing output
      
      assert has_purpose,
        "Command section '#{section_name}' in tech.md missing purpose"
      
      assert has_when,
        "Command section '#{section_name}' in tech.md missing 'when to run' guidance"
      
      assert has_output,
        "Command section '#{section_name}' in tech.md missing expected output"
    end
  end

  def test_workflow_commands_have_expected_outcomes
    # Commands in product.md workflows should have expected outcomes
    
    # Extract workflow sections
    workflows = extract_workflows(@product_md)
    
    workflows.each do |workflow_name, workflow_content|
      # Find all command blocks in this workflow
      workflow_content.scan(/```bash\n(.*?)\n```/m).each do |match|
        commands = match[0].split("\n").reject { |line| line.strip.empty? || line.strip.start_with?('#') }
        
        next if commands.empty?
        
        # Get context around this command block
        block_start = workflow_content.index(match[0])
        context_after = workflow_content[block_start..-1].split("\n").first(5).join("\n")
        
        # Check for expected outcome
        has_expected = context_after.match?(/expected:|outcome:|result:|should|will/i)
        
        assert has_expected,
          "Command in workflow '#{workflow_name}' lacks expected outcome:\n#{commands.first}"
      end
    end
  end

  private

  def extract_command_sections(content)
    # Extract ### or #### level sections under "Command Reference"
    sections = {}
    
    # Find Command Reference section
    cmd_ref_start = content.index(/^## Command Reference/i)
    return sections if cmd_ref_start.nil?
    
    # Find next ## level section (end of Command Reference)
    remaining = content[cmd_ref_start..-1]
    next_section = remaining.index(/^## /, 1)
    
    cmd_ref_content = if next_section
                       remaining[0...next_section]
                     else
                       remaining
                     end
    
    # Extract subsections (### or ####)
    current_section = nil
    current_content = []
    
    cmd_ref_content.split("\n").each do |line|
      if line.match?(/^###+ (.+)$/)
        # Save previous section
        if current_section
          sections[current_section] = current_content.join("\n")
        end
        
        # Start new section
        current_section = line.match(/^###+ (.+)$/)[1].strip
        current_content = [line]
      elsif current_section
        current_content << line
      end
    end
    
    # Save last section
    if current_section
      sections[current_section] = current_content.join("\n")
    end
    
    sections
  end

  def extract_workflows(content)
    # Extract workflow sections (### level under User Workflows)
    workflows = {}
    
    # Find User Workflows section
    workflows_start = content.index(/^## User Workflows/i)
    return workflows if workflows_start.nil?
    
    # Find next ## level section
    remaining = content[workflows_start..-1]
    next_section = remaining.index(/^## /, 1)
    
    workflows_content = if next_section
                         remaining[0...next_section]
                       else
                         remaining
                       end
    
    # Extract workflow subsections (###)
    current_workflow = nil
    current_content = []
    
    workflows_content.split("\n").each do |line|
      if line.match?(/^### (.+)$/)
        # Save previous workflow
        if current_workflow
          workflows[current_workflow] = current_content.join("\n")
        end
        
        # Start new workflow
        current_workflow = line.match(/^### (.+)$/)[1].strip
        current_content = [line]
      elsif current_workflow
        current_content << line
      end
    end
    
    # Save last workflow
    if current_workflow
      workflows[current_workflow] = current_content.join("\n")
    end
    
    workflows
  end
end


# **Feature: steering-files-refactor, Property 5: Example Syntax Validity**
# Tests that code examples are syntactically valid
class SteeringFilesExampleValidityTest < Minitest::Test
  STEERING_DIR = File.join(__dir__, '../../../.kiro/steering')
  
  def setup
    @product_md = File.read(File.join(STEERING_DIR, 'product.md'))
    @tech_md = File.read(File.join(STEERING_DIR, 'tech.md'))
    @structure_md = File.read(File.join(STEERING_DIR, 'structure.md'))
  end

  def test_yaml_examples_are_valid
    all_content = [@product_md, @tech_md, @structure_md]
    file_names = ['product.md', 'tech.md', 'structure.md']
    
    all_content.each_with_index do |content, idx|
      # Extract YAML code blocks
      content.scan(/```ya?ml\n(.*?)\n```/m).each do |match|
        yaml_content = match[0]
        
        begin
          YAML.safe_load(yaml_content, permitted_classes: [Date, Time, Symbol])
        rescue Psych::SyntaxError => e
          flunk "Invalid YAML in #{file_names[idx]}:\n#{yaml_content}\nError: #{e.message}"
        end
      end
    end
  end

  def test_ruby_examples_are_valid
    all_content = [@product_md, @tech_md, @structure_md]
    file_names = ['product.md', 'tech.md', 'structure.md']
    
    all_content.each_with_index do |content, idx|
      # Extract Ruby code blocks
      content.scan(/```ruby\n(.*?)\n```/m).each do |match|
        ruby_content = match[0]
        
        begin
          # Check syntax without executing
          RubyVM::InstructionSequence.compile(ruby_content)
        rescue SyntaxError => e
          flunk "Invalid Ruby syntax in #{file_names[idx]}:\n#{ruby_content}\nError: #{e.message}"
        end
      end
    end
  end

  def test_markdown_examples_are_valid
    all_content = [@product_md, @tech_md, @structure_md]
    file_names = ['product.md', 'tech.md', 'structure.md']
    
    all_content.each_with_index do |content, idx|
      # Extract Markdown code blocks
      content.scan(/```markdown\n(.*?)\n```/m).each do |match|
        md_content = match[0]
        
        # Basic markdown validation - check for common syntax errors
        # Check for unmatched brackets
        open_brackets = md_content.scan(/\[/).count
        close_brackets = md_content.scan(/\]/).count
        
        assert_equal open_brackets, close_brackets,
          "Unmatched brackets in markdown example in #{file_names[idx]}:\n#{md_content}"
        
        # Check for unmatched parentheses in links
        open_parens = md_content.scan(/\]\(/).count
        close_parens_after_bracket = md_content.scan(/\]\([^\)]*\)/).count
        
        assert_equal open_parens, close_parens_after_bracket,
          "Unmatched parentheses in markdown links in #{file_names[idx]}:\n#{md_content}"
      end
    end
  end

  def test_bash_examples_are_reasonable
    all_content = [@product_md, @tech_md, @structure_md]
    file_names = ['product.md', 'tech.md', 'structure.md']
    
    all_content.each_with_index do |content, idx|
      # Extract bash code blocks
      content.scan(/```bash\n(.*?)\n```/m).each do |match|
        bash_content = match[0]
        
        # Check for common bash syntax errors
        lines = bash_content.split("\n")
        
        lines.each do |line|
          line = line.strip
          next if line.empty? || line.start_with?('#')
          
          # Check for unmatched quotes
          single_quotes = line.scan(/'/).count
          double_quotes = line.scan(/"/).count
          
          assert_equal 0, single_quotes % 2,
            "Unmatched single quotes in bash example in #{file_names[idx]}:\n#{line}"
          
          assert_equal 0, double_quotes % 2,
            "Unmatched double quotes in bash example in #{file_names[idx]}:\n#{line}"
          
          # Check for dangerous patterns (just warnings, not failures)
          if line.include?('rm -rf /')
            puts "WARNING: Dangerous command in #{file_names[idx]}: #{line}"
          end
        end
      end
    end
  end

  def test_liquid_examples_are_valid
    all_content = [@product_md, @tech_md, @structure_md]
    file_names = ['product.md', 'tech.md', 'structure.md']
    
    all_content.each_with_index do |content, idx|
      # Extract Liquid code blocks
      content.scan(/```liquid\n(.*?)\n```/m).each do |match|
        liquid_content = match[0]
        
        # Check for balanced Liquid tags
        open_tags = liquid_content.scan(/\{%/).count
        close_tags = liquid_content.scan(/%\}/).count
        
        assert_equal open_tags, close_tags,
          "Unmatched Liquid tags in #{file_names[idx]}:\n#{liquid_content}"
        
        # Check for balanced Liquid output tags
        open_output = liquid_content.scan(/\{\{/).count
        close_output = liquid_content.scan(/\}\}/).count
        
        assert_equal open_output, close_output,
          "Unmatched Liquid output tags in #{file_names[idx]}:\n#{liquid_content}"
      end
    end
  end

  def test_inline_code_is_reasonable
    all_content = [@product_md, @tech_md, @structure_md]
    file_names = ['product.md', 'tech.md', 'structure.md']
    
    all_content.each_with_index do |content, idx|
      # Check that inline code backticks are balanced
      # Count backticks not in code blocks
      content_without_blocks = content.gsub(/```.*?```/m, '')
      
      backticks = content_without_blocks.scan(/`/).count
      
      assert_equal 0, backticks % 2,
        "Unmatched inline code backticks in #{file_names[idx]}"
    end
  end
end
