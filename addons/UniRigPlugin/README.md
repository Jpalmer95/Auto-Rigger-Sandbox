# UniRig Godot Plugin

This plugin integrates the [UniRig AI-based auto-rigging tool](https://github.com/VAST-AI-Research/UniRig) into the Godot editor, allowing you to automate the rigging process for your 3D models directly within Godot.

## Features

*   Automated skeleton generation for `.glb` models using UniRig.
*   Automated skinning weight prediction based on the generated skeleton.
*   Merges the generated rig and weights back into the original model.
*   Simple UI within the Godot editor to configure UniRig and run the rigging process.
*   Log display for monitoring progress and errors.

## Prerequisites

**It is crucial that you meet these prerequisites before attempting to use this plugin.**

### 1. UniRig Installation & Environment

*   **UniRig Must Be Working Independently:** This plugin *calls* UniRig's scripts. It does **not** include UniRig itself. You must have a fully functional UniRig installation.
    *   **Official UniRig Repository:** [https://github.com/VAST-AI-Research/UniRig](https://github.com/VAST-AI-Research/UniRig)
    *   Follow their installation instructions carefully.
*   **Python Version:** UniRig requires **Python 3.11**.
*   **Key Dependencies:** You need PyTorch, `spconv`, `torch_scatter`, `torch_cluster`, and other packages as listed in UniRig's `requirements.txt`.
    *   Ensure you have the correct PyTorch version compatible with your CUDA version (if using GPU).
*   **Hardware:**
    *   **CUDA-enabled GPU:** UniRig requires a CUDA-enabled NVIDIA GPU for optimal performance (at least 8GB VRAM is recommended by UniRig). CPU-only mode might be possible but extremely slow and is not the primary target for UniRig.
    *   Sufficient RAM as per UniRig's needs.

### 2. Godot Version

*   This plugin is intended for **Godot Engine version 4.x**.

## How to Install Plugin

1.  **Download:**
    *   Download the plugin files (e.g., from a release ZIP or by cloning its repository).
2.  **Place in Project:**
    *   Create an `addons` folder in your Godot project's root directory if it doesn't already exist.
    *   Place the `UniRigPlugin` directory (containing `plugin.cfg`, `unirig_plugin.gd`, etc.) inside the `addons/` folder.
    *   The final structure should be: `MyGodotProject/addons/UniRigPlugin/`.
3.  **Enable in Godot:**
    *   Open your project in Godot.
    *   Go to `Project > Project Settings`.
    *   Navigate to the `Plugins` tab.
    *   Find "UniRig Plugin" in the list and check the "Enable" box.

## How to Use

### 1. Configuration

1.  **Open UniRig Panel:** After enabling the plugin, a new dock panel named "UniRig" should appear (typically on the left side of the editor, but its location can be changed in the Editor Layout).
2.  **Set UniRig Path:**
    *   In the "UniRig Configuration" section of the panel, find the "UniRig Python/Installation Path" field.
    *   Enter the **absolute path** to the root directory of your local UniRig repository clone (e.g., `/home/user/dev/UniRig` or `C:\Users\YourName\Documents\UniRig`).
3.  **Save Configuration:**
    *   Click the "Save Configuration" button.
    *   The "Status" label below the path field will update to indicate if the path seems valid (e.g., checks for key scripts and directories). Address any errors reported.

### 2. Rigging a Model

1.  **Input File:**
    *   In the "Rigging Process" section, click the "Browse" button next to "Input .glb File:".
    *   Select the `.glb` model file you want to rig.
2.  **Output File:**
    *   Click the "Browse" button next to "Output Rigged .glb File:".
    *   Specify the desired location and filename for the rigged model. This will also be a `.glb` file.
3.  **Seed (Optional):**
    *   You can enter an integer in the "Seed (Optional)" field. This seed influences the skeleton generation process and can be used to get different results if the initial one is not satisfactory.
4.  **Start Rigging:**
    *   Click the "Start Rigging" button.
5.  **Monitor Log:**
    *   The "Log" area at the bottom of the panel will display progress messages from the plugin and output from the UniRig scripts.
    *   Pay attention to any errors reported here.
6.  **Retrieve Output:**
    *   Once the process is complete (indicated by a success message in the log), your rigged `.glb` file will be available at the output path you specified.

## Important Notes / Known Limitations

*   The quality of the final rig depends entirely on UniRig's AI capabilities and the characteristics of your input 3D model.
*   UniRig is a research project. It may have limitations or perform suboptimally with certain types_of meshes (e.g., highly non-humanoid, extremely low-poly, or disjointed meshes).
*   This plugin executes UniRig's shell scripts (`.sh`) as external processes. It's essential that your UniRig installation is working correctly in its dedicated Python 3.11 environment *before* you use this plugin.
*   **Synchronous Execution:** Currently, the plugin runs UniRig scripts in a blocking (synchronous) manner. This means the Godot editor **will freeze** during the rigging process. This can take several minutes for complex models or on slower hardware. Future versions may explore asynchronous execution.
*   Error messages from UniRig scripts are directly displayed in the log panel. If you encounter issues, these messages are your primary guide. It's often helpful to try running the failing UniRig command (visible in the log) directly from your command line in the UniRig environment to get more detailed diagnostics.
*   Temporary files (e.g., `temp_skeleton.fbx`, `temp_skin.fbx`) are created in your Godot project's `user://unirig_temp/` directory during the process. These are **not deleted automatically** by default to aid in debugging. You can manually delete them if they are no longer needed.

## Troubleshooting

*   **Status: "UniRig path is invalid" (or similar errors in the status label):**
    *   Double-check that the path entered is the absolute path to the **root** of your cloned UniRig repository.
    *   Ensure that the `launch/inference/` subdirectory exists within that path.
    *   Verify that the core UniRig scripts (`generate_skeleton.sh`, `generate_skin.sh`, `merge.sh`) are present inside `launch/inference/`.

*   **Script execution errors appear in the Log panel:**
    *   **Verify Python Environment:** Confirm that your UniRig Python 3.11 environment is correctly activated and has all necessary dependencies installed (PyTorch, correct CUDA version for PyTorch, spconv, etc., as per UniRig's `requirements.txt`).
    *   **Run Manually:** Copy the "Executing: ..." command from the log panel. Open your system's command line/terminal, activate the UniRig Python environment, and try running that exact command. This will often provide more direct error messages from UniRig or Python.
    *   **GPU/CUDA Issues:** Ensure your NVIDIA GPU drivers and CUDA toolkit (if installed system-wide) are up to date and compatible with your PyTorch installation.
    *   **UniRig Issues:** The problem might be with UniRig itself or its compatibility with your specific model. Check the UniRig GitHub issues page for similar problems.
    *   **File Paths:** Ensure input/output file paths do not contain unusual characters that might cause issues with command-line tools.
