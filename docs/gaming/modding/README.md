# gaming - modding

Notes on how to mod games. Mostly Unity games.

## asset extraction (Unity games)

- https://github.com/zhangjiequan/AssetStudio
    - view and extract assets only
    - Fork of https://github.com/Perfare/AssetStudio
    - How To: https://www.youtube.com/watch?v=d_o1JH_kyeQ&t=9s
- https://github.com/nesrak1/UABEA/
    - view, edit, re-import and extract assets
- https://github.com/nesrak1/UABEA?tab=readme-ov-file#addressables
    - clean up addressables (catalog.json)
- https://github.com/nesrak1/AssetsTools.NET
    - library and tooling

## Melon loader (mod loader)

- download Installer: https://github.com/LavaGang/MelonLoader.Installer

### problems caused by up NET 6.0 runtime (in 2023)

As far as I understood due to some changes by the .NET runtime around 2023, many mods and plugins had to rewritten/updated and still have issues.  
The result is that even some of the universal mods listed in the MelonLoader Wiki are not working anymore. Check GitHub issues for alternatives.

### universal mods

- https://melonwiki.xyz/#/universalmods
- UnityExplorer
    - the default is archived and doesn't seem to work: - https://github.com/GrahamKracker/UnityExplorer
    - see https://github.com/LavaGang/MelonLoader/issues/565
    - the Fork seem to work https://github.com/GrahamKracker/UnityExplorer?tab=readme-ov-file

## guides

- https://jf.id.au/blog/reverse-engineering-a-unity-game
- https://jf.id.au/blog/modding-unity-il2cpp-games
- https://steamcommunity.com/sharedfiles/filedetails/?id=2850274044
- https://steamcommunity.com/sharedfiles/filedetails/?id=2854936721

## links

- https://github.com/loicreynier/awesome-modding
- https://www.nexusmods.com/site/mods/21
    - adds mod support for around 50 unity games
- https://github.com/BepInEx/BepInEx
    - mod loader, alternative to Melon loader
    - https://www.nexusmods.com/site/mods/529
        - alternative config manager for mods
- https://github.com/ManlyMarco/RuntimeUnityEditor
    - in-game editor and debugger for unity

## Game - Starri

### asset locations

- Song Info and Coordinates (MonoBehaviour Script)
    - `basic_assets_all_5d5c29a2a5a228a3ff4e5987c2f22dad.bundle`
- audio (full song as ogg Vobis)
    - `music-full_assets_all_94bbb3c5fe9d20075a02e9df1340b14a.bundle`
- audio (short preview as ogg Vobis)
    - `music-preview_assets_all_e40b9f7fd1e81c65170eb287df4915dd.bundle`
- cover (Texture2D + Sprite)
    - `music-jacket_assets_all_9c2608e18eadccbe5ac94c2bf2d01c16.bundle`

### song structure

#### song info

### Melon loader

- Download and Install Melon loader into Starri
    - https://melonwiki.xyz/#/README?id=automated-installation

#### universal mods

- UnityExplorer
    - doesn't seem to work, see https://github.com/LavaGang/MelonLoader/issues/565
    - the Fork seem to work https://github.com/GrahamKracker/UnityExplorer?tab=readme-ov-file
