"""
Module for handling input operations, primarily loading 3D mesh files.
"""

import trimesh
import os

def load_mesh(filepath: str) -> trimesh.Trimesh | None:
    """
    Loads a 3D mesh from the given filepath.

    Currently, only OBJ files are supported.

    Args:
        filepath: The path to the mesh file.

    Returns:
        A trimesh.Trimesh object if loading is successful, otherwise None.
    """
    if not filepath.lower().endswith(".obj"):
        print(f"Error: Only OBJ files are currently supported. File provided: {filepath}")
        return None

    if not os.path.exists(filepath):
        print(f"Error: File not found at '{filepath}'.")
        return None

    try:
        mesh = trimesh.load_mesh(filepath)
        if not isinstance(mesh, trimesh.Trimesh):
            # trimesh.load_mesh can return a list of meshes or a scene
            # For simplicity, we only handle single Trimesh objects for now.
            print(f"Error: Loaded object is not a single mesh. Type: {type(mesh)}")
            return None
        print(f"Successfully loaded mesh from '{filepath}'.")
        return mesh
    except Exception as e:
        print(f"Error loading mesh from '{filepath}': {e}")
        return None

if __name__ == '__main__':
    # Example usage (optional, for testing)
    # Create a dummy OBJ file for testing
    dummy_obj_content = """
    # Simple cube
    v 1.0 1.0 -1.0
    v 1.0 -1.0 -1.0
    v 1.0 1.0 1.0
    v 1.0 -1.0 1.0
    v -1.0 1.0 -1.0
    v -1.0 -1.0 -1.0
    v -1.0 1.0 1.0
    v -1.0 -1.0 1.0
    f 1 2 4 3
    f 5 6 8 7
    f 1 5 7 3
    f 2 6 8 4
    f 1 5 6 2
    f 3 7 8 4
    """
    dummy_filepath = "dummy_cube.obj"
    with open(dummy_filepath, "w") as f:
        f.write(dummy_obj_content)

    print(f"Attempting to load mesh: {dummy_filepath}")
    mesh_object = load_mesh(dummy_filepath)
    if mesh_object:
        print(f"Mesh loaded: {mesh_object.vertices.shape[0]} vertices, {mesh_object.faces.shape[0]} faces")

    print("\nAttempting to load non-existent file:")
    load_mesh("non_existent_file.obj")

    print("\nAttempting to load unsupported file type:")
    with open("dummy_unsupported.txt", "w") as f:
        f.write("This is not a mesh file.")
    load_mesh("dummy_unsupported.txt")

    # Clean up dummy files
    os.remove(dummy_filepath)
    os.remove("dummy_unsupported.txt")
