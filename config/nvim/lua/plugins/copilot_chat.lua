return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "zbirenbaum/copilot.lua" }, -- Mesin utamanya
      { "nvim-lua/plenary.nvim" }, -- Utility tambahan
      { "nvim-telescope/telescope.nvim" }, -- Biar bisa search di chat
    },
    opts = {
      debug = false,
      proxy = nil,
      allow_offline = false,
    },
    keys = {
      { "<leader>cc", "<cmd>CopilotChatToggle<cr>", desc = "Copilot Chat" },
      { "<leader>ce", "<cmd>CopilotChatExplain<cr>", desc = "Copilot Explain Code" },
    },
    -- Penting: Kita build plugin-nya agar executable-nya siap
    -- build = "make utf8",
  },
}
