fs = require 'fs'
nodeID3 = require 'node-id3'
nodeshout = require 'nodeshout'

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

    return @play() unless fpath.substr(-4) is '.mp3'

    @deleteStreams()

    @fsStream = new nodeshout.FileReadStream fpath, 65536
    @fsStream.on 'error', (err) -> console.error '[FS]', err

    err = @shout.open()
    unless err is nodeshout.ErrorTypes.SUCCESS or err is nodeshout.ErrorTypes.CONNECTED
      return console.error 'Unable to connect to server error', err

    try
      meta = nodeID3.read fpath
    catch error
      return console.error '[META]', err if err

    console.log '[META]', meta

    metadata = nodeshout.createMetadata()
    metadata.add 'song', "#{@name}#{meta.artist or ''} - #{meta.title or ''}"
    @shout.setMetadata metadata if metadata

    console.error 'Currently playing file:', fpath

    @stream = new nodeshout.ShoutStream @shout
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
