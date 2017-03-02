promisify = require 'promisify-node'
fs = promisify 'fs'
Monitor = promisify 'icecast-monitor'

DJ = require './dj'
cfg = require './config'

Object.assign cfg.monitor, cfg.srv
Object.assign cfg.dj, cfg.srv

monitor = new Monitor cfg.monitor

Promise.all([
  fs.readdir(cfg.dir),
  monitor.createFeed()
]).then((res) ->

  files = res[0]?.map (file) -> cfg.dir + file
  feed = res[1]

  return console.log 'No files in directory' if files.length is 0

  dj = new DJ srv: cfg.dj,  playlist: files, name: cfg.name

  feed.on 'server.you', (val) -> console.log val

  feed.on 'mount.totalBytesRead', (key, val) -> console.log 'mount.totalBytesRead', key, val

  feed.on 'server.sources', (sources) ->

    console.log 'sources', sources

    return dj.play() if sources is 0

    if sources >= 1
      monitor.getSource cfg.monitor.mount, (err, source) ->
        return console.log '[INFO]', err if err
        # if source then live is streaming and stop dj
        dj.stop()

  process.on 'SIGUSR1', ->
    dj.stop()
    dj.play()
).catch((err) -> console.log  err)
