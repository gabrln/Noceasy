return {
  -- Installs the base16-nvim colorscheme (as per Noctalia docs)
  {
    "RRethy/base16-nvim",
    config = function()
      require("matugen").setup()
    end,
  },
}
