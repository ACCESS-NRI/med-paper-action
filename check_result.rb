paper_md_path = ARGV[0].to_s
formats = ARGV[1].to_s.downcase.split(",")

# Check for generated files presence
if paper_md_path.empty?
  raise "   !! ERROR: The paper path is empty"
else
  paper_pdf_path = File.dirname(paper_md_path)+"/paper.pdf"
  if File.exist?(paper_pdf_path)
    system("echo 'paper_pdf_path=#{paper_pdf_path}' >> $GITHUB_OUTPUT")
    system("echo 'Success! PDF file generated at: #{paper_pdf_path}'")
  else
    system("echo 'CUSTOM_ERROR=Failed to generate PDF file.' >> $GITHUB_ENV")
    raise "   !! ERROR: Failed to generate PDF file" if formats.include?("pdf")
  end
end
