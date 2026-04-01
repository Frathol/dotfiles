return {
  -- Auto-close brackets/quotes (sangat bantu pas koding Java/C)
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },
  -- Menampilkan indentasi dengan garis halus (biar rapi liat blok kode)
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
  },
  -- Colorizer (buat liat warna CSS langsung di nvim)
  {
    "NvChad/nvim-colorizer.lua",
    opts = {
      user_default_options = { tailwind = true },
    },
  },
  -- Highlight kata yang sama saat kursor di atasnya
  {
    "RRethy/vim-illuminate",
    event = "VeryLazy",
  },
}
