require "theoj"
require "yaml"

issue_id = ENV["ISSUE_ID"]
repo_url = ENV["REPO_URL"]
repo_branch = ENV["PAPER_BRANCH"]
acceptance = ENV["COMPILE_MODE"] == "accepted"

# I must override the journal otherwise it looks in the wrong repo for the issue.
journal_data = {
  doi_prefix: "10.21105",
  url: "https://medportal-dev-6a745f452687.herokuapp.com/",
  name: "ACCESS-NRI MedPortal",
  alias: "medportal",
  launch_date: "2023-08-14",
  papers_repository: "ACCESS-NRI/med-recipes",
  reviews_repository: "ACCESS-NRI/med-reviews",
  deposit_url: "https://medportal-dev-6a745f452687.herokuapp.com/papers/api_deposit",
  retract_url: "https://medportal-dev-6a745f452687.herokuapp.com/papers/api_retract"
}

# I must overwrite self.find_paper_path so it finds jupyter notebooks, not markdown files.
class NewPaper < Theoj::Paper
  def self.find_paper_path(search_path)
    paper_path = nil

    if Dir.exist? search_path
      Find.find(search_path).each do |path|
        if path =~ /paper\.ipynb$/
          paper_path = path
          break
        end
      end
    end

    paper_path
  end

  private

    def find_paper(path)
      if path.to_s.strip.empty?
        setup_local_repo
        @paper_path = NewPaper.find_paper_path(local_path)
      else
        @paper_path = path
      end
    end

end


journal = Theoj::Journal.new(journal_data)
issue = Theoj::ReviewIssue.new(journal.data[:reviews_repository], issue_id)
issue.paper = NewPaper.from_repo(repo_url, repo_branch)

submission = Theoj::Submission.new(journal, issue, issue.paper)

paper_path = issue.paper.paper_path
system("echo 'paper_path=#{paper_path}.' >> $GITHUB_ENV")

if paper_path.nil?
  system("echo 'CUSTOM_ERROR=Paper file not found.' >> $GITHUB_ENV")
  raise "   !! ERROR: Paper file not found"
else
  system("echo 'paper_file_path=#{paper_path}' >> $GITHUB_OUTPUT")
end

metadata = submission.article_metadata
if acceptance && metadata[:published_at].to_s.strip.empty?
  metadata[:published_at] = Time.now.strftime("%Y-%m-%d")
end

metadata[:submitted_at] = "0000-00-00" if metadata[:submitted_at].to_s.strip.empty?
metadata[:published_at] = "0000-00-00" if metadata[:published_at].to_s.strip.empty?

metadata[:editor].transform_keys!(&:to_s)
metadata[:authors].each {|author| author.transform_keys!(&:to_s) }
metadata.transform_keys!(&:to_s)

metadata_file_path = File.dirname(paper_path)+"/paper-metadata.yaml"

File.open(metadata_file_path, "w") do |f|
  f.write metadata.to_yaml
end

if File.exist?(metadata_file_path)
  title = metadata["title"]
  system("echo 'paper_title=#{title}' >> $GITHUB_OUTPUT")
  system("echo 'Metadata created for paper: #{title}'")
else
  system("echo 'CUSTOM_ERROR=Paper metadata file could not be generated.' >> $GITHUB_ENV")
  raise "   !! ERROR: Paper metadata file could not be generated"
end

inara_args = "-m #{metadata_file_path} -l -o pdf,crossref,jats"
inara_args += ",cff -p" if acceptance

system("echo 'inara_args=#{inara_args}' >> $GITHUB_OUTPUT")

track = submission.track
track_name = track[:parameterized] || journal_alias
system("echo 'track_name=#{track_name}' >> $GITHUB_OUTPUT")
