require_relative 'lib/reindexer'

AppConfig[:reindex_on_startup] = false unless AppConfig.has_key? :reindex_on_startup
if AppConfig[:reindex_on_startup]
  puts "\n\n\nInitiating reindex\n\n\n"
  ArchivesSpace::Reindexer.run
end
