vim.lsp.config("clangd", {
  cmd = { 'clangd', '--query-driver=**/*gcc*,**/*g++*' },
})
