# frozen_string_literal: true

require_relative 'spec_helper'
require 'stringio'

describe Kramdown::AsciiDoc do
  describe '#convert' do
    it 'converts Markdown string to AsciiDoc string' do
      input = <<~END
      ---
      title: Document Title
      ---

      Body content.
      END

      expected = <<~END
      = Document Title

      Body content.
      END

      (expect subject.convert input).to eql expected
    end

    it 'converts Markdown IO to AsciiDoc string' do
      input = <<~END.encode 'ISO-8859-1'
      ---
      title: Document Title
      ---

      Très bien.
      END

      expected = <<~END
      = Document Title

      Très bien.
      END

      (expect subject.convert StringIO.new input).to eql expected
    end

    it 'encodes Markdown source to UTF-8' do
      input = %(bien s\u00fbr !).encode Encoding::ISO_8859_1
      output = subject.convert input
      (expect output.encoding).to eql Encoding::UTF_8
      (expect output).to eql %(bien s\u00fbr !\n)
    end

    it 'converts CRLF newlines in Markdown source to LF newlines' do
      input = %(\r\n\r\none\r\ntwo\r\nthree\r\n)
      output = subject.convert input
      (expect output.encoding).to eql Encoding::UTF_8
      (expect output).to eql %(one\ntwo\nthree\n)
    end

    it 'converts CR newlines in Markdown source to LF newlines' do
      input = %(\r\rone\rtwo\rthree\r)
      output = subject.convert input
      (expect output.encoding).to eql Encoding::UTF_8
      (expect output).to eql %(one\ntwo\nthree\n)
    end

    it 'writes AsciiDoc to string path specified by :to option' do
      the_output_file = output_file 'convert-to-string-path.adoc'
      (expect subject.convert 'Converted using the API', to: the_output_file).to be_nil
      (expect (File.read the_output_file)).to eql %(Converted using the API\n)
    end

    it 'creates intermediary directories when writing to string path specified by :to option' do
      the_output_file = output_file 'path/to/convert-to-string-path.adoc'
      the_output_dir = (Pathname.new the_output_file).dirname
      (expect subject.convert 'Converted using the API', to: the_output_file).to be_nil
      (expect the_output_dir).to exist
    end

    it 'writes AsciiDoc to pathname specified by :to option' do
      the_output_file = Pathname.new output_file 'convert-to-pathname.adoc'
      (expect subject.convert 'Converted using the API', to: the_output_file).to be_nil
      (expect the_output_file.read).to eql %(Converted using the API\n)
    end

    it 'creates intermediary directories when writing to pathname specified by :to option' do
      the_output_file = Pathname.new output_file 'path/to/convert-to-pathname.adoc'
      (expect subject.convert 'Converted using the API', to: the_output_file).to be_nil
      (expect the_output_file.dirname).to exist
    end

    it 'writes AsciiDoc to IO object specified by :to option' do
      expect do
        (expect subject.convert 'text', to: $stdout).to be_nil
      end.to (output %(text\n)).to_stdout
    end

    it 'does not mutate options argument' do
      the_output_file = Pathname.new output_file 'convert-with-options.adoc'
      opts = { encode: true, to: the_output_file, attributes: {} }
      hash = opts.hash
      (expect subject.convert '**File > Save**', opts).to be_nil
      (expect the_output_file.read).to eql %(:experimental:\n\nmenu:File[Save]\n)
      (expect opts.hash).to eql hash
    end

    it 'removes whitespace in front of leading XML comment' do
      input = <<~END
       <!--
      A legal statement

      ...of some sort
      -->
      # Document Title
      END

      expected = <<~END
      ////
      A legal statement

      ...of some sort
      ////
      = Document Title
      END
      (expect subject.convert input).to eql expected
    end

    it 'adds line feed (EOL) to end of output document if non-empty' do
      (expect subject.convert 'paragraph').to end_with ?\n
    end

    it 'does not add line feed (EOL) to end of output document if empty' do
      (expect subject.convert '').to be_empty
    end

    it 'duplicates value of :attributes option' do
      input = <<~END
      # Document Title

      # Part 1

      ## Chapter A

      so it begins
      END

      expected = <<~END
      = Document Title
      :doctype: book

      = Part 1

      == Chapter A

      so it begins
      END

      (expect subject.convert input, attributes: (attributes = {})).to eql expected
      (expect attributes).to be_empty
    end

    it 'applies preprocessors specified by :preprocessors option' do
      input = <<~END
      # Document Title
      END

      expected = <<~END
      = You Have Been Replaced!
      END

      preprocessors = [-> _markdown, _attributes { '# You Have Been Replaced!' }]
      (expect subject.convert input, preprocessors: preprocessors).to eql expected
    end

    it 'does not apply preprocessors if :preprocessors option is falsy' do
      input = <<~END
      ---
      front: matter
      ---
      END

      (expect subject.convert input, preprocessors: nil).to start_with %(''')
    end
  end

  describe '#convert_file' do
    let(:source) { 'Markdown was *here*, but it has become **AsciiDoc**!' }
    let(:expected_output) { %(Markdown was _here_, but it has become *AsciiDoc*!\n) }
    let!(:the_source_file) { (output_file %(convert-file-api-#{object_id}.md)).tap {|file| File.write file, source } }

    it 'converts Markdown file to AsciiDoc file' do
      the_output_file = output_file %(convert-file-api-#{object_id}.adoc)
      (expect subject.convert_file the_source_file).to be_nil
      (expect Pathname.new the_output_file).to exist
      (expect (File.read the_output_file)).to eql expected_output
    end

    it 'converts Markdown file object to AsciiDoc file' do
      the_output_file = output_file %(convert-file-api-#{object_id}.adoc)
      File.open the_source_file do |the_source_file_object|
        (expect subject.convert_file the_source_file_object).to be_nil
        (expect Pathname.new the_output_file).to exist
        (expect (File.read the_output_file)).to eql expected_output
      end
    end

    it 'writes output file to string path specified by :to option' do
      the_output_file = output_file 'convert-file-to-string-path.adoc'
      (expect subject.convert_file the_source_file, to: the_output_file).to be_nil
      (expect (File.read the_output_file)).to eql expected_output
    end

    it 'creates intermediary directories when writing to string path specified by :to option' do
      the_output_file = output_file 'path/to/convert-file-to-string-path.adoc'
      the_output_dir = (Pathname.new the_output_file).dirname
      (expect subject.convert_file the_source_file, to: the_output_file).to be_nil
      (expect the_output_dir).to exist
    end

    it 'writes output file to pathname specified by :to option' do
      the_output_file = Pathname.new output_file 'convert-file-to-pathname.adoc'
      (expect subject.convert_file the_source_file, to: the_output_file).to be_nil
      (expect (the_output_file.read)).to eql expected_output
    end

    it 'creates intermediary directories when writing to pathname specified by :to option' do
      the_output_file = Pathname.new output_file 'path/to/convert-file-to-pathname.adoc'
      (expect subject.convert_file the_source_file, to: the_output_file).to be_nil
      (expect the_output_file.dirname).to exist
    end

    it 'returns output as string if value of :to option is falsy' do
      (expect subject.convert_file the_source_file, to: nil).to eql expected_output
    end

    it 'writes output to IO object specified by :to option' do
      output_sink = StringIO.new
      (expect subject.convert_file the_source_file, to: output_sink).to be_nil
      (expect output_sink.string).to eql expected_output
    end

    it 'writes output file as UTF-8 regardless of default external encoding' do
      source = %(tr\u00e8s bien !)
      the_output_file = output_file 'force-encoding.adoc'
      script_file = output_file 'force-encoding.rb'
      File.write script_file, <<~END
      require 'kramdown-asciidoc'
      Kramdoc.convert '#{source}', to: '#{the_output_file}'
      END
      # NOTE internal encoding must also be set for test to work on JRuby
      %x(#{ruby} -E ISO-8859-1:ISO-8859-1 #{Shellwords.escape script_file})
      (expect File.read the_output_file, mode: 'r:UTF-8').to eql %(#{source}\n)
    end

    it 'does not mutate options argument' do
      another_source_file = Pathname.new output_file 'convert-file-with-options.md'
      another_source_file.write '**File > Save**'
      the_output_file = Pathname.new output_file 'convert-file-with-options.adoc'
      opts = { to: the_output_file, attributes: {} }
      hash = opts.hash
      (expect subject.convert_file another_source_file, opts).to be_nil
      (expect the_output_file.read).to eql %(:experimental:\n\nmenu:File[Save]\n)
      (expect opts.hash).to eql hash
    end

    it 'passes result through postprocess callback if given' do
      the_output_file = output_file %(convert-file-api-#{object_id}.adoc)
      postprocess = -> asciidoc { asciidoc.gsub 'become', 'become glorious' }
      (expect subject.convert_file the_source_file, postprocess: postprocess).to be_nil
      (expect Pathname.new the_output_file).to exist
      (expect (File.read the_output_file)).to eql %(Markdown was _here_, but it has become glorious *AsciiDoc*!\n)
    end

    it 'passes krawdown document to postprocess method if arity is not 1' do
      the_output_file = output_file %(convert-file-api-#{object_id}.adoc)
      postprocess = -> asciidoc, kramdown_doc { asciidoc.gsub 'Markdown', kramdown_doc.options[:input] }
      (expect subject.convert_file the_source_file, postprocess: postprocess).to be_nil
      (expect Pathname.new the_output_file).to exist
      (expect (File.read the_output_file)).to eql %(GFM was _here_, but it has become *AsciiDoc*!\n)
    end

    it 'uses original source if postprocess callback returns falsy' do
      the_output_file = output_file %(convert-file-api-#{object_id}.adoc)
      postprocess = -> _asciidoc {}
      (expect subject.convert_file the_source_file, postprocess: postprocess).to be_nil
      (expect Pathname.new the_output_file).to exist
      (expect (File.read the_output_file)).to eql %(Markdown was _here_, but it has become *AsciiDoc*!\n)
    end

    it 'passes result through all postprocessors if list of callbacks is given' do
      the_output_file = output_file %(convert-file-api-#{object_id}.adoc)
      postprocess_1 = -> asciidoc { asciidoc.sub 'become', 'become glorious' }
      postprocess_2 = -> asciidoc { asciidoc.sub 'glorious', 'marvelous' }
      (expect subject.convert_file the_source_file, postprocessors: [postprocess_1, postprocess_2]).to be_nil
      (expect Pathname.new the_output_file).to exist
      (expect (File.read the_output_file)).to eql %(Markdown was _here_, but it has become marvelous *AsciiDoc*!\n)
    end
  end

  describe Kramdoc do
    it 'supports Kramdoc as an alias for Kramdown::AsciiDoc' do
      (expect described_class).to eql Kramdown::AsciiDoc
    end

    it 'can be required using the alias kramdoc' do
      require 'kramdoc'
    end
  end
end
