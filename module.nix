inputs:
{
    config,
    wlib,
    lib,
    pkgs,
    ...
}:
{
    imports = [ wlib.wrapperModules.neovim ];
    options.nvim-lib.neovimPlugins = lib.mkOption {
        readOnly = true;
        type = lib.types.attrsOf wlib.types.stringable;
        default = config.nvim-lib.pluginsFromPrefix "plugins-" inputs;
    };
    config.settings.config_directory = ./.;
    config.specs.lze = [
        config.nvim-lib.neovimPlugins.lze
        {
            data = config.nvim-lib.neovimPlugins.lzextras;
            name = "lzextras";
        }
    ];

    config.specs.lsp = {
        after = [ "general" ];
        lazy = true;
        data = null;
        extraPackages = with pkgs; [
            nil
            nixd
            nixfmt
            lua-language-server
            stylua
            clang-tools
            rust-analyzer
            rustfmt
            vtsls
            nodePackages.vscode-langservers-extracted
            tailwindcss-language-server
            emmet-ls
            cmake-language-server
        ];
    };

    config.specs.formatter = {
        after = [ "general" ];
        lazy = true;
        data = null;
        extraPackages = with pkgs; [
            prettierd
            nodePackages.prettier
            black
            isort
            shellcheck
            shellharden
            shfmt
            jq
            clang-tools
            rustfmt
            nixfmt
            nodePackages.eslint_d
            cmake-format
        ];
    };

    config.specs.debug = {
        after = [ "general" ];
        lazy = true;
        extraPackages = with pkgs; [
            (writeShellScriptBin "codelldb" ''
                exec ${vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb "$@"
            '')
        ];
        data = with pkgs.vimPlugins; [
            nvim-dap
            nvim-dap-ui
            nvim-dap-virtual-text
            nvim-nio
        ];
    };

    config.specs.linter = {
        after = [ "general" ];
        lazy = true;
        data = null;
        extraPackages = with pkgs; [
            cppcheck
            nodePackages.eslint_d
        ];
    };

    config.specs.general = {
        after = [ "lze" ];
        extraPackages = with pkgs; [
            lazygit
            tree-sitter
        ];
        lazy = true;
        data = with pkgs.vimPlugins; [
            {
                data = vim-sleuth;
                lazy = false;
            }
            lazydev-nvim
            snacks-nvim
            nvim-lspconfig
            nvim-surround
            vim-startuptime
            nvim-cmp
            luasnip
            cmp-cmdline
            cmp-nvim-lsp
            cmp-buffer
            cmp-path
            cmp-git
            friendly-snippets
            lualine-nvim
            # moved from separate spec files
            { data = gitsigns-nvim; }
            { data = which-key-nvim; }
            { data = fidget-nvim; }
            nvim-lint
            conform-nvim
            nvim-treesitter-textobjects
            nvim-treesitter.withAllGrammars
            # additional plugins from converted specs
            nvim-autopairs
            leap-nvim
            nvim-ufo
            promise-async # ufo dependency
            mini-icons # neo-tree + snacks icons
            nvim-ts-autotag
        ];
    };
    # These are from the tips and tricks section of the neovim wrapper docs!
    # https://birdeehub.github.io/nix-wrapper-modules/neovim.html#tips-and-tricks
    # We could put these in another module and import them here instead!

    # This submodule modifies both levels of your specs
    config.specMods =
        {
            # When this module is ran in an inner list,
            # this will contain `config` of the parent spec
            parentSpec ? null,
            # and this will contain `options`
            # otherwise they will be `null`
            parentOpts ? null,
            parentName ? null,
            # and then config from this one, as normal
            config,
            # and the other module arguments.
            ...
        }:
        {
            # you could use this to change defaults for the specs
            # config.collateGrammars = lib.mkDefault (parentSpec.collateGrammars or false);
            # config.autoconfig = lib.mkDefault (parentSpec.autoconfig or false);
            # config.runtimeDeps = lib.mkDefault (parentSpec.runtimeDeps or false);
            # config.pluginDeps = lib.mkDefault (parentSpec.pluginDeps or false);
            # or something more interesting like:
            # add an extraPackages field to the specs themselves
            options.extraPackages = lib.mkOption {
                type = lib.types.listOf wlib.types.stringable;
                default = [ ];
                description = "a extraPackages spec field to put packages to suffix to the PATH";
            };
            # You could do this too
            # config.before = lib.mkDefault [ "INIT_MAIN" ];
        };
    config.extraPackages = config.specCollect (acc: v: acc ++ (v.extraPackages or [ ])) [ ];

    # Inform our lua of which top level specs are enabled
    options.settings.cats = lib.mkOption {
        readOnly = true;
        type = lib.types.attrsOf lib.types.bool;
        default = builtins.mapAttrs (_: v: v.enable) config.specs;
    };
    # build plugins from inputs set
    options.nvim-lib.pluginsFromPrefix = lib.mkOption {
        type = lib.types.raw;
        readOnly = true;
        default =
            prefix: inputs:
            lib.pipe inputs [
                builtins.attrNames
                (builtins.filter (s: lib.hasPrefix prefix s))
                (map (
                    input:
                    let
                        name = lib.removePrefix prefix input;
                    in
                    {
                        inherit name;
                        value = config.nvim-lib.mkPlugin name inputs.${input};
                    }
                ))
                builtins.listToAttrs
            ];
    };
}
