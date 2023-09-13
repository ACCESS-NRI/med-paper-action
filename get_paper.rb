require "open3"
require "fileutils"
require "securerandom"

# This entire page is taken from the theoj repository.

def clone_repo(url, local_path)
  url = URI.extract(url.to_s).first
  return false if url.nil?

  FileUtils.mkdir_p(local_path)
  stdout, stderr, status = Open3.capture3 "git clone #{url} #{local_path}"
  status.success?
end

def change_branch(branch, local_path)
  return true if (branch.nil? || branch.strip.empty?)
  stdout, stderr, status = Open3.capture3 "git -C #{local_path} switch #{branch}"
  status.success?
end

def setup_local_repo(repository, branch, local_path)
  msg_no_repo = "Downloading of the repository failed. Please make sure the URL is correct: #{}"
  msg_no_branch = "Branch name is incorrect: #{branch.to_s}"

  error = clone_repo(repository, local_path) ? nil : msg_no_repo
  (error = change_branch(branch, local_path) ? nil : msg_no_branch) unless error

  failure(error) if error
  error.nil?
end


# issue_id = ENV["ISSUE_ID"]
repo_url = ENV["REPO_URL"] # this is repreository
repo_branch = ENV["PAPER_BRANCH"] # this is branch
rand_local_path = "tmp/#{SecureRandom.hex}" # where the repo will be cloned

setup_local_repo(repo_url, repo_branch, rand_local_path)

def find_paper_path(search_path)
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

path_to_ipynb = find_paper_path(rand_local_path)

if paper_path.nil?
  system("echo 'CUSTOM_ERROR=Paper file not found.' >> $GITHUB_ENV")
  raise "   !! ERROR: Paper file not found"
else
  system("echo 'paper_file_path=#{path_to_ipynb}' >> $GITHUB_OUTPUT")
end
