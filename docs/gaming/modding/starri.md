# gaming - modding - Starri

Notes on experimenting with modding the game Starri.

Starri is a rhythm game that doesn't support custom songs out of the box. This guide explains how to replace existing songs with custom ones.

Game: https://store.steampowered.com/app/1940410/Starri/

## original asset locations

path: `C:\Program Files (x86)\Steam\steamapps\common\Starri\Starri_Data\StreamingAssets\`

- Song Info and Coordinates (MonoBehaviour Script)
    - `basic_assets_all_5d5c29a2a5a228a3ff4e5987c2f22dad.bundle`
- audio (full song as ogg Vobis)
    - `music-full_assets_all_94bbb3c5fe9d20075a02e9df1340b14a.bundle`
- audio (short preview as ogg Vobis)
    - `music-preview_assets_all_e40b9f7fd1e81c65170eb287df4915dd.bundle`
- cover (Texture2D + Sprite)
    - `music-jacket_assets_all_9c2608e18eadccbe5ac94c2bf2d01c16.bundle`

## Exporting original assets

Download https://github.com/Perfare/AssetStudio and open the bundles to extract the assets.
A sample song is provided in the `sample_song` folder.

## asset structure for songs

This section uses the sample song `sample_song` as an example.

### song info

The song info is stored in the `sample_song\MonoBehaviour\brain-power-info.json`.

### song cover

Two versions are needed:

- `sample_song\Texture2D\brain-power-album.png`
- `sample_song\Sprite\brain-power-album.png`

### song audio file

The song is stored in ogg Vobis format, but exported as wav. Best is to use ogg Vobis for the custom song.

- short preview: `sample_song\AudioClip\brain-power-short.wav`
- full song: `sample_song\AudioClip\brain-power-song.wav`

## note coordinates

The game has two game modes and three difficulty levels. Each has one file for the note coordinates and one for metadata.

- mode: Slash
    - difficulty: Easy
        - coordinates: `sample_song\MonoBehaviour\brain-power [Slash-Easy].json`
        - metadata: `sample_song\MonoBehaviour\slash-easy-brain-power.json`
    - difficulty: Normal
        - coordinates `sample_song\MonoBehaviour\brain-power [Slash-Normal].json`
        - metadata: `sample_song\MonoBehaviour\slash-normal-brain-power.json`
    - difficulty: Hard
        - coordinates `sample_song\MonoBehaviour\brain-power [Slash-Hard].json`
        - metadata: `sample_song\MonoBehaviour\slash-hard-brain-power.json`
- mode: Catch
    - difficulty: Easy
        - coordinates `sample_song\MonoBehaviour\brain-power [Catch-Easy].json`
        - metadata: `sample_song\MonoBehaviour\catch-easy-brain-power.json`
    - difficulty: Normal
        - coordinates `sample_song\MonoBehaviour\brain-power [Catch-Normal].json`
        - metadata: `sample_song\MonoBehaviour\catch-normal-brain-power.json`
    - difficulty: Hard
        - coordinates `sample_song\MonoBehaviour\brain-power [Catch-Hard].json`
        - metadata: `sample_song\MonoBehaviour\catch-hard-brain-power.json`

The assets also include coordinates for a visual mode that I don't know the purpose of.

Each note has multiple properties:

````json
    {
  "id": 0,
  "targetLane": 2,
  "startTimestamp": 2.163,
  "endTimestamp": 0.0,
  "noteType": 8,
  "isFlippedArrow": 0,
  "isAirArrow": 0,
  "catchSlashConfigType": 0,
  "slashConfigParameter": 0
}
````

## replacing an existing song

### replacing a song

Use  https://github.com/nesrak1/UABEA/ to replace the assets inside the bundles.

#### clean up addressables

The catalog.json keeps track of the hashes for each bundles. It needs to be cleaned up after replacing assets.

Download https://github.com/nesrak1/AddressablesTools/releases

````powershell
cd Download location
./Example patchcrc "C:\Program Files (x86)\Steam\steamapps\common\Starri\Starri_Data\StreamingAssets\catalog_2024.<date>.json"
````

rename the original file to `catalog_2024.<date>.json.bak` and the new file to `catalog_2024.<date>.json`.

## Melon loader

Melon Loader can be used to write completely custom mods for Starri.

- Download and Install Melon loader into Starri
    - https://melonwiki.xyz/#/README?id=automated-installation
-

### universal mods

- UnityExplorer
    - doesn't seem to work, see https://github.com/LavaGang/MelonLoader/issues/565
    - the Fork seem to work https://github.com/GrahamKracker/UnityExplorer?tab=readme-ov-file
