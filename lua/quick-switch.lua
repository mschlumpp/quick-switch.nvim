local uniquify = require 'quick-switch.uniquify'

local M = {}

local path_separator = '/'
if vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
    path_separator = '\\'
end

--
-- Buffer management
--
local ts = 0
local function init_ts()
    for i, b in ipairs(vim.fn.getbufinfo()) do
        if b.variables ~= nil and b.variables.qs_ts ~= nil then
            ts = math.max(ts, b.variables.qs_ts)
        end
    end
    ts = ts + 1
end

local function buffer_touch(ev)
    local bufnr = ev.buf

    vim.api.nvim_buf_set_var(bufnr, 'qs_ts', ts)
    ts = ts + 1
end

local function filter_buffer(b)
    return vim.fn.buflisted(b) == 1 and vim.api.nvim_buf_is_loaded(b)
end

-- Returns a list of buffers with { bufnr, name } elements
local function get_mru_list()
    -- get a list of buffers
    local buffer_list = {}
    for i, b in ipairs(vim.api.nvim_list_bufs()) do
        if filter_buffer(b) then
            local info = vim.fn.getbufinfo(b)[1]
            table.insert(buffer_list, info)
        end
    end

    -- sort by last used (desc)
    table.sort(buffer_list, function(a, b)
        -- Assume that very old buffers don't have qs_ts set
        if a.variables == nil or a.variables.qs_ts == nil then
            return false
        elseif b.variables == nil or b.variables.qs_ts == nil then
            return true
        end

        return a.variables.qs_ts > b.variables.qs_ts
    end)

    return buffer_list
end

--
-- UI handling
--
local FORWARD = 1
local BACKWARD = -1

local function init_state()
    return {
        buffers = get_mru_list(),
        idx = 1,
        target_window = vim.api.nvim_get_current_win(),
    }
end

local function pretty_print_state(state)
    local paths = {}
    for i, v in ipairs(state.buffers) do
        table.insert(paths, vim.fn.split(vim.fn.fnamemodify(v.name, ':p:~'), path_separator))
    end
    paths = uniquify(paths)

    local line = {}
    for i, path in ipairs(paths) do
        local hl = nil
        if i == state.idx then
            hl = 'TermCursor'
        end
        table.insert(line, { table.concat(path, '/'), hl })
        table.insert(line, { ' ' })
    end

    vim.api.nvim_echo(line, false, {})
end

local function change_buffer(state, direction, wrap)
    -- update index and temporarily use zero-based indices...
    local idx = state.idx + direction - 1
    if wrap then
        idx = idx % #state.buffers
    else
        idx = math.max(0, math.min(#state.buffers - 1, idx))
    end
    state.idx = idx + 1

    -- switch buffer
    vim.api.nvim_win_set_buf(state.target_window, state.buffers[state.idx].bufnr)
end

local function buffer_switch(initial, wrap)
    local state = init_state()
    if #state.buffers == 0 then
        return
    end

    if initial then
        change_buffer(state, FORWARD, wrap)
    end

    while true do
        -- For some reason this used ':mode' previously, which also *clears*
        -- the screen before redrawing. Will have to switch back if there are
        -- glitches...
        vim.api.nvim_command('redraw')
        pretty_print_state(state)
        local char = vim.fn.nr2char(vim.fn.getchar())
        if char == '.' then
            change_buffer(state, FORWARD, wrap)
        elseif char == ',' then
            change_buffer(state, BACKWARD, wrap)
        else
            -- Forward keyboard input as close as possible as originally
            -- inputed by the user forward to VIM
            vim.api.nvim_feedkeys(char, 'mt', false)
            break
        end
    end
    vim.api.nvim_command('redraw | echo ""')
end

-- External functions
function M.start_switch()
    buffer_switch(true, false)
end

function M.setup(opts)
    local bufmgmt_group = vim.api.nvim_create_augroup('quick-switch', { clear = true })

    -- List of events from mildred/vim-bufmru
    vim.api.nvim_create_autocmd({
        'InsertEnter',
        'InsertLeave',
        'TextChanged',
        'TextChangedI',
        'CursorMoved',
        'CursorMovedI',
    }, {
        group = bufmgmt_group,
        callback = buffer_touch,
    })

    init_ts()
end

return M
