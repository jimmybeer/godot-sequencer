# Sequencer Project – Design Principles

This document defines the guiding principles for the Sequencer project.  
All new features, fixes, or refactors **must follow these rules** to ensure the system remains consistent, maintainable, and extensible.

---

## 1. Model-Driven Design
- All persistent state is stored in **Resource classes**:
  - `Sequence` → top-level container of tracks.
  - `TrackData` → holds track name and list of `ClipData`.
  - `ClipData` → holds clip name, start, duration, and future metadata.
- **Commands** mutate only the model (e.g., adding, deleting, renaming clips).
- Views **never own state** — they render what the model currently contains.

---

## 2. Separation of Concerns
- **CommandBus**  
  - Executes, undoes, and redoes commands.  
  - Emits `stack_changed` when history changes.  
  - Has no knowledge of the UI.

- **Views (e.g., `TrackView`, `ClipView`, `TimelineView`)**  
  - Passive renderers of model data.  
  - Expose signals (e.g., `clip_clicked`) to express user intent.  
  - Do not modify the model directly.

- **SequenceDock**  
  - Orchestrates everything.  
  - Holds the active `Sequence`, `CommandBus`, and editor UI.  
  - Responds to signals from views by pushing commands.  
  - Refreshes views from the model after changes.

---

## 3. Maintainability & Extensibility
- Prefer **clear APIs** over internal access:  
  - Example: `TrackView.get_selected_clips()` instead of poking into arrays.
- All view updates must come from **`refresh_from_model()`** calls.  
- Adding new commands (e.g., move clip, resize clip, rename track) should not require rewriting Dock or Views.
- Avoid duplicating state: the **model is always the single source of truth**.

---

## 4. Consistency
- Naming conventions:  
  - `bind_to_model()` and `refresh_from_model()` for views.  
  - `*_Command.gd` for undoable actions.  
- Use strong typing where possible (`ClipData`, `TrackData`, etc.).  
- Follow Godot’s scene/node best practices (separation of UI containers vs. control nodes).

---

## 5. Red Flags to Avoid
- Commands that manipulate UI nodes (`add_child`, `queue_free`, etc.) directly.  
- Views that change `ClipData` or `TrackData` without going through a command.  
- `SequenceDock` passing both model and view objects to the same function.  
- Storing duplicated lists of clips or tracks outside the model.

---

## 6. Review Process
- After each milestone (e.g., Stage S1, Stage S2), perform a **design audit**:
  - Verify that commands are model-only.  
  - Verify that views are refreshed solely from the model.  
  - Verify that no state duplication exists.  
- If drift is detected, refactor before adding new features.

---

## Summary
This Sequencer is **model-driven, UI-passive, and command-mediated**.  
The Dock orchestrates, the CommandBus controls history, the model is the single source of truth, and the views are pure renderers.  
Stick to these principles to keep the system robust, simple to extend, and easy to maintain.
