# ACT3 MCP — Tools

The tools `act3-mcp` exposes to an MCP client. They are proxied straight from the
ACT3 backend, so this list grows automatically as the backend adds tools — this
snapshot is from `tools/list` against a backend reporting 92 tools.

Legend:

- **💳** spends credits — always quotes first; nothing starts without `confirm:true`, and `maxCredits` caps the spend
- **✏️** writes data
- **⚠️** irreversible
- unmarked = read-only

Most write tools *plan first*: called without `confirm:true` they return exactly
what they would change and write nothing.

---

## Account & orientation

| Tool | What it does |
|---|---|
| `whoami` | Who you're signed in as and which orgs you belong to |
| `list_org_members` | Who's in the org and what they're allowed to do (read-only) |
| `get_credits` | Org's spendable credit balance |
| `get_credit_history` | Recent credit spend, newest first |
| `get_current_context` | Where you are in the editor right now — open project, scene, shot, character |
| `get_next_steps` | What's left to do on a project, in order, naming the tool for each step |
| `get_progress` | How far along a project is — shots / first frames / rendered / locked, per scene |
| `get_batch_status` | Live generation status for a scene (queued / running / done / failed) |
| `get_job_status` | Poll one async job by id |
| `list_genres` | Available project genres |
| `list_layers` | Available shot layer types |
| `list_voices` | TTS voices a character can be given |

## Projects

| Tool | What it does |
|---|---|
| `list_projects` | All projects in your orgs (search by title) |
| `set_current_project` ✏️ | Switch the "current" project cursor |
| `create_project` ✏️💳 | New movie project (credits only if you pass `overViewForAI`) |
| `update_project` ✏️ | Title, description, notes, target runtime |
| `clone_project` ✏️ | Copy a whole project |
| `archive_project` ✏️ | Hide / restore a project |
| `copy_assets_between_projects` ✏️ | Copy sets / characters etc. from one project to another (plans first) |
| `list_project_assets` | Uploaded images, b-roll, etc. in a project |

## Structure & navigation

| Tool | What it does |
|---|---|
| `list_structure` | Acts → beats → scenes skeleton with ids |
| `list_scenes` | Scenes of a project |
| `list_shots` | Shots of a scene |
| `resolve_range` | Turn "act 2", "scenes 12–15", "shots 19–34" into the exact shot list |
| `find_shots` | Shots matching a condition: no first frame, unrendered, locked, by character, dialogue text |
| `get_report` | Tabulated facts — shots / characters / scenes / wardrobe / lint; JSON or CSV |
| `tag_shots` ✏️ | Add/remove a tag across a range |
| `generate_scenes_from_beats` ✏️💳 | Expand beats into scenes |
| `split_scene` ✏️ | Split a scene into two at a shot boundary |
| `merge_scene` ✏️ | Fold a scene into its neighbour (shots are kept) |
| `update_scene` ✏️ | Title, description, transitions, lock |
| `reorder_shots` ✏️ | Change shot order within a scene |
| `delete_shots` ✏️⚠️ | Permanently remove shots and everything generated for them |

## Shots (per-shot directing)

| Tool | What it does |
|---|---|
| `get_shot` | One shot in full — title, type, video, cast, first-frame URL |
| `get_shot_cast` | Which characters are in a shot and whether they speak |
| `get_shot_layers` | Layer data for a shot (audio, character, set, mocap, yaml, …) |
| `get_shot_yaml` | The assembled generation prompt as YAML — what the engine is told |
| `update_shot` ✏️ | Title, script, time, weather, camera (type/lens/height/movement/position/target), transitions, duration, prompt |
| `apply_to_range` ✏️ | Same `update_shot` change across a whole range (plans first) |
| `get_first_frame` | First-frame image URL |
| `regenerate_first_frame` ✏️💳 | Generate/regenerate first frame from a prompt (async, returns jobId) |
| `generate_first_frame_prompts` ✏️💳 | Write first-frame prompts for every shot in a scene |
| `generate_storyboards` ✏️💳 | Storyboard panels for the whole project |
| `list_shot_takes` | Every rendered take of a shot, and which is current |
| `set_primary_take` ✏️ | Choose which take a shot uses |
| `revert_shot_video` ✏️ | Undo the last re-render |
| `get_download_urls` | Download URLs for first frames or videos across a range |

## Script & dialogue

