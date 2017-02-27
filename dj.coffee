nodeshout = require 'nodeshout'
nodeID3 = require 'node-id3'

class DJ

  constructor: (opt = {}) ->
    @name = opt.name or 'Autodj'
    @playlist = opt.playlist or []
    @stream = 0
    @fsStream = 0
    @currentSongIndex = 0
    @playing = 0

    nodeshout.init()

    @shout = nodeshout.create()
    @shout.setHost opt.srv.host
    @shout.setPort opt.srv.port
    @shout.setUser opt.srv.user
    @shout.setPassword opt.srv.password
    @shout.setMount opt.srv.mount
    @shout.setFormat 1 # 0=ogg, 1=mp3
    @shout.setAudioInfo 'bitrate', '192'
    @shout.setAudioInfo 'samplerate', '44100'
    @shout.setAudioInfo 'channels', '2'

  play: ->

    return if @playing

    @currentSongIndex = Math.floor Math.random() * @playlist.length

    fpath = @playlist[@currentSongIndex]

    @deleteStreams()

    @fsStream = new nodeshout.FileReadStream fpath, 65536

    try
      meta = nodeID3.read fpath # FIX: in some instances returns no music meta data on the same music file ??
    catch error
      console.log error

    if meta
      console.log meta
      metadata = nodeshout.createMetadata()
      metadata.add 'song', "#{meta.artist or ''} - #{meta.title or ''} #{@name}"
      # FIX: all below add calls don't change icecast server metadata
      metadata.add 'title', meta.title or ''
      metadata.add 'artist', meta.artist or ''
      metadata.add 'album', meta.album or ''
      metadata.add 'genre', meta.genre or ''

    err = @shout.open()
    return console.error 'Unable to connect to server error', err unless err is 0 or err is -7 # use nodeshout.ErrorCodes

    @stream = new nodeshout.ShoutStream @shout
    metaResult = @shout.setMetadata metadata if metadata
    console.log 'meta result', metaResult
    
    @fsStream.pipe(@stream).on 'finish', =>
      metadata.free() if metadata
      @playing = 0
      @play()

    @playing = 1

  stop: ->
    @deleteStreams()

    @playing = 0
    @shout.close()

  deleteStreams: ->
    @fsStream?.unpipe?(@stream) if @stream
    delete @stream
    delete @fsStream

module.exports = DJ
