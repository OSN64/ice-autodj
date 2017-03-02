module.exports =
  name: ''
  dir: __dirname + '/.tmp/'
  srv:
    host: 'localhost'
    port: 8000
  dj:
    user: 'source'
    password: 'hackme'
    mount: '/autodj'
  monitor:
    user: 'admin'
    password: 'hackme'
    mount: '/live' # / required
