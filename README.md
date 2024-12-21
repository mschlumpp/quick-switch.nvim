# quick-switch

Small minimalistic LRU buffer switcher for neovim.

## Configuration

With lazy.nvim:

```
{
    'mschlumpp/quick-switch.nvim',
    -- The plugin needs to keep track of buffers even if the keybind wasn't
    -- used yet.
    event = 'VeryLazy',
    keys = {
        { '<leader>.', function() require 'quick-switch'.start_switch() end, 'quick-switch' },
    },
    opts = {},
},
```

## TODOs

- [ ] make keybinds within buffer switcher configurable
- [ ] handle large buffer lists more gracefully (limit how many buffers are shown around current position)

