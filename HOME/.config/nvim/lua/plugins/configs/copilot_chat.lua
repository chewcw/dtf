local M = {}

M.opts = {
  model = "claude-3.5-sonnet",
  mappings = {
    reset = {
      normal = "<C-A-r>",
      insert = "<C-A-r>",
    },
    submit_prompt = {
      normal = "<A-CR>",
      insert = "<A-CR>",
    },
    show_help = {
      normal = "g?",
    },
    accept_diff = {
      normal = "<C-A-y>",
      insert = "<C-A-y>",
    },
    yank_diff = {
      normal = "gY",
      register = "+",
    },
    jump_to_diff = {
      normal = "gJ",
    },
    close = {
      normal = "gq",
      insert = "<C-c>",
    },
    quickfix_answers = {
      normal = "gQa",
    },
    quickfix_diffs = {
      normal = "gQd",
    },
    show_info = {
      normal = "gI",
    },
    show_context = {
      normal = "gC",
    },
    show_diff = {
      normal = "gD",
    },
    toggle_sticky = {
      detail = "Makes line under cursor sticky or deletes sticky line.",
      normal = "gR",
    },
  },
  show_folds = true,
  window = {
    width = 0.4,
    height = 1,
  },
  highlight_headers = false,
  prompts = {
    GeneralChat = {
      prompt = "",
      system_prompt =
      "You are a helpful and knowledgeable AI assistant capable of answering questions, generating text, translating languages, writing different kinds of creative content, and providing summaries on a broad range of topics.",
      description = "General chat agent without the context",
      selection = function() end, -- No context
    },
    Search = {
      prompt = "",
      system_prompt =
      "You are a helpful and knowledgeable AI assistant capable of answering questions, generating text, translating languages, writing different kinds of creative content, and providing summaries on a broad range of topics.",
      description = "General search agent without the context",
      selection = function() end, -- No context
      agent = "perplexityai",  -- Use perplexityai
    },
    Dict = {
      prompt =
      "Explain the selected word with pronunciation, translations to Chinese and Japanese, along with explanations, example use cases, synonyms, antonyms in different contexts, all in English, Chinese, and Japanese.\n\n",
      description = "Dictionary",
      selection = function(source)
        return require("CopilotChat.select").visual(source)
      end,
    },
  },
}

return M
