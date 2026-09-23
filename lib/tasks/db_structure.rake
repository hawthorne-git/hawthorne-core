# Dumps the schema (structure only, no data) of each development database to
# hawthorne-core/db/<name>.sql so the SQL files mirror the live dev
# databases. Every hawthorne app shares these databases, so the files live in
# hawthorne core rather than in each app.
#
# Usage:
#   bin/rails db:structure:dump          # refresh all three
#   bin/rails db:structure:dump[admin]   # refresh just one
#
# The dev databases are the model structure. Run this after any schema change
# (migration, manual DDL) to refresh the committed structure files.
#
# Must be run from an app that loads hawthorne core from a local checkout
# (gem 'hawthorne-core', path: '../hawthorne-core'). When core is loaded from
# git, its root is bundler's gem cache, so the task aborts instead of writing
# the files there.
#
# Requires a pg_dump whose major version is >= the server (Render runs PG 18).
# The task auto-detects the newest pg_dump under C:\Program Files\PostgreSQL,
# or honors a PG_DUMP env var pointing at a specific pg_dump executable.

namespace :db do
  namespace :structure do
    # name => env var holding its connection URL
    DB_STRUCTURE_TARGETS = {
      'admin' => 'DATABASE_ADMIN_URL',
      'app' => 'DATABASE_APP_URL',
      'log' => 'DATABASE_LOGS_URL'
    }.freeze

    desc 'Dump hawthorne-core/db/<name>.sql for each dev database (or one: db:structure:dump[admin])'
    task :dump, [:only] => :environment do |_t, args|
      if Gem.loaded_specs['hawthorne-core']&.source.is_a?(Bundler::Source::Git)
        abort 'hawthorne-core is loaded from git; run this from an app using ' \
              "gem 'hawthorne-core', path: '../hawthorne-core'"
      end

      core_root = HawthorneCore::Engine.root
      pg_dump = find_pg_dump
      targets = DB_STRUCTURE_TARGETS
      targets = targets.slice(args[:only]) if args[:only]

      if targets.empty?
        abort "Unknown target '#{args[:only]}'. Valid: #{DB_STRUCTURE_TARGETS.keys.join(', ')}"
      end

      targets.each do |name, env_var|
        url = ENV[env_var]
        if url.nil? || url.strip.empty?
          warn "Skipping #{name}: #{env_var} is not set"
          next
        end

        out_path = core_root.join('db', "#{name}.sql")
        FileUtils.mkdir_p(out_path.dirname)

        ok = system(
          pg_dump,
          '--schema-only',
          '--no-owner',
          '--no-privileges',
          '--file', out_path.to_s,
          url
        )

        if ok
          puts "Wrote #{out_path.relative_path_from(core_root.parent)}"
        else
          abort "pg_dump failed for #{name} (exit #{$?.exitstatus})"
        end
      end
    end

    def find_pg_dump
      env = ENV['PG_DUMP']
      return env if env && File.executable?(env)

      candidates = Dir.glob('C:/Program Files/PostgreSQL/*/bin/pg_dump.exe')
                      .sort_by { |p| p[%r{PostgreSQL/(\d+)/}, 1].to_i }
                      .reverse
      return candidates.first if candidates.any?

      'pg_dump' # fall back to PATH (incl. non-Windows)
    end
  end
end
