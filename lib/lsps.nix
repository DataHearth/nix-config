{ pkgs }:
# LSPs grouped by language. Each entry exposes:
#   - packages: LSP servers / formatters / linters for that language
#   - deps    : runtime tools the LSPs need (e.g. node for vtsls)
# Consumer pattern: `extraPackages = lsp.<lang>.packages ++ lsp.<lang>.deps;`
{
  nix = {
    packages = with pkgs; [
      nixd
      nixfmt
    ];
    deps = [ ];
  };

  rust = {
    packages = with pkgs; [
      rust-analyzer
    ];
    deps = [ ];
  };

  go = {
    packages = with pkgs; [
      gopls
      golangci-lint
    ];
    deps = [ ];
  };

  python = {
    packages = with pkgs; [
      ruff
      pyright
    ];
    deps = [ ];
  };

  typescript = {
    packages = with pkgs; [
      vtsls
      biome
    ];
    deps = with pkgs; [ nodejs ];
  };

  svelte = {
    packages = with pkgs; [ svelte-language-server ];
    deps = with pkgs; [ nodejs ];
  };

  tailwind = {
    packages = with pkgs; [ tailwindcss-language-server ];
    deps = with pkgs; [ nodejs ];
  };

  web = {
    packages = with pkgs; [ vscode-langservers-extracted ];
    deps = with pkgs; [ nodejs ];
  };

  yaml = {
    packages = with pkgs; [ yaml-language-server ];
    deps = with pkgs; [ nodejs ];
  };

  toml = {
    packages = with pkgs; [ taplo ];
    deps = [ ];
  };

  shell = {
    packages = with pkgs; [
      bash-language-server
      shfmt
      shellcheck
    ];
    deps = with pkgs; [ nodejs ];
  };

  lua = {
    packages = with pkgs; [
      lua-language-server
      stylua
    ];
    deps = [ ];
  };

  zig = {
    packages = with pkgs; [ zls ];
    deps = [ ];
  };

  proto = {
    packages = with pkgs; [ protobuf-language-server ];
    deps = [ ];
  };

  helm = {
    packages = with pkgs; [ helm-ls ];
    deps = [ ];
  };

  docker = {
    packages = with pkgs; [ dockerfile-language-server ];
    deps = with pkgs; [ nodejs ];
  };

  markdown = {
    packages = with pkgs; [ markdown-oxide ];
    deps = [ ];
  };

  jj = {
    packages = with pkgs; [ jj-lsp ];
    deps = [ ];
  };
}
