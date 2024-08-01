mp.add_key_binding(null, 'toggle-shuffle', (function() {
  var commands = ['playlist-shuffle', 'playlist-unshuffle']
  var index = 0
  return function() {
    mp.commandv(commands[index])
    mp.commandv('show-text', commands[index])
    index = (index + 1) % commands.length
  }
})())
