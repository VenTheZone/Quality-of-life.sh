{
  description = "qol: small, pretty terminal commands (compress, cdg, cg, ft, ff, pw, up, vault, lc)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      forAllSystems = f: lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: f nixpkgs.legacyPackages.${system});

      # Every file in bin/ is a command; a new file there becomes a package and a qol entry.
      names = builtins.attrNames (builtins.readDir ./bin);

      # Line 2 of every command is "# qol: <description>"; qol prints these.
      descOf = file:
        let line = builtins.elemAt (lib.splitString "\n" (builtins.readFile file)) 1;
        in if lib.hasPrefix "# qol: " line then lib.removePrefix "# qol: " line
           else throw "${baseNameOf file}: line 2 must be '# qol: <description>'";
      entries = map (n: { name = n; file = ./bin + "/${n}"; }) names
        ++ [ { name = "cdg"; file = ./shell/cdg.zsh; } ];
      qolList = lib.concatMapStrings (e: "${e.name}\t${descOf e.file}\n")
        (builtins.sort (a: b: a.name < b.name) entries);

      # Tools each command runs. A bin/ file without an entry here fails evaluation.
      deps = pkgs: with pkgs; {
        compress = [ ffmpeg fd fzf gum chafa gnused gawk coreutils ];
        cg = [ fd fzf bat eza chafa gnused ];
        ff = [ fd fzf bat eza chafa gnused ];
        ft = [ ripgrep fzf bat ];
        pw = [ gum wl-clipboard coreutils ];
        up = [ curl gum wl-clipboard coreutils ];
        vault = [ age gnutar gum coreutils ];
        lc = [ eza gawk ncurses ];
        qol = [ fzf gawk ];
      };

      # bin/<name> minus its shebang, wrapped by writeShellApplication (shellcheck at build time).
      # QOL_LIB points at lib/ui.sh in the store; every script sources it.
      mkCmd = pkgs: { inputs, env ? { } }: name: pkgs.writeShellApplication {
        inherit name;
        runtimeInputs = inputs;
        runtimeEnv = { QOL_LIB = "${./lib/ui.sh}"; } // env;
        text = lib.removePrefix "#!/usr/bin/env bash\n" (builtins.readFile (./bin + "/${name}"));
      };

      commands = pkgs:
        let
          d = deps pkgs;
          others = lib.genAttrs (lib.remove "qol" names) (n: mkCmd pkgs { inputs = d.${n}; } n);
          # qol carries the other commands on its PATH, so `nix run .#qol` can run any of them.
          qol = mkCmd pkgs {
            inputs = d.qol ++ builtins.attrValues others;
            env.QOL_LIST = "${pkgs.writeText "qol-list" qolList}";
          } "qol";
        in others // { inherit qol; };
    in {
      packages = forAllSystems (pkgs:
        let cmds = commands pkgs;
        in cmds // { default = pkgs.symlinkJoin { name = "qol"; paths = builtins.attrValues cmds; }; });

      # tests/<name>.test.sh becomes checks.<system>.<name>; PKG is the built command of that name.
      checks = forAllSystems (pkgs:
        let
          cmds = self.packages.${pkgs.stdenv.hostPlatform.system};
          tests = map (lib.removeSuffix ".test.sh")
            (builtins.filter (lib.hasSuffix ".test.sh") (builtins.attrNames (builtins.readDir ./tests)));
          runTest = n: pkgs.runCommand "qol-test-${n}" { nativeBuildInputs = [ pkgs.util-linux ]; } ''
            export SRC=${self} PKG=${cmds.${n} or ""}
            bash ${self}/tests/${n}.test.sh
            touch $out
          '';
        in lib.genAttrs tests runTest // {
          packages = cmds.default; # builds, and so shellchecks, every command
          lint = pkgs.runCommand "qol-lint" { nativeBuildInputs = [ pkgs.shellcheck pkgs.zsh ]; } ''
            cd ${self}
            shellcheck --shell=bash -x lib/ui.sh tests/*.sh tests/stubs/*
            zsh -n shell/cdg.zsh
            touch $out
          '';
        });

      # Home Manager: the commands, the cdg zsh function and the QOL alias.
      homeModules.default = { pkgs, ... }: {
        home.packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.default ];
        programs.zsh.shellAliases.QOL = "qol";
        programs.zsh.initContent = lib.replaceStrings [ "@fd@" "@fzf@" "@eza@" ]
          [ (lib.getExe pkgs.fd) (lib.getExe pkgs.fzf) (lib.getExe pkgs.eza) ]
          (builtins.readFile ./shell/cdg.zsh);
      };
    };
}
