# In production, Tailwind CSS is pre-built locally and committed to git.
# The @source path for hawthorne-core only resolves in development (local path gem).
# This prevents assets:precompile from overwriting the committed CSS with a bad rebuild.
unless Rails.env.development?
  # runs as a prerequisite, after every rake file has loaded, so it works
  # regardless of whether tailwindcss-rails loads before or after hawthorne core
  task 'tailwindcss:skip_build' do
    Rake::Task['tailwindcss:build'].clear_actions
  end

  task 'tailwindcss:build' => 'tailwindcss:skip_build'
end
