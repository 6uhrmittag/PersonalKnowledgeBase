# Recording in VR

## Tools and ways to record VR

- **OBS-Plugin: OpenVR-Capture** _[easiest since in OBS directly]_
    - https://github.com/Pigney/OpenVR-Capture
    - Updated fork of this Plugin: https://github.com/baffler/OBS-OpenVR-Input-Plugin
- **SteamVR Mirror Window** _[a bit more convinient]_
    - plain capture via OBS Game Capture
- **Metas Debugging tools to record**(*more or less all the same, IMHO offering the most advanced settings, no audio)*
    - OculusMirror.exe _[I believe wired only?!]_
        - https://developers.meta.com/horizon/documentation/native/pc/dg-compositor-mirror/
    - Meta Quest Developer Hub (MQDH) _[wireless casting via BetaCast 2.0]_
        - https://developers.meta.com/horizon/documentation/unity/ts-odh-media/
        - https://www.vr-wave.store/de-de/blogs/virtual-reality-prescription-lenses/how-to-record-gameplay-on-the-meta-quest-3
- **built-in Quest wireless casting** _[requires to cast to Firefox to capture with OBS, rather lame solution]_
    - https://www.meta.com/help/quest/articles/in-vr-experiences/oculus-features/cast-with-quest/
- **built-in Quest recording** _[convenient, adds min. 5ms latency in my experiments]_
    - https://www.meta.com/help/quest/articles/in-vr-experiences/social-features-and-sharing/record-video-oculus/
- **Sidequest to enhance built-in casting/recording** _[improves performance + quality]_
    - enhanced quality for local recording enhanced quality for wireless casting (no audio I believe)
    - ability to set CPU+GPU to max. level for optimization
    - mirroring via scrcpy, but not worth it having all other options
- **LIV** _[adds nothing for plain recording, but a bit more convenient, adds more advanced features]_
    - https://help.liv.tv/hc/en-us/articles/14408182394642-How-to-use-your-Quest-with-LIV

### Advanced methods/links

- Overview by Meta: Capture MR and VR Apps for Publishing
    - https://developers.meta.com/horizon/resources/video-capture-mr-vr/
- Overview of how to Record VR videos by Meta (focus on content for VR)
    - https://creator.oculus.com/create-build/capturing-video-from-a-quest-headset/
- Tips to optimize performance by LIV
    - https://help.liv.tv/hc/en-us/articles/360016871619-How-To-Improve-Performance-With-LIV

## Recording custom avatars in VR (VRChat avatars/FBX/VRM)

As of 2024/2025 there are just 2+1/2 ways to record custom avatars in VR:

- LIV (built-in avatar feature + image combination)
    - https://help.liv.tv/hc/en-us/sections/360004620060-LIV-Avatars-and-Virtual-Cameras
    - Notes:
        - Avatars are displayed in very low quality compared to the original. VMC's quality is much better.
        - LIV offers lots of useful features
- LIV(image combination) + VMC(avatar)
    - VMC
        - https://github-com.translate.goog/gpsnmeajp/EasyVirtualMotionCaptureForUnity?_x_tr_sl=ja&_x_tr_tl=de&_x_tr_hl=de&_x_tr_pto=sc
        - documentation(translated): https://gpsnmeajp-github-io.translate.goog/EasyVirtualMotionCaptureForUnity-documents/?_x_tr_sl=ja&_x_tr_tl=de&_x_tr_hl=de&_x_tr_pto=sc
    - Setup Guides:
        - https://dance-dash.fandom.com/wiki/Using_VMC_(Virtual_Motion_Capture)_for_Avatar_Tracking
        - https://www.youtube.com/watch?v=diGjkjZM2n8
    - Demos
        - VMC and Synth Riders:
            - https://www.youtube.com/watch?v=TE-qsOfweM4
    - Hack: use Quest Passthrough with any game by using Virtual Desktops greenscreen feature
        - by combining Virtual Desktop's greenscreen chromakey feature + any game that includes green/blue screen levels(e.g. a greenroom world in VRChat)
        - Demo:
            - https://www.youtube.com/watch?v=OCQG6Dqarvs
                - LunchAndVR - How to use Mixed Reality with PCVR games (Virtual Desktop Passthrough)
            - https://www.youtube.com/watch?v=j0TxmDyHS24
                - Artur's Tech Tales - Mixed Reality Passthrough - Blending Realities & Virtual Desktop Set-Up
- Games with built-in avatar support
    - Synth Riders has a built-in avatar feature
        - unfortunately no FBT support, so no legs+hips
        - better quality than LIV's avatar feature
    - Beat Saber [untested by me]
        - built-in feature
        - mods to integrate with VMC [seems very good/advanced]
            - integrates with advanced camera mods like Camera2
                - https://github.com/kinsi55/CS_BeatSaber_Camera2
                - http://stefanekren.com/vr/vmc.html
    - Dance Dash
        - https://store.steampowered.com/app/2005050/Dance_Dash/
    - VRChat [obviously]
