class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/plugins/reindex')
    .description("Rebuild the ArchivesSpace Solr index")
    .params()
    .permissions([:administer_system])
    .returns(
      [200, "String"],
      [403, "Access Denied"]
    ) \
  do
    # TODO: could job this, but it shouldn't take long (famous.last.words)
    ArchivesSpace::Reindexer.run

    [200, {}, "OK"]
  end

end
