require "test/unit"
require_relative "../lib/dropbox_sdk"
require "securerandom"
require "set"
require "uri"

class SDKTest < Test::Unit::TestCase

  def testfile(name)
    File.expand_path("../testfiles/#{name}", __FILE__)
  end

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @client = DropboxClient.new(ENV['DROPBOX_RUBY_SDK_ACCESS_TOKEN'])

    @foo = testfile("foo.txt")
    @frog = testfile("Costa Rican Frog.jpg")
    @song = testfile("dropbox_song.mp3")
    @fluff = "https://www.dropbox.com/s/qmocfrco2t0d28o/Fluffbeast.docx"

    @save_url_statuses = ["PENDING", "COMPLETE", "DOWNLOADING"]
    @test_dir = "/Ruby SDK Tests/" + Time.new.strftime("%Y-%m-%d %H.%M.%S") + "/"
  end

  def teardown
    return true
    @client.file_delete(@test_dir) rescue nil # already deleted
  end

  def hash_has(hash, options={}, more)

    more.each do |m|
      assert(hash.include? m)
    end

    options.each do |key, value|
      assert_equal(value, hash[key])
    end

  end

  def assert_file(file, path, metadata, more=[], options={})
    hash_has(metadata,
      {
        "name"         => File.basename(path),
        "path_lower"   => path.downcase,
        "path_display" => path,
        "size"         => File.size(file),
      }.merge(options),
      more.push(*['id', 'client_modified', 'server_modified', 'rev'])
    )
  end

  def assert_folder(file, path, metadata, more=[], options={})
    hash_has(metadata,
      {
        ".tag"         => "folder",
        "name"         => path.split('/').last,
        "path_lower"   => path.downcase,
        "path_display" => path
      }.merge(options),
      more.push(*['id'])
    )
  end

  def open_binary(filename)
    File.open(filename, 'rb') { |io| io.read }
  end

  def upload(filename, path, mode='add')
    @client.upload(path, open_binary(filename), mode)
  end

  def test_upload
    def assert_upload(file, path)
      file_path = @test_dir + "put/" + path
      result = @client.upload(file_path, open(file, "rb"))
      assert_file(file, file_path, result)
    end

    assert_upload(@foo, "foo.txt")
    assert_upload(@frog, "frog.jpg")
    assert_upload(@song, "song.mp3")

    puts "✅  Test Upload Successful"
  end

  def test_download
    def assert_download(file, path)
      file_path = @test_dir + "get/" + path
      upload(file, file_path)
      result, metadata = @client.download(file_path)
      local = open_binary(file)
      assert_equal(result.length, local.length)
      assert_equal(result, local)
      assert_file(file, file_path, metadata)
    end

    assert_download(@foo, "foo.txt")
    assert_download(@frog, "frog.txt")
    assert_download(@song, "song.txt")

    puts "✅  Test Download Successful"
  end

  def test_search
    path = @test_dir + "search/"
    upload_paths = [path + "text.txt",
                    path + "subFolder/text.txt",
                    path + "subFolder/cow.txt",
                    path + "frog.jpg",
                    path + "frog2.jpg",
                    path + "subFolder/frog2.jpg"]

    3.times do |i|
      upload(@foo, upload_paths[i])
      upload(@frog, upload_paths[3+i])
    end

    # give Dropbox enough time to make the uploads searchable
    sleep 15

    results = @client.search(path, "sasdfasdf")
    assert_equal(results, {"matches"=>[], "more"=>false, "start"=>0})

    results = @client.search(path, "jpg")
    assert_equal(results['matches'].length, 3)

    matches = results["matches"]
    matches.sort_by!{ |key| key["metadata"]["path_lower"] }
    matches.each.with_index do |match, i|
      assert_equal(match["match_type"], {".tag"=>"filename"})
      assert_file(@frog, upload_paths[3+i], match["metadata"], [], ".tag"=>"file")
    end

    results = @client.search(path + "subFolder", "jpg")
    assert_equal(results["matches"].length, 1)
    assert_file(@frog, upload_paths[5], results["matches"][0]["metadata"], [], ".tag"=>"file")

    results = @client.search(path, "subFolder")
    assert_equal(results["matches"].length, 1)
    assert_folder(@frog, File.dirname(upload_paths[5]), results["matches"][0]["metadata"])

    puts "✅  Test Search Succeeded"
  end

  def test_metadatas
    return true
    def assert_metadata(file, path)
      file_path = @test_dir + "meta" + path
      upload(file, file_path)
      result = @client.metadata(file_path)
      assert_file(file, result, "path" => file_path)
    end
    assert_metadata(@foo, "foo.txt")
    assert_metadata(@frog, "frog.txt")
    assert_metadata(@song, "song.txt")
  end

  def test_create_folder
    return true
    path = @test_dir + "new_folder"
    result = @client.file_create_folder(path)
    assert_equal(result['size'], '0 bytes')
    assert_equal(result['bytes'], 0)
    assert_equal(result['path'], path)
    assert_equal(result['is_dir'], true)
  end

  def test_delete
    return true
    path = @test_dir + "delfoo.txt"
    upload(@foo, path)
    metadata = @client.metadata(path)
    assert_file(@foo, metadata, "path" => path)

    del_metadata = @client.file_delete(path)
    assert_file(@foo, del_metadata, "path" => path, "is_deleted" => true, "bytes" => 0)

  end

  def test_copy
    return true
    path = @test_dir + "copyfoo.txt"
    path2 = @test_dir + "copyfoo2.txt"
    upload(@foo, path)
    @client.file_copy(path, path2)
    metadata = @client.metadata(path)
    metadata2 = @client.metadata(path2)

    assert_file(@foo, metadata, "path" => path)
    assert_file(@foo, metadata2, "path" => path2)
  end

  def test_move
    return true
    path = @test_dir + "movefoo.txt"
    path2 = @test_dir + "movefoo2.txt"
    upload(@foo, path)
    @client.file_move(path, path2)

    metadata = @client.metadata(path)
    assert_file(@foo, metadata, "path" => path, "is_deleted" => true, "bytes" => 0)

    metadata = @client.metadata(path2)
    assert_file(@foo, metadata, "path" => path2)
  end

  def test_stream
    return true
    path = @test_dir + "/stream_song.mp3"
    upload(@song, path)
    link = @client.media(path)
    hash_has(link, {},
      "url",
      "expires"
    )
  end
  def test_share
    return true

    path = @test_dir + "/stream_song.mp3"
    upload(@song, path)
    link = @client.shares(path)
    hash_has(link, {},
      "url",
      "expires"
    )
  end

  def test_revisions_restore
    return true

    path = @test_dir + "foo_revs.txt"
    upload(@foo, path)
    upload(@frog, path, overwrite = true)
    upload(@song, path, overwrite = true)
    revs = @client.revisions(path)
    metadata = @client.metadata(path)
    assert_file(@song, metadata, "path" => path, "mime_type" => "text/plain")

    assert_equal(revs.length, 3)
    assert_file(@song, revs[0], "path" => path, "mime_type" => "text/plain")
    assert_file(@frog, revs[1], "path" => path, "mime_type" => "text/plain")
    assert_file(@foo, revs[2], "path" => path, "mime_type" => "text/plain")

    metadata = @client.restore(path, revs[2]["rev"])
    assert_file(@foo, metadata, "path" => path, "mime_type" => "text/plain")
    metadata = @client.metadata(path)
    assert_file(@foo, metadata, "path" => path, "mime_type" => "text/plain")
  end

  def test_copy_ref
    return true

    path = @test_dir + "foo_copy_ref.txt"
    path2 = @test_dir + "foo_copy_ref_target.txt"

    upload(@foo, path)
    copy_ref = @client.create_copy_ref(path)
    hash_has(copy_ref, {},
      "expires",
      "copy_ref"
    )

    copied = @client.add_copy_ref(path2, copy_ref["copy_ref"])
    metadata = @client.metadata(path2)
    assert_file(@foo, metadata, "path" => path2)
    copied_foo = @client.get_file(path2)
    local_foo = open(@foo, "rb").gets
    assert_equal(copied_foo.length, local_foo.length)
    assert_equal(copied_foo, local_foo)
  end

  def test_chunked_upload
    return true
    path = @test_dir + "chunked_upload_file.txt"
    size = 1024*1024*10
    chunk_size = 4 * 1024 * 1102


    random_data = SecureRandom.random_bytes(n=size)
    uploader = @client.get_chunked_uploader(StringIO.new(random_data), size)
    error_count = 0
    while uploader.offset < size and error_count < 5
      begin
        upload = uploader.upload(chunk_size = chunk_size)
      rescue DropboxError => e
        error_count += 1
      end
    end
    uploader.finish(path)
    downloaded = @client.get_file(path)
    assert_equal(size, downloaded.length)
    assert_equal(random_data, downloaded)
  end

  def test_delta
    return true
    prefix = @test_dir + "delta"

    a = prefix + "/a.txt"
    upload(@foo, a)
    b = prefix + "/b.txt"
    upload(@foo, b)
    c = prefix + "/c"
    c_1 = prefix + "/c/1.txt"
    upload(@foo, c_1)
    c_2 = prefix + "/c/2.txt"
    upload(@foo, c_2)

    prefix_lc = prefix.downcase
    c_lc = c.downcase

    # /delta on everything
    expected = Set.new [prefix, a, b, c, c_1, c_2].map {|p| p.downcase}
    entries = Set.new
    cursor = nil
    while true
      r = @client.delta(cursor)
      entries = Set.new if r['reset']
      r['entries'].each { |path_lc, md|
        if path_lc.start_with?(prefix_lc+'/') || path_lc == prefix_lc
          assert(md != nil)  # we should never get deletes under 'prefix'
          entries.add path_lc
        end
      }
      if not r['has_more']
        break
      end
      cursor = r['cursor']
    end

    assert_equal(expected, entries)

    # /delta where path_prefix=c
    expected = Set.new [c, c_1, c_2].map {|p| p.downcase}
    entries = Set.new
    cursor = nil
    while true
      r = @client.delta(cursor, c)
      entries = Set.new if r['reset']
      r['entries'].each { |path_lc, md|
        assert path_lc.start_with?(c_lc+'/') || path_lc == c_lc
        assert(md != nil)  # we should never get deletes
        entries.add path_lc
      }
      if not r['has_more']
        break
      end
      cursor = r['cursor']
    end

    assert_equal(expected, entries)
  end

  def test_delta_latest_cursor
    return true
    prefix = @test_dir + "delta"

    # First test with no path_prefix

    r = @client.delta_latest_cursor
    cursor = r['cursor']
    assert(cursor)

    # Other changes (outside of these tests) might be going on, so we can't
    # assert anything more about the deltas.
    r = @client.delta(cursor)

    # Going deeper down the tree is OK
    r = @client.delta(cursor, prefix)
    assert(r['entries'].empty?)

    # Now test with a path_prefix

    r = @client.delta_latest_cursor(prefix)
    cursor = r['cursor']
    assert(cursor)

    r = @client.delta(cursor, prefix)
    assert(r['entries'].empty?)

    # Going deeper down the tree is OK
    r = @client.delta(cursor, prefix + "/subdir")
    assert(r['entries'].empty?)

    # Going up (outside of the scope of the cursor) is not OK
    assert_raise DropboxError do
      @client.delta(cursor, nil)
    end
  end

  def test_longpoll_delta
    return true
    prefix = @test_dir + "delta"

    # Initial cursor has to come from #delta
    r = @client.delta(nil, prefix)
    cursor = r['cursor']

    upload(@foo, prefix + "/a.txt")
    r = @client.longpoll_delta(cursor)
    assert(r['changes'])

    r = @client.delta(cursor, prefix)
    cursor = r['cursor']

    # Await timeout
    r = @client.longpoll_delta(cursor)
    assert(!r['changes'])
  end

  def test_save_url
    return true
    to_path = URI.encode(@test_dir + "fluff.docx")
    result = @client.save_url(to_path, @fluff)

    assert_includes(@save_url_statuses, result["status"])
    assert_includes(result, "job")
  end

  def test_save_url_job
    return true
    to_path = URI.encode(@test_dir + "fluff.docx")
    save_url = @client.save_url(to_path, @fluff)

    job_id = save_url["job"]
    result = @client.save_url_job(job_id)

    assert_includes(@save_url_statuses, result["status"])

  end
end
