return {
  {
    "chrisbra/csv.vim",
    ft = { "csv" }, -- Plugin ini hanya akan aktif saat Michael buka file .csv
    setup = function()
      -- Opsional: Biar kolomnya otomatis rapi pas dibuka
      vim.g.csv_autocmd_arrange = 1
    end,
  },
}
