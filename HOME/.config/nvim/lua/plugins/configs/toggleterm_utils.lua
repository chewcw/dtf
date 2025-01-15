local utils = require("core.utils")

local M = {}

-- there are also some exit action defined in plugins/config/toggleterm.lua

-- ----------------------------------------------------------------------------
-- ToggleTerm on demand, can select working directory for the opened term
-- ----------------------------------------------------------------------------
M.toggle_term = function(target_direction, is_open_from_file_browser, cwd)
  local count = vim.v.count or vim.g.toggle_term_count or 1

  local main_logic = function(vcount)
    return function(dir)
      if dir == nil then
        dir = ""
      end

      if vcount ~= 0 then
        if vcount ~= vim.g.toggle_term_count then
          if vim.g.toggle_term_direction == target_direction then
            if not vim.g.toggle_term_opened then
              -- open term for direction [target_direction]
              vim.cmd(vcount .. "ToggleTerm direction=" .. target_direction .. " dir='" .. dir .. "'")
              vim.g.toggle_term_opened = true
              vim.g.toggle_term_count = vcount
              goto done
            end

            if vim.g.toggle_term_opened then
              -- close existing term
              vim.cmd(vim.g.toggle_term_count .. "ToggleTerm")
              vim.g.toggle_term_opened = false
              -- open [vcount] term for same direction [target_direction]
              vim.cmd(vcount .. "ToggleTerm direction=" .. target_direction .. " dir='" .. dir .. "'")
              vim.g.toggle_term_opened = true
              vim.g.toggle_term_count = vcount
              goto done
            end
            goto done
          end

          -- different direction
          if not vim.g.toggle_term_opened then
            -- open [vcount] term for different direction [target_direction]
            vim.cmd(vcount .. "ToggleTerm direction=" .. target_direction .. " dir='" .. dir .. "'")
            vim.g.toggle_term_opened = true
            vim.g.toggle_term_count = vcount
            goto done
          end

          if vim.g.toggle_term_opened then
            -- close existing term
            vim.cmd(vim.g.toggle_term_count .. "ToggleTerm")
            vim.g.toggle_term_opened = false
            -- open [vcount] term for different direction [target_direction]
            vim.cmd(vcount .. "ToggleTerm direction=" .. target_direction .. " dir='" .. dir .. "'")
            vim.g.toggle_term_opened = true
            vim.g.toggle_term_count = vcount
            goto done
          end
        else
          if vim.g.toggle_term_direction == target_direction then
            if not vim.g.toggle_term_opened then
              -- open term for direction [target_direction]
              vim.cmd(vcount .. "ToggleTerm direction=" .. target_direction .. " dir='" .. dir .. "'")
              vim.g.toggle_term_opened = true
              vim.g.toggle_term_count = vcount
              goto done
            end

            if vim.g.toggle_term_opened then
              -- close the term
              vim.cmd(vim.g.toggle_term_count .. "ToggleTerm")
              vim.g.toggle_term_opened = false
              vim.g.toggle_term_count = vcount
              goto done
            end
            goto done
          end

          -- different direction
          if not vim.g.toggle_term_opened then
            -- open [vcount] term for different direction [target_direction]
            vim.cmd(vcount .. "ToggleTerm direction=" .. target_direction .. " dir='" .. dir .. "'")
            vim.g.toggle_term_opened = true
            vim.g.toggle_term_count = vcount
            goto done
          end

          if vim.g.toggle_term_opened then
            -- close existing term
            vim.cmd(vim.g.toggle_term_count .. "ToggleTerm")
            vim.g.toggle_term_opened = false
            -- open [vcount] term for different direction [target_direction]
            vim.cmd(vcount .. "ToggleTerm direction=" .. target_direction .. " dir='" .. dir .. "'")
            vim.g.toggle_term_opened = true
            vim.g.toggle_term_count = vcount
            goto done
          end
        end
      else
        -- without specifying vim.v.vcount
        if vim.g.toggle_term_direction == target_direction then
          if not vim.g.toggle_term_opened then
            -- open term for direction
            vim.cmd("ToggleTerm direction=" .. target_direction .. " dir='" .. dir .. "'")
            vim.g.toggle_term_opened = true
            goto done
          end

          if vim.g.toggle_term_opened then
            -- close term
            vim.cmd("ToggleTerm")
            vim.g.toggle_term_opened = false
            goto done
          end
          goto done
        end

        -- different direction
        if not vim.g.toggle_term_opened then
          -- open term for different direction
          vim.cmd("ToggleTerm direction=" .. target_direction .. " dir='" .. dir .. "'")
          vim.g.toggle_term_opened = true
          goto done
        end

        if vim.g.toggle_term_opened then
          -- close term first
          vim.cmd("ToggleTerm")
          vim.g.toggle_term_opened = false
          -- then open term for different direction
          vim.cmd("ToggleTerm direction=" .. target_direction .. " dir='" .. dir .. "'")
          vim.g.toggle_term_opened = true
          goto done
        end
      end

      ::done::
      vim.g.toggle_term_direction = target_direction

      local x = vim.g.toggle_term_opened_term_ids
      if not utils.table_contains(x, vcount) then
        table.insert(x, vcount)
      end
      vim.g.toggle_term_opened_term_ids = x
    end
  end

  local select_path_for_toggle_term
  select_path_for_toggle_term = function(callback, path)
    local select_path = function(prompt_bufnr)
      local selection = require("telescope.actions.state").get_selected_entry()
      local selected_path = selection.path
      if vim.fn.isdirectory(selected_path) == 1 then
        require("telescope.actions").close(prompt_bufnr)
        callback(selected_path)
      else
        print("Selected item is not a directory")
      end
    end

    local fb = require("telescope").extensions.file_browser
    fb.file_browser({
      path = path or "",
      prompt_title = "Select terminal workdir",
      select_dirs = true,
      select_buffer = true,
      attach_mappings = function(_, map)
        map("i", "<A-CR>", select_path)
        map("n", "<A-CR>", select_path)
        map(
          "n",
          "g<Space>",
          require("plugins.configs.telescope_utils").go_to_directory(function(input, _, _)
            select_path_for_toggle_term(callback, input)
          end)
        )
        map("n", "q", function(prompt_bufnr)
          -- nothing selected, then just proceed without specifying the path
          require("telescope.actions").close(prompt_bufnr)
          local dir = ""
          callback(dir)
        end)
        return true
      end,
    })
  end

  if
      vim.g.toggle_term_direction == nil
      or vim.g.toggle_term_opened == nil
      or vim.g.toggle_term_count == nil
      or vim.g.toggle_term_dir == nil
      or vim.g.toggle_term_opened_term_ids == nil
  then
    vim.g.toggle_term_direction = target_direction
    vim.g.toggle_term_opened = false
    vim.g.toggle_term_count = 0
    vim.g.toggle_term_dir = ""
    vim.g.toggle_term_opened_term_ids = {}
  end

  local found = false
  for _, opened_term_id in ipairs(vim.g.toggle_term_opened_term_ids) do
    if count == opened_term_id then
      found = true
      break
    end
  end

  if is_open_from_file_browser and cwd then
    local dir = cwd
    main_logic(vim.g.toggle_term_count + 1)(dir) -- +1 so that it always open in new ToggleTerm
    return
  end

  -- if the current count is 0, and the record is also 0, means this is first time open the term,
  -- the first time opened term should be assigned id 1,
  -- and let me select the working directory for this term
  if count == 0 and vim.g.toggle_term_count == 0 then
    select_path_for_toggle_term(main_logic(count + 1))
    return
  end

  -- if the current count is 0, and the record is not 0, means vim.g.toggle_term_count was
  -- opened previously, now just need to toggle it
  if count == 0 and vim.g.toggle_term_count ~= 0 then
    local dir = ""
    main_logic(vim.g.toggle_term_count)(dir)
    return
  end

  -- there is no terminal with this count opened, means this is new terminal
  -- let me select the working directory for this new term
  if not found then
    select_path_for_toggle_term(main_logic(count))
  else
    -- else just open or close the term
    local dir = ""
    main_logic(count)(dir)
  end
end

return M
