# Auto-Rigging Sandbox Application

## Project Overview

Goal: Develop an open-source auto-rigging sandbox application that automates the creation of animation-ready rigs for 3D models, with a modern GUI, targeting integration with Godot and Blender. The application will export rigs in .glb format for compatibility with game engines like Godot, Unity, and Unreal Engine.

## Initial Setup

This project is built using Python.

### Dependencies

Currently, the project relies on the following Python libraries:

*   `trimesh`: For 3D mesh processing.

You can install the necessary dependencies using pip:

```bash
pip install trimesh
```

## Planned Features (High-Level)

*   Automated Rigging for humanoid and non-humanoid models.
*   Modern GUI with real-time previews.
*   Blender Integration.
*   Godot Compatibility (.glb export).
*   Support for various 3D input formats (OBJ, FBX, STL).
*   Sandbox Mode for interactive rig tweaking.

## Technology Stack (Proposed)

*   **Programming Language**: Python (core logic, Blender integration), C# (Godot integration)
*   **GUI Framework**: Dear ImGui or PyQt/PySide; Godot's UI System
*   **3D Processing**: Open3D, PyTorch3D, Assimp
*   **AI/ML**: PyTorch or TensorFlow
*   **Blender Integration**: bpy
*   **Godot Integration**: GDScript or C#
*   **Export Format**: GLTF 2.0 (.glb)
*   **Dependencies**: NumPy, SciPy