| Tool | What it does |
|---|---|
| `read_script` | Script for a range, shot by shot, with dialogue |
| `list_lines` | Every spoken line in a range, by character |
| `update_line` ✏️ | Rewrite one character's line (and parenthetical) in one shot |
| `update_lines` ✏️ | Rewrite many lines in one go (plans first) |
| `move_line` ✏️ | Move a line from one shot to another |
| `import_screenplay` ✏️💳⚠️ | Import an uploaded .fdx/.txt into scenes + shots (`full-reset` mode wipes existing) |
| `export_script` | Export as Final Draft XML or plain text |
| `list_script_versions` | Saved script versions, or the diff for one |
| `restore_script_version` ✏️ | Roll the script back to a saved version |

## Characters

| Tool | What it does |
|---|---|
| `list_characters` | Cast of a project |
| `get_character` | One cast member — name, role, image |
| `rename_character` ✏️ | Rename across the project |
| `generate_character_image` ✏️💳 | Generate the digital-actor reference image |
| `add_character_to_shot` ✏️ | Place an existing character into a shot |
| `update_character_action` ✏️ | Blocking in one shot — seated, visible, over-the-shoulder, left/right placement |
| `set_character_voice` ✏️ | Assign a TTS voice (doesn't re-record; follow with `generate_audio`) |
| `create_outfit` ✏️ | Turn an uploaded image into a wardrobe outfit |
| `attach_mocap` ✏️ | Apply an uploaded mocap file to a character in a shot |

## 4D sets

| Tool | What it does |
|---|---|
| `list_sets` | The 4D sets in a project |
| `get_current_set` | Which set the conversation is standing in |
| `set_current_set` ✏️ | Point the set cursor at a set (by name or id) |
| `create_set` ✏️ | New 4D set in a project |
| `get_set_tree` | Readable outline — zones, elements, objects, with counts |
| `get_set_model` | The whole set model, raw |
| `list_set_nodes` | Flat node list — key, kind, parent |
| `get_set_node` | One node in full |
| `list_set_spots` | Camera spots and which directions have a generated view |
| `add_set_node` ✏️ | Add a zone / element / object / spot (plans first) |
| `duplicate_set_node` ✏️ | Copy a node |
| `update_set_node` ✏️ | Rename / redescribe a node |
| `move_set_node` ✏️ | Reparent a node |
| `set_set_node_geometry` ✏️ | Move / resize a node |
| `delete_set_node` ✏️⚠️ | Remove a node |
| `generate_set_image` ✏️💳 | Generate the set's look from a description |
| `attach_blend_file` ✏️ | Attach an uploaded .blend to a shot or set |

## Styles

| Tool | What it does |
|---|---|
| `list_style_sources` | Things you can copy a look from — outfits, 4D sets, cinematography patterns, screens, render styles, tone styles |
| `apply_style_to_range` ✏️ | Copy one of those onto every shot in a range (plans first) |

## Rendering & audio

| Tool | What it does |
|---|---|
| `estimate_cost` | Dry-run price for render / upscale / audio — spends nothing |
| `render_shot` ✏️💳 | Render one shot or its whole scene (PREVIEW / MEDIUM / PUBLISH) |
| `build_videos` ✏️💳 | Render with a chosen engine (runway / veo / seedance), quality and scope (shot / scene / beat / act / all) |
| `retry_failed_shots` ✏️💳 | Re-render shots in a range that have no finished video |
| `assemble_cut` ✏️💳 | Stitch finished shots into one video (whole movie / act / scenes), optionally upscaled to 4K |
| `generate_audio` ✏️💳 | Generate spoken audio for a shot's dialogue |

## Uploads

| Tool | What it does |
|---|---|
| `create_upload_url` | Get a short-lived PUT URL for one local file |
| `register_upload` ✏️ | Turn the uploaded file into an ACT3 asset (then use with `create_outfit`, `attach_mocap`, `attach_blend_file`, `import_screenplay`) |

## Built into the binary

| Tool | What it does |
|---|---|
| `act3_connect` | Only present while not logged in. Tells the client how to authenticate and, once `act3-mcp login` has been run, reconnects without restarting the client. Disappears once authenticated. |

---

A typical flow: `get_current_context` → `get_next_steps` → read tools
(`list_structure`, `read_script`, `find_shots`) → `resolve_range` to confirm the
target → a write tool without `confirm` to see the plan → the same call with
`confirm:true`. Anything 💳 should be preceded by `estimate_cost` or `get_credits`.
